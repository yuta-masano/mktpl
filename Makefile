SHELL := /bin/bash

sources = $(shell find -type f        \
	| grep -E '\.(go|tmpl)'           \
	| grep --invert-match -E '_test')

#===============================================================================
#  release information
#===============================================================================
tool_dir := _tool
release_dir := _release
pkg_dest_dir := $(release_dir)/.pkg

latest_local_devel_branch := $(subst * ,,$(shell git branch --sort='-committerdate' \
	| grep --invert-match master                                                    \
	| head --lines=1))
new_tag := $(shell echo "$(latest_local_devel_branch)"  \
	| grep --only-matching -E '[0-9]+\.[0-9]+\.[0-9]+')

#===============================================================================
#  build options
#===============================================================================
package := $(shell go list)
binary := $(notdir $(package))

ALL_OS := darwin linux windows
ALL_ARCH := 386 amd64

# Version tag must be annotation tag created by `git tag -a 'x.y.z'`.
version := $(shell git describe --always --dirty 2>/dev/null || echo 'no git tag')
VERSION_PACKAGE := main
build_revision := $(shell git rev-parse --short HEAD)
build_with := $(shell go version)

static_flags := -a -tags netgo -installsuffix netgo
ld_flags := -s -w -X '$(VERSION_PACKAGE).buildVersion=$(version)' \
	-X '$(VERSION_PACKAGE).buildRevision=$(build_revision)'       \
	-X '$(VERSION_PACKAGE).buildWith=$(build_with)'               \
	-extldflags -static

#===============================================================================
#  lint options
#===============================================================================
GOMETALINTER_OPTS := --enable-all --vendored-linters --deadline=60s \
	--dupl-threshold=75 --line-length=120
GOMETALINTER_EXCLUDE_REGEX := gas

#===============================================================================
#  README.md generation
#===============================================================================
# mo is a simple template engine (called as Mustache) written by shell script.
mo := $(tool_dir)/mo
readme_template := $(tool_dir)/etc/template/README.md

nl2text := perl -pe 's/\n/__NL__/g' | perl -pe 's/__NL__$$//' # trim the last EOL.
text2nl := perl -i -pe 's/__NL__/\n/g'

# Replace newlines with '__NL__' because Makefile can not hold newlines of bash command ouputs.
1l_help_out = $(shell $(binary) --help 2>&1 | $(nl2text))
ifneq ($(wildcard glide.yaml),)
	1l_thanks_out := $(shell sed --quiet 's/\(\s\+\)\?- package: /* /p' glide.yaml \
		| sort                                                                     \
		| $(nl2text))
endif
MO_PARAMS = HELP_OUT="$(1l_help_out)" \
	THANKS_OUT="$(1l_thanks_out)"     \
	BINARY="$(binary)"

#===============================================================================
#  targets
#    `make [help]` shows tasks what you should execute.
#    The other are helper targets.
#===============================================================================
.DEFAULT_GOAL := help

# [Add a help target to a Makefile that will allow all targets to be self documenting]
# https://gist.github.com/prwhite/8168133
.PHONY: help
help: ## show help
	@echo 'USAGE: make [target]'
	@echo
	@echo 'TARGETS:'
	@grep -E '^[^#]+##' $(MAKEFILE_LIST) \
		| sed 's/:[^#]\+/:/'             \
		| column -t -s ':#'

# install development tools
.PHONY: setup
setup:
ifeq ($(shell type -a glide 2>/dev/null),)
	curl https://glide.sh/get | sh
endif
ifeq ($(wildcard $(mo)),)
	wget https://raw.githubusercontent.com/tests-always-included/mo/master/mo -O $(mo) \
		&& chmod u+x $(mo)
endif
	go get -v -u github.com/alecthomas/gometalinter
	go get -v -u github.com/tcnksm/ghr
	gometalinter --install
	cp -a $(tool_dir)/etc/git_hooks/* .git/hooks/
	mkdir -p .github
	BINARY="$(binary)" $(mo) $(tool_dir)/etc/template/ISSUE_TEMPLATE.md > .github/ISSUE_TEMPLATE.md

.PHONY: deps-install
deps-install: setup ## install vendor packages based on glide.lock or glide.yaml
	glide install --strip-vendor

# You need to do this task when you have updated or installed packages, because godoc
# reads files generated by `go install`.
.PHONY: install
install: ## it is necessary to notify godoc when packages have been updated or installed newly
ifneq ($(wildcard glide.yaml),)
	-go install $(shell sed --quiet 's/\(\s\+\)\?- package: /.\/vendor\//p' glide.yaml)
endif
	CGO_ENABLED=0 go install $(subst -a ,,$(static_flags)) -ldflags "$(ld_flags)"

.PHONY: lint
lint: install ## lint go sources and check whether only LICENSE file has copyright sentence
	gometalinter $(GOMETALINTER_OPTS)                                                  \
		$(if $(GOMETALINTER_EXCLUDE_REGEX), --exclude='$(GOMETALINTER_EXCLUDE_REGEX)') \
		$(shell glide novendor)
	$(tool_dir)/copyright_check.sh

.PHONY: push-release-tag
push-release-tag: lint test ## update CHANGELOG and push all of the your development works
	$(tool_dir)/add_changelog.sh "$(new_tag)"
	git checkout master
	git merge --ff "$(latest_local_devel_branch)"
	git push
	$(tool_dir)/add_release_tag.sh "$(new_tag)"
	git branch --move "$(latest_local_devel_branch)" "$(latest_local_devel_branch)-pushed"

.PHONY: test
test: ## go test
	go test -v -cover $(shell glide novendor)

.PHONY: all-build
all-build: lint test
	$(tool_dir)/build_static_bins.sh "$(ALL_OS)" "$(ALL_ARCH)"      \
		$(static_flags)" "$(ld_flags)" $(pkg_dest_dir)" "$(binary)"

.PHONY: all-archive
all-archive:
	$(tool_dir)/archive.sh "$(ALL_OS)" "$(ALL_ARCH)" "$(pkg_dest_dir)"

.PHONY: release
release: all-build all-archive ## build binaries for all platforms and upload them to GitHub
	ghr "$(version)" "$(release_dir)"

.PHONY: clean
clean: ## uninstall the binary and remove $(release_dir) directory
	go clean -i .
	rm -rf $(release_dir)

.PHONY: readme.md
readme.md: ## create README.md using template $(readme_template)
	@$(MO_PARAMS) $(mo) $(readme_template) > README.md
	@$(text2nl) README.md
