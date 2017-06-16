#!/bin/bash

# Fail on unset variables, command errors and pipe fail.
set -o nounset -o errexit -o pipefail

# Prevent commands misbehaving due to locale differences.
export LC_ALL=C LANG=C

# Copyright © {{.year}} {{author}} が記載されているファイル名を取得。
#          ~~~ <- LANG=C の場合、regex 的には .... になるので注意。
# ただし、LICENSE ファイルは除く。
sources=$(grep --binary-files=without-match --recursive --files-with-match     \
	--exclude-dir=vendor --extended-regexp 'Copyright....[0-9]{4} Yuta MASANO' \
	| grep --invert-match 'LICENSE' || :)

[ -z "$sources" ] && exit
# LICENSE ファイル以外の Copyright 文は不許可。
echo 'NG: the following sources still have a copyright sentence' >&2
for src in $sources; do
	echo "**** $src ****"
	head --lines 3 "$src"
	echo
done
exit 1
