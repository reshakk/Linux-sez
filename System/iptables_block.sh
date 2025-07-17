# https://www.ipdeny.com/ipblocks - списки ip-адресов стран
# https://www.ip2location.com/free/visitor-blocker - конфиг для конкретного сервиса


#!/bin/bash

# Удаляем список, если он уже есть
ipset -X whitelist
# Создаем новый список
ipset -N whitelist nethash

# Скачиваем файлы тех стран, что нас интересуют и сразу объединяем в единый список
wget -O netwhite http://www.ipdeny.com/ipblocks/data/countries/{ru,ua,kz,by,uz,md,kg,de,am,az,ge,ee,tj,lv}.zone

echo -n "Загружаем белый список в IPSET..."
# Читаем список сетей и построчно добавляем в ipset
list=$(cat netwhite)
for ipnet in $list
 do
 ipset -A whitelist $ipnet
 done
echo "Завершено"
# Выгружаем созданный список в файл для проверки состава
ipset -L whitelist > w-export
