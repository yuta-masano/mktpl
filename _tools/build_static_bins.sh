#!/bin/bash

# Fail on unset variables, command errors and pipe fail.
set -o nounset -o errexit -o pipefail

# Prevent commands misbehaving due to locale differences.
export LC_ALL=C LANG=C

ALL_OS="$1"
ALL_ARCH="$2"
STATIC_FLAGS="$3"
LD_FLAGS="$4"
PKG_DEST_DIR="$5"
BINARY="$6"

PARALLEL_NUM=8

cnt=0
for os in $ALL_OS; do
	if [ "_$os" = '_windows' ]; then
		app_name="$BINARY.exe"
	else
		app_name="$BINARY"
	fi
	for arch in $ALL_ARCH; do
		output="$PKG_DEST_DIR/${os}_${arch}/$app_name"
		echo "build $output"
		GOOS="$os" GOARCH="$arch" CGO_ENABLED=0 go build \
			$STATIC_FLAGS -ldflags "$LD_FLAGS"           \
			-o "$output"                                 &
		(( (cnt += 1) % $PARALLEL_NUM == 0 )) && wait
	done
done
wait
