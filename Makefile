SHELL := /bin/bash

sources = $(shell find . -type d -name '*_tools' -prune -or \
		  -type f \(                                        \
		  \( -name '*.go' -or -name '*.gotpl' \) -and       \
		  -not -name '*_test.go'                            \
		  \)                                                \
		  -printf '%p ')
gopath := $(shell echo $$GOPATH)

#===============================================================================
#  release
#===============================================================================
tool_dir := _tools
release_dir := _release
pkg_dest_dir := $(release_dir)/.pkg

latest_local_devel_branch := $(shell git for-each-ref --count=1 \
	--sort=-committerdate --format='%(refname:short)' refs/heads/)
sem_ver_regex := (0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$$
new_tag := v$(shell echo "$(latest_local_devel_branch)" \
	| egrep --only-matching '$(sem_ver_regex)')

#===============================================================================
#  build option
#===============================================================================
ALL_OS := darwin linux windows
ALL_ARCH := 386 amd64

# Version tag must be annotation tag created by `git tag -a 'x.y.z'`.
version := $(shell git describe --always --dirty 2>/dev/null || echo 'no git tag')
VERSION_PACKAGE := main
build_revision := $(shell git rev-parse --short HEAD)
build_with := $(shell go version)

# static build
static_flags := -a -tags netgo -installsuffix netgo
ld_flags := -s -w -X '$(VERSION_PACKAGE).buildVersion=$(version)' \
	-X '$(VERSION_PACKAGE).buildRevision=$(build_revision)'       \
	-X '$(VERSION_PACKAGE).buildWith=$(build_with)'               \
	-extldflags -static

# ==============================================================================
#   develop tools version
# ==============================================================================
GOLANGCI_LINT_VERSION := v1.54.2
GOCREDITS_VERSION := v0.3.0
GIT_CHGLOG_VERSION := v0.15.4
GHR_VERSION := v0.16.0
MKTPL_VERSION := v1.0.1

#===============================================================================
#  lint tool
#===============================================================================
GOLINTER := golangci-lint run

#===============================================================================
#   go test
#===============================================================================
go_cover_out := cover.out
go_test := go test -tags mock

#===============================================================================
#  gitignore.io
#===============================================================================
GITIGNORE_BOILERPLATE :=  Vim,Go
gitignore_io_request := https://www.gitignore.io/api/$(GITIGNORE_BOILERPLATE)

#===============================================================================
#  file generation from template engine
#    `mktpl` is used for generating files, .data.yml is used for templating.
#    .data.yml is automatically generated using upper case variables in Makefile.
#===============================================================================
template_dir := $(tool_dir)/etc/template
data_yml := .data.yml
# user-defined function: $(call mktpl,TEMPLATE,OUTPUT)
define mktpl
	@mktpl --data=$(data_yml) --template=$1 >$2
endef

BINARY := $(notdir $(shell pwd))
HELP_OUT := $(BINARY) --help

#===============================================================================
#  targets
#    `make [help]` shows tasks what you should execute.
#===============================================================================
.DEFAULT_GOAL := help

.PHONY: help ## show help
help:
	@echo 'USAGE: make [target]'
	@echo
	@echo 'TARGETS:'
	@egrep '^.PHONY[^#]+##' $(MAKEFILE_LIST)                                        \
		| sed 's/^.PHONY: //'                                                       \
		| awk 'BEGIN {FS = " ## "}; {printf "\033[32m%-19s\033[0m %s\n", $$1, $$2}'

.PHONY: setup ## install devlop tools for this project
setup: $(data_yml)
	curl -sfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh \
		| bash -s -- -b $(shell go env GOPATH)/bin $(GOLANGCI_LINT_VERSION)
	go install github.com/Songmu/gocredits/cmd/gocredits@$(GOCREDITS_VERSION)
	go install github.com/tcnksm/ghr@$(GHR_VERSION)
	go install github.com/yuta-masano/mktpl@$(MKTPL_VERSION)

.PHONY: init ## misc tasks for first commit
init: setup .gitignore
	! git log --grep='First commit' --format='%s' | grep --quiet '^First commit$$'
	mkdir --parents .github
	${call mktpl,$(template_dir)/ISSUE_TEMPLATE.md,.github/ISSUE_TEMPLATE.md}
	echo -n >CHANGELOG
	git add $(tool_dir) .gitignore .github .golangci.yml CHANGELOG LICENSE Makefile
	git commit --message='First commit'
	cp --archive $(tool_dir)/etc/git_hooks/* .git/hooks/

# cobra init (fail if you don't explicitly set BINARY env)
cobra: main.go cmd/config.go cmd/hello.go cmd/root.go

# You need to do this task when you have updated or installed packages, because godoc
# reads files generated by `go install`.
.PHONY: install ## it is necessary to notify godoc when packages have been updated or installed newly
install:
	go mod tidy
	$(MAKE) $(gopath)/bin/$(BINARY)

.PHONY: lint ## lint go sources and check whether only LICENSE file has copyright sentence
lint: install
	$(GOLINTER)
	$(tool_dir)/copyright_check.sh

.PHONY: test ## go test
test:
	@go mod tidy
	@$(go_test) -cover ./...

.PHONY: coverfunc ## check cover profile for each function
coverfunc: $(go_cover_out)
	go tool cover -func=$(go_cover_out)

.PHONY: coverhtml ## check cover profile with browser
coverhtml: $(go_cover_out)
	go tool cover -html=$(go_cover_out)

.PHONY: push-release-tag ## update CHANGELOG and push all of the your development works
push-release-tag: lint test
	$(tool_dir)/commit_changelog.sh "$(new_tag)"
	git checkout master
	git merge --ff "$(latest_local_devel_branch)"
	git push
	$(tool_dir)/push_release_tag.sh "$(new_tag)"
	git branch --move "$(latest_local_devel_branch)" "$(latest_local_devel_branch)-pushed"

.PHONY: all-build
all-build: lint test
	$(tool_dir)/build_static_bins.sh "$(ALL_OS)" "$(ALL_ARCH)"        \
		"$(static_flags)" "$(ld_flags)" "$(pkg_dest_dir)" "$(BINARY)"

.PHONY: all-archive
all-archive:
	$(tool_dir)/archive.sh "$(ALL_OS)" "$(ALL_ARCH)" "$(pkg_dest_dir)"

.PHONY: release ## build binaries for all platforms and upload them to GitHub
release: all-build all-archive
	ghr "$(version)" "$(release_dir)"

.PHONY: clean ## uninstall the binary and remove non versioning files and direcotries
clean:
	go mod tidy
	go clean -i .
	rm --recursive --force $(release_dir)
	rm --force $(data_yml)

.PHONY: doc ## create README.md and DEVELOPMENT.md using template
doc: $(data_yml) install
	${call mktpl,$(template_dir)/README.md,README.md}
	${call mktpl,$(template_dir)/DEVELOPMENT.md,DEVELOPMENT.md}
	gocredits . > CREDIT

#---  helper targets  ----------------------------------------------------------

.INTERMEDIATE: $(data_yml)
$(data_yml):
	@$(MAKE) print_mktpl_vars | grep '^[A-Z_]' \
		| sed 's/ *$$//' >$@

.INTERMEDIATE: $(go_cover_out)
$(go_cover_out):
	@go mod tidy
	$(go_test) -cover --coverprofile=$(go_cover_out) ./...

.gitignore:
	curl --location $(gitignore_io_request) >>$@
	echo >>$@
	echo '### my repository' >>$@
	echo '_release' >>$@

$(gopath)/bin/$(BINARY): $(sources)
	CGO_ENABLED=0 go install $(subst -a ,,$(static_flags)) -ldflags "$(ld_flags)"

main.go: $(data_yml)
	${call mktpl,$(template_dir)/cobra/main.go.tpl,$@}

cmd/hello.go: $(data_yml)
	mkdir --parents cmd
	${call mktpl,$(template_dir)/cobra/hello.go.tpl,$@}

cmd/config.go: $(data_yml)
	mkdir --parents cmd
	${call mktpl,$(template_dir)/cobra/config.go.tpl,$@}

cmd/root.go: $(data_yml)
	mkdir --parents cmd
	${call mktpl,$(template_dir)/cobra/root.go.tpl,$@}

# Dumping Every Makefile Variable
.PHONY: print_mktpl_vars
print_mktpl_vars:
	$(foreach V,                                         \
		$(sort $(.VARIABLES)),                           \
		$(if                                             \
			$(filter-out environment% default automatic, \
				$(origin $V)),                           \
			$(info $V: $($V))                            \
		)                                                \
	)
