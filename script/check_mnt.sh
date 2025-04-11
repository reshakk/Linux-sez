# Usage: ./check_mnt /mnt/mount_point
# findmnt -x can check fstab file for errors

if findmnt -rno TARGET "$1" >/dev/null; then 
    echo "$1 mounted."
else
    echo "$1 not mounted."
fi
