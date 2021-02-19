#!/bin/bash
#===============================================================================
#         USAGE: build_static_bins.sh ALL_OS ALL_ARCH STATIC_FLAGS LD_FLAGS \
#                    PKG_DEST_DIR BINARY
#
#   DESCRIPTION: Build GO binaries for each OS and architecture.
#===============================================================================
# Fail on unset variables, command errors and pipe fail.
set -o nounset -o errexit -o pipefail

# Prevent commands misbehaving due to locale differences.
export LC_ALL=C LANG=C

#===============================================================================
#  GLOBAL DECLARATIONS
#===============================================================================
PARALLEL_NUM=3

# Script arguments
ALL_OS="$1"
ALL_ARCH="$2"
STATIC_FLAGS="$3"
LD_FLAGS="$4"
PKG_DEST_DIR="$5"
BINARY="$6"

#===============================================================================
#  MAIN SCRIPT
#===============================================================================
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
			-trimpath                                    \
			-o "$output"                                 &
		(( (cnt += 1) % $PARALLEL_NUM == 0 )) && wait
	done
done
wait
