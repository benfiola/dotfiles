#!/bin/sh -e
if [ "$LS_CAN_USE_COLORS" = "" ]; then
    command "$LS_BIN" "$@"
else
    command "$LS_BIN" --color=auto "$@"
fi
