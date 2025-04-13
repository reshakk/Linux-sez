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
- `r_passw.sh` - random password (first argument - length of password);
- `check_fs.sh` - find a filesystems with UUID or label; (first argument - UUID\label)
- `check_mnt.sh` - check if filesystem mounted; (first argument - filesystem)
- `dir_size.sh` - check size of direction; 
- `iptables_block.sh` - block ip-address of specific countries;
- `ps_mem.sh` - RAM usage by processes;
- `swap_proc.sh` - use of swap by processes;
- `trash.sh` - like recycle bin;
- `wget.sh` - server load (first argument - number of cycles).

```
bash <(curl -sL https://raw.githubusercontent.com/reshakk/Ubuntu-gez/master/script/add_name_script.sh)
```

### Other cool scripts
- https://github.com/klazarsk/storagetoolkit/blob/main/topdiskconsumer - This script reports on the top disk consumers to help identify where cleanup is required.
- https://github.com/vernu/vps-audit/blob/main/vps-audit.sh -  lightweight, dependency-free bash script for security, performance auditing and infrastructure monitoring of Linux servers.
