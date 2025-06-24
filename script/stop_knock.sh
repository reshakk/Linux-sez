#!/usr/bin/env bash

read -p "Enter port: " port

systemctl disable knockd

iptables -D INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -D INPUT -p tcp --dport "$port" -j REJECT
apt install iptables-persistent 
service netfilter-persistent save
