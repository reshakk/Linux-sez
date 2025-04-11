# Server-auto

A GUI script that serves for minimal user management, swap management, knockd service management, minimal interaction with sshd config and docker.
And also more scripts to simplify life.

## Main script for install:
``` bash
bash <(curl -sL https://raw.githubusercontent.com/reshakk/Ubuntu-gez/master/main_script.sh)
```

![image](https://github.com/reshakk/Server-auto/blob/main/GUI.png)

## Roadmap:
- [ ] Add fail2ban
- [ ] Add marzban


### Other scripts
**You can also run the scripts separately:**
- `docker_in.sh` - installer docker;
- `start_knock.sh` - downloads knockd, creates configuration files, and configures rules for iptables;
- `stop_knock.sh` - stop knockd-service;
- `swap.sh` - 2 GB swap;
- `start_swap.sh` - enable swap in fstab;
- `stop_swap.sh` - disable swap;
- `r_passw` - random password (first argument - length of password)

```
bash <(curl -sL https://raw.githubusercontent.com/reshakk/Ubuntu-gez/master/script/add_name_script.sh)
```
