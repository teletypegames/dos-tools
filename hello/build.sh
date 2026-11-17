#!/bin/sh
set -eu
cd "$(dirname "$0")"

field() { sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" ../metadata.json | head -n 1; }
EXE="$(field folder)"
[ -n "$EXE" ] || EXE="$(field name | tr '[:lower:]' '[:upper:]' | tr -cd 'A-Z0-9' | cut -c1-8)"

WATCOM=${WATCOM:-$HOME/.local/opt/watcom}
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) WATCOM_BIN=armo64 ;;
  Darwin-*) WATCOM_BIN=bino64 ;;
  Linux-aarch64) WATCOM_BIN=arml64 ;;
  *) WATCOM_BIN=binl64 ;;
esac
export WATCOM PATH="$WATCOM/$WATCOM_BIN:$PATH" INCLUDE="$WATCOM/h"
mkdir -p build
wcl -q -bt=dos -ms -fo=build/ -fe="../$EXE.EXE" hello.c
