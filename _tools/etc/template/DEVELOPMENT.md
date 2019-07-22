## Development flow

### 0. First commit

Do the following.

```
$ git clone github.com/yuta-masano/{{ .BINARY }}.git ... # Get Repository.
$ cd .../{{ .BINARY }} # Go to Repository Directory.
$ make init # First commit.
```

When the first `git clone ...` a new, empty remote repository or `git init`, you shoud do `make init`.

### 1. Prepare development tools

This is not necessary if you have done `make init`.

```
$ make setup
```

### 2. Create the local branch and start working

Versioning conforms to the [Semantic Versioning](http://semver.org/).

The branch name contains the version number to release (e.g. `local-0.1.1`).  
In the subsequent work, the release version number is automatically obtained from the local branch name.

### 3. Commit commit commit...

Part of the commit log is used for CHANGELOG.  
For example, you can start the commit log subject with `prefix: ` to appear in CHANGELOG, such as `fix: Display explicitly help message (#2)`.

Valid prefixes are:
- change (Changes that are not backward compatible)
- feat (Add New Features)
- fix (Bug fixes)

### 4. `$ make doc`

Don't forget to update the documents before releaseing.

### 5. `$ make push-release-tag`

Perform the following sequence of tasks semi-automatically. **Requires vi operation. Not fully automatic.**

1. Update and commit CHANGELOG.
   Do the following using the script `_tool/commit_changelog.sh`.
   1. Extract the commit log you want to appear in CHANGELOG from the previous release up to the time you run the script.
   2. Write commit log to beginning of CHANGELOG.
   3. Open CHANGELOG in `vi`.
   4. **Developers manually edit CHANGELOG accordingly.**
   5. If the contents of CHANGELOG have been changed before or after editing vi, the CHANGELOG will be commited.  
      **Again, developers manually edit commit message accordingly.**
      At the time of commit, the issue numbers listed in CHENGELOG are listed in the commit log and those issue numbers are closed.
2. Merge them into the local master branch and push to the remote master branch.
3. Create the release tag and push.  
   Use the `_tool/push_release_tag.sh` to create a history of changes in the releasing version from CHANGELOG as an annotated tag and push it to remote repository.

### 6. `$ make release`

Automatically:
1. Build the binaries.
2. Create binary archive files.
3. Releasing archive files to GitHub using the latest remote tags.
