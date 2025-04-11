# https://www.ipdeny.com/ipblocks - списки ip-адресов стран
# https://www.ip2location.com/free/visitor-blocker - конфиг для конкретного сервиса


#!/bin/bash

# Delete list if it already exists
ipset -X whitelist
# Create a new list
ipset -N whitelist nethash

# Download the files of those countries that we are interested in and combine them into a single list at once
wget -O netwhite http://www.ipdeny.com/ipblocks/data/countries/{ru,ua,kz,by,uz,md,kg,de,am,az,ge,ee,tj,lv}.zone

echo -n "Export file in IPSET..."
# Read the list of networks and add to ipset line by line
list=$(cat netwhite)
for ipnet in $list
 do
 ipset -A whitelist $ipnet
 done
# Export list in file
ipset -L whitelist > w-export
