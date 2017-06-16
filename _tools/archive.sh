#!/bin/bash

# Fail on unset variables, command errors and pipe fail.
set -o nounset -o errexit -o pipefail

# Prevent commands misbehaving due to locale differences.
export LC_ALL=C LANG=C

ALL_OS="$1"
ALL_ARCH="$2"
PKG_DEST_DIR="$3"

cd "$PKG_DEST_DIR"
for os in $ALL_OS; do
	for arch in $ALL_ARCH; do
		if $(echo "${os}_${arch}" | grep --quiet 'linux'); then # is linux os?
			tar zcvf "../${os}_${arch}.tar.gz" "${os}_${arch}"     #   -> tar.gz
		else                                                    # is win, mac os?
			zip -r  "../${os}_${arch}.zip" "${os}_${arch}"         #   -> zip
		fi
	done;
done
