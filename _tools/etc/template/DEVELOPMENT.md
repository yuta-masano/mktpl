## Development flow

### 0. First commit

Execute `make init` on an empty repository instead of `git init`. The initialization of the repository is done by Makefile task.

```
$ git clone github.com/yuta-masano/{{ .BINARY }}.git ... # Get Repository.
$ cd .../{{ .BINARY }} # Go to Repository Directory.
$ make init # First commit.
```

### 1. Prepare development tools

This is not necessary if you have done `make init`.

```
$ make setup
```

### 2. Create the local branch and start working

Versioning follows [Semantic Versioning](http://semver.org/).

The name of the branch must contain the version number to be released (e.g. `local-0.1.1`), so that subsequent works automatically get the release version number from the local branch name.

### 3. Commit commit commit...

Part of the commit log is used for CHANGELOG.  
If you start the commit log with "prefix:" in the subject, such as `fix: Display explicitly help message (#2)`, the subject is used in CHANGELOG.

Valid prefixes are:
- change (Changes that are not backward compatible)
- feature (Add New Features)
- fix (Bug fixes)

### 4. `$ make doc`

Don't forget to update the documents before releaseing.

### 5. `$ make push-release-tag`

Perform the following sequence of tasks semi-automatically. **Requires vi operation. Not fully automatic.**

1. Update and commit CHANGELOG.  
   Execute `_tool/commit_changelog.sh` to do the following.
   1. Check the commit message from the last release to this point and extract the subject to be used in CHANGELOG.
   2. Write commit log to beginning of CHANGELOG.
   3. Open CHANGELOG in `vi`.
   4. **Developers manually edit CHANGELOG.**
   5. If the contents of CHANGELOG have been changed before and after editing, the CHANGELOG is commited.  
      **Again, developers manually edit commit message.**
      When committing, the issue numbers listed in CHANGELOG are written in the commit log and those issue numbers are closed.
2. Merge them into the local master branch and push to the remote master branch.
3. Create the release tag and push.  
   Execute `_tool/push_release_tag.sh` to create a history of changes in the releasing version from CHANGELOG as an annotated tag and push it to remote repository.

### 6. `$ make release`

Automatically:
1. Build the binaries.
2. Create binary archive files.
3. Releasing archive files to GitHub using the latest remote tags.
