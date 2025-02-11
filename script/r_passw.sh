#!/usr/bin/env bash

if [ $1 ]; then
	length=$1
else
	length=12
fi
_hash=$(python3 -c "
import os,base64
exec('print(base64.b64encode(os.urandom(64))[:${length}].decode(\'utf-8\'))')
")
echo $_hash | xclip -selection clipboard
echo "new password copied to the system clipboard"

