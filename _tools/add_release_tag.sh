#!/bin/bash

# Fail on unset variables, command errors and pipe fail.
set -o nounset -o errexit -o pipefail

# Prevent commands misbehaving due to locale differences.
export LC_ALL=C LANG=C

# 注釈付きタグを作成してリモートに push する。
# 注釈の内容は今回のリリース文の CHANGELOG の内容。

NEW_TAG="$1"
tag_list="$(git describe --always --dirty)"

echo "$tag_list" | grep --quiet "$NEW_TAG" && :
if [ $? -eq 0 ]; then
	echo "$NEW_TAG already exists" >&2
	exit 1
fi

# CHANGELOG を上から一行ずつ読み込んでリリース向けバージョンに該当する
# 変更履歴だけを取り出す。
is_target_tag=false
buff=""
while IFS= read line; do # 行頭・行末のホワイトスペースを維持したい。
	echo "$line" | grep --quiet "$NEW_TAG" && :
	if [ $? -eq 0 ]; then
		is_target_tag=true
		buff+="$line\n"
		continue
	fi

	echo "$line" | grep --quiet -E "^[0-9]+\.[0-9]+\.[0-9]+" && :
	if [ $? -eq 0 ] && ($is_target_tag); then
		is_target_tag=false
		continue
	fi

	if ($is_target_tag); then
		buff+="$line\n"
		continue
	fi
done < ./CHANGELOG

# $buff に入っている内容は改行が文字列 '\n' となって一行で入っている。
# また、行末が '\n\n' となっているのでそれを取り除いて文字列を改行に置換する必要がある。
changes="$(echo "$buff" | sed -e 's/\\n\\n//' -e 's/\\n/\n/g')"
git tag -a "$NEW_TAG" -m "$changes"
git push --tags
