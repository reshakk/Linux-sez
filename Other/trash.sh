# mkdir /tmp/trash
# alias rm='sh ~/trash.sh'
# source ~/.bashrc

#!/bin/sh
TRASH_DIR="/tmp/trash"
TIMESTAMP=`date +'%d-%b-%Y-%H:%M:%S'`
for i in $*; do
  FILE=`basename $i`
  mv $i ${TRASH_DIR}/${FILE}.${TIMESTAMP}
done
