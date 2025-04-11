# Usage: ./check_fs.sh UUID

if findfs "UUID=$1" >/dev/null; then 
echo "$1 connected."
else
echo "$1 not connected."
fi
