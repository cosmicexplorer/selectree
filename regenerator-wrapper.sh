#!/bin/sh

# regenerator has stupid output on success, so remove that, but do display
# output on failure
regen_script=$@
tmp=$(mktemp)
trap "rm -f $tmp" EXIT
if ! $regen_script 2>"$tmp"; then
  cat "$tmp" >&2
fi
