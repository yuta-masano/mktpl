#!/bin/bash
#===============================================================================
#         USAGE: commit_changelog.sh NEW_TAG
#
#   DESCRIPTION: Add working change history to the top of the CHANGELOG file
#                and commit it.
#===============================================================================
# Fail on unset variables, command errors and pipe fail.
set -o nounset -o errexit -o pipefail

# Prevent commands misbehaving due to locale differences.
export LC_ALL=C LANG=C

#===============================================================================
#  GLOBAL DECLARATIONS
#===============================================================================
SCRIPT_NAME="${0##*/}"
: ${TMPDIR=/tmp}
TEMP_FILE_SUFFIX="${SCRIPT_NAME//.sh/}"

# Script arguments
NEW_TAG="$1"

#===============================================================================
#  TRAPS
#===============================================================================
# trap for multiple `mktemp`
trap 'rm --force "$TMPDIR"/tmp.*."$TEMP_FILE_SUFFIX"'         0        # EXIT
trap 'rm --force "$TMPDIR"/tmp.*."$TEMP_FILE_SUFFIX"; exit 1' 1 2 3 15 # HUP QUIT INT TERM

#===============================================================================
#  MAIN SCRIPT
#===============================================================================
#---  Step 1 -------------------------------------------------------------------
# Create an empty temporary file and write the working change history to it.
# Add the old change history to the temporary file.
#-------------------------------------------------------------------------------
latest_tag="$(git describe --always --dirty)"
from_tag="${latest_tag%%-*}" # tag から dirty suffix を除去
commit_logs=$(git log "$from_tag..."                                        \
	--format='    * %s'                                                     \
	| sed 's/\([^'$'\x01''-'$'\x7e'']\) \([^'$'\x01''-'$'\x7e'']\)/\1\2/g')
	# 上の sed は、「全角 全角」となっている文字列から半角スペースを
	# 取り除いている。
	# 2 行以上のコミットログの件名を一行で表示すると、
	# 余計な半角スペースが含まれてしまうので、それを取り除く。
	# 以下の bash 機能を使っている。
	# - bash の $'...' 表記を使って ASCII コード以外 = 半角文字以外を表現。
	# - bash の文字列結合は単に文字列を隣接させるだけでよい。
current_changelog="$(git show origin/master:CHANGELOG)"
new_chengelog="$(mktemp --suffix=".$TEMP_FILE_SUFFIX")"
{
	echo '# Delete this line to accept this draft.'
	echo "$NEW_TAG ($(date +'%F'))"
	echo '  Incompatible Change'
	echo "$commit_logs" | sed --quiet 's/change: //p'
	echo '  New Feature'
	echo "$commit_logs" | sed --quiet 's/feat: //p'
	echo '  Bug Fix'
	echo "$commit_logs" | sed --quiet 's/fix: //p'
	echo
	echo "$commit_logs" | egrep --invert-match 'change:|feat:|fix:'
	echo
	echo "$current_changelog"
} > "$new_chengelog"

#---  Step 2  ------------------------------------------------------------------
# Edit the temporary file with vim.
#-------------------------------------------------------------------------------
befor="$(md5sum "$new_chengelog")"
vi "$new_chengelog" < $(tty) > $(tty)
after="$(md5sum "$new_chengelog")"
if [ "_$befor" = "_$after" ]; then
	echo 'CHANGELOG was not changed' >&2
	exit 1
fi
grep --quiet '# Delete this line' "$new_chengelog" && :
if [ $? -eq 0 ]; then
	echo '1 st line must be deleted' >&2
	exit 1
fi

#---  Step 3  ------------------------------------------------------------------
# Copy the temporary file as CHANGELOG.
#-------------------------------------------------------------------------------
cp --force "$new_chengelog" CHANGELOG

#---  Step 4  ------------------------------------------------------------------
# Edit a commit message for CHANGELOG with vim.
#-------------------------------------------------------------------------------
git add CHANGELOG
close_issues="$(echo "$commit_logs"       \
	| egrep --only-matching '\(#[0-9]+\)' \
	| sed 's/[()]//g; s/^/close /'        \
	| uniq | sort --version-sort || :)"

commit_messages="$(mktemp --suffix=".$TEMP_FILE_SUFFIX")"
{
	echo '# This is a commit message to commit CHANGELOG.'
	echo '# DO NOT FORGET to remove these lines.'
	echo "Release $NEW_TAG"
	if [ -n "$close_issues" ]; then
		echo
		echo "$close_issues"
	fi
} > "$commit_messages"
vi "$commit_messages" < $(tty) > $(tty)

#---  Step 5  ------------------------------------------------------------------
# Commit CHANGELOG.
#-------------------------------------------------------------------------------
git commit --file="$commit_messages"
