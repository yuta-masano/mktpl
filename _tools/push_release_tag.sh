#!/bin/bash
#===============================================================================
#         USAGE: push_release_tag.sh NEW_TAG
#
#   DESCRIPTION: Create an annotation tag and push it to remote repository.
#                The content of the annotation is the content of CHANGELOG
#                which will be released this time.
#===============================================================================
# Fail on unset variables, command errors and pipe fail.
set -o nounset -o errexit -o pipefail

# Prevent commands misbehaving due to locale differences.
export LC_ALL=C LANG=C

#===============================================================================
#  GLOBAL DECLARATIONS
#===============================================================================
# Script arguments
NEW_TAG="$1"

#===============================================================================
#  MAIN SCRIPT
#===============================================================================
tag_list="$(git describe --always --dirty)"
echo "$tag_list" | grep --quiet "$NEW_TAG" && :
if [ $? -eq 0 ]; then
	echo "$NEW_TAG already exists" >&2
	exit 1
fi

# CHANGELOG を上から一行ずつ読み込んでリリース向けバージョンに該当する
# 変更履歴だけを取り出す。
is_target_tag=false
changes=""
while IFS= read line; do # IFS= COMMAND でタブ、スペースを維持。
	echo "$line" | grep --quiet "$NEW_TAG" && :
	if [ $? -eq 0 ]; then
		is_target_tag=true
		changes+="$line"$'\n'
		continue
	fi

	echo "$line" | egrep --quiet "^[0-9]+\.[0-9]+\.[0-9]+" && :
	if [ $? -eq 0 ] && ($is_target_tag); then
		is_target_tag=false
		continue
	fi

	if ($is_target_tag); then
		changes+="$line"$'\n'
		continue
	fi
done < ./CHANGELOG
git tag --annotate --message="$changes" "$NEW_TAG"
git push --tags
