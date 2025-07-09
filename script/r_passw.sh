#!/usr/bin/env bash
# Need xclip to copied pasword to the clipboard
# First argument is the length of the password

if [ $1 ]; then
        length=$1
else
        length=12
fi
_hash=$(python3 -c "
import os,base64
exec('print(base64.b64encode(os.urandom(64))[:${length}].decode(\'utf-8\'))')
")
if which xclip >/dev/null 2>&1; then 
        echo $_hash | xclip -selection clipboard
        echo "new password copied to the system clipboard"
else
        echo $_hash
fi
