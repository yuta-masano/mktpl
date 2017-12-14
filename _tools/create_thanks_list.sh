#!/bin/bash

# Fail on unset variables, command errors and pipe fail.
set -o nounset -o errexit -o pipefail

# Prevent commands misbehaving due to locale differences.
export LC_ALL=C LANG=C

cat Gopkg.toml                                                     \
	| tr '\n' ' '                                                  \
	| egrep --only-matching '\[\[constraint\]\] +name *= *"[^ ]+"' \
	| sed 's/\(^.*\)"\(.*\)"$/* \2/'                               \
	| sort
