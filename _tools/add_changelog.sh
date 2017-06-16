#!/bin/bash

# Fail on unset variables, command errors and pipe fail.
set -o nounset -o errexit -o pipefail

# Prevent commands misbehaving due to locale differences.
export LC_ALL=C LANG=C

# trap for `mktemp`
trap 'rm -f /tmp/tmp.*."$(basename --suffix='.sh' "$0")"'         0        # EXIT
trap 'rm -f /tmp/tmp.*."$(basename --suffix='.sh' "$0")"; exit 1' 1 2 3 15 # HUP QUIT INT TERM

# 既存の CHANGELOG　の先頭に新しい変更履歴を挿入したいので、
#   1. 空の一時ファイルに変更したい情報を記入。
#   2. 既存の変更履歴を 1. に追記。
#   3. 1. のファイルを CHANGELOG としてコピー。
# という手法を取っている。

#===============================================================================
#  新しい CHANGELOG を作成する
#===============================================================================
NEW_TAG="$1"
from_tag="$(git describe --always --dirty)"

commit_logs=$(git log "${from_tag%%-*}..."                                  \
	--format='    * %s'                                                     \
	--grep='([a-z]\+ #[0-9]\+'                                              \
	| sed 's/\([^'$'\x01''-'$'\x7e'']\) \([^'$'\x01''-'$'\x7e'']\)/\1\2/g')
	# 上の sed は、「全角 全角」となっている文字列から半角スペースを
	# 取り除いている。
	# 2 行以上のコミットログの件名を一行で表示すると、
	# 余計な半角スペースが含まれてしまうので、それを取り除くため。
	# 以下を使った強引な方法。
	# - bash の $'...' 表記を使って ASCII コード以外 = 半角文字以外を表現。
	# - bash の文字列結合は単に文字列を隣接させるだけでよい。
feature_logs="$(echo "$commit_logs"     | grep '(feature #'     || :)"
bug_logs="$(echo "$commit_logs"         | grep '(bug #'         || :)"
enhancement_logs="$(echo "$commit_logs" | grep '(enhancement #' || :)"
misc_logs="$(echo "$commit_logs"        | grep '(misc #'        || :)"

current_changelog="$(git show origin/master:CHANGELOG)"
new_chengelog="$(mktemp --tmpdir=/tmp --suffix=".$(basename --suffix='.sh' "$0")")"
{
	echo '# Delete this line to accept this draft.'
	echo "$NEW_TAG ($(date +'%F'))"
	if [ -n "$feature_logs" ]; then
		echo '  Feature'
		echo "${feature_logs//'(feature #'/'(#'}"
	fi
	if [ -n "$bug_logs" ]; then
		echo '  Bug'
		echo "${bug_logs//'(bug #'/'(#'}"
	fi
	if [ -n "$enhancement_logs" ]; then
		echo '  Enhancement'
		echo "${enhancement_logs//'(enhancement #'/'(#'}"
	fi
	if [ -n "$misc_logs" ]; then
		echo '  Misc'
		echo "${misc_logs//'(misc #'/'(#'}"
	fi
	echo
	echo "$current_changelog"
} > "$new_chengelog"

#===============================================================================
#  エディタで CHANGELOG を編集
#===============================================================================
befor="$(md5sum "$new_chengelog")"
vi "$new_chengelog" < $(tty) > $(tty)
after="$(md5sum "$new_chengelog")"
if [ "$befor" = "$after" ]; then
	echo 'CHANGELOG dit not modified' >&2
	exit 1
fi
grep --quiet '# Delete this line' "$new_chengelog" && :
if [ $? -eq 0 ]; then
	echo '1 st line must be deleted' >&2
	exit 1
fi

#===============================================================================
#  CHANGELOG を適用してコミット
#===============================================================================
cp --force "$new_chengelog" CHANGELOG
git add CHANGELOG

close_issues="$(echo "$commit_logs"            \
	| grep --only-matching -E '[a-z]+ #[0-9]+' \
	| sed 's/[a-z]\+/close/'                   \
	| uniq || :)"

commit_messages="$(mktemp --tmpdir=/tmp --suffix=".$(basename --suffix='.sh' "$0")")"
{
	echo "Release $NEW_TAG"
	if [ -n "$close_issues" ]; then
		echo
		echo "$close_issues"
	fi
} > "$commit_messages"

vi "$commit_messages" < $(tty) > $(tty)
git commit --file "$commit_messages"
