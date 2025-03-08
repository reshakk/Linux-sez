#!/usr/bin/env bash

#set -e

#Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit 1
fi

apt install bzip2 -y

useradd -md /opt/teamspeak teamspeak -s "$(which bash)"

wget https://files.teamspeak-services.com/releases/server/3.13.7/teamspeak3-server_linux_amd64-3.13.7.tar.bz2 -O /opt/teamspeak/teamspeak-server.tar.bz2

tar xfj /opt/teamspeak/teamspeak-server.tar.bz2 --strip-components 1 -C /opt/teamspeak

touch /opt/teamspeak/.ts3server_license_accepted

cat >"/etc/systemd/system/teamspeak.service" << EOF
[Unit]
Description=Teamspeak Service
Wants=network.target

[Service]
WorkingDirectory=/opt/teamspeak
User=teamspeak
ExecStart=/opt/teamspeak/ts3server_minimal_runscript.sh
ExecStop=/opt/teamspeak/ts3server_startscript.sh stop
ExecReload=/opt/teamspeak/ts3server_startscript.sh restart
Restart=always
RestartSec=15

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

systemctl start teamspeak

systemctl enable teamspeak

chown -R teamspeak:teamspeak /opt/teamspeak  
