# https://looking.house/ - list of hosters

#!/bin/bash
steps=$1
for ((i=0;i<$steps;i++))
do
 echo "$i STEP, TO STOP [CTRL+C]"
 wget -O /dev/null https://speedtest.selectel.ru/100MB
 wget -O /dev/null https://msk.lg.aeza.net/files/100MB
 wget -O /dev/null https://45-67-230-12.lg.looking.house/100.mb
 wget -O /dev/null https://185-43-4-155.lg.looking.house/100.mb
 wget -O /dev/null https://185-231-154-182.lg.looking.house/100.mb
done
