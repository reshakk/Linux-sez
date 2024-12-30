# Server-auto

A GUI script that serves for minimal user management, swap management, knockd service management, minimal interaction with sshd config, docker and two containers (Flatnotes and Passky) as well as nextcloud (which is deployed with snap).

## Main script for install:
``` bash
bash <(curl -sL https://raw.githubusercontent.com/reshakk/Ubuntu-gez/master/main-script.sh)
```

![image](https://github.com/reshakk/Server-auto/blob/main/GUI.png)

## Roadmap:
- [ ] Add fail2ban
- [ ] Add marzban


### Other scripts
**You can also run the scripts separately:**
- `docker-in.sh` - installer docker;
- `start-knock.sh` - downloads knockd, creates configuration files, and configures rules for iptables;
- `stop-knock.sh` - stop knockd-service;
- `swap.sh` - 2 GB swap;
- `start-swap.sh` - enable swap in fstab;
- `stop-swap.sh` - disable swap;

```
bash <(curl -sL https://raw.githubusercontent.com/reshakk/Ubuntu-gez/master/script/name_script.sh)
```
