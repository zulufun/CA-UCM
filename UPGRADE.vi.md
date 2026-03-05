# Hướng dẫn Nâng cấp UCM

Hướng dẫn này bao gồm việc nâng cấp UCM lên các phiên bản mới hơn theo các phương thức cài đặt khác nhau.

## Mục lục

- [Nâng cấp Docker](#nâng-cấp-docker)
- [Nâng cấp Gói DEB](#nâng-cấp-gói-deb)
- [Nâng cấp Gói RPM](#nâng-cấp-gói-rpm)
- [Nâng cấp Cài đặt từ Nguồn](#nâng-cấp-cài-đặt-từ-nguồn)
- [Lưu ý Theo Phiên bản](#lưu-ý-theo-phiên-bản)

---

## Nâng cấp Docker

### Dùng Docker Compose

```bash
# 1. Sao lưu dữ liệu hiện tại
docker-compose exec ucm cp /opt/ucm/data/ucm.db /opt/ucm/data/backups/manual-backup-$(date +%Y%m%d).db

# 2. Tải image mới
docker-compose pull

# 3. Khởi động lại container
docker-compose down
docker-compose up -d

# 4. Kiểm tra nhật ký
docker-compose logs -f ucm
```

### Lệnh Docker Thủ công

```bash
# 1. Dừng container
docker stop ucm

# 2. Sao lưu dữ liệu
docker cp ucm:/opt/ucm/data/ucm.db ./backup-$(date +%Y%m%d).db

# 3. Xóa container cũ
docker rm ucm

# 4. Tải image mới
docker pull neyslim/ultimate-ca-manager:latest

# 5. Khởi động container mới
docker run -d \
  --name ucm \
  -p 8443:8443 \
  -v ucm-data:/opt/ucm/data \
  -e UCM_FQDN=ucm.example.com \
  neyslim/ultimate-ca-manager:latest
```

---

## Nâng cấp Gói DEB

### Nâng cấp Tự động

```bash
# Tải phiên bản mới (thay VERSION, ví dụ 2.48)
wget https://github.com/NeySlim/ultimate-ca-manager/releases/latest/download/ucm_VERSION_all.deb

# Cài đặt (tự động sao lưu database)
sudo dpkg -i ucm_VERSION_all.deb

# Sửa dependency nếu cần
sudo apt-get install -f
```

**Quá trình nâng cấp:**
1. Tự động tạo bản sao lưu trước khi nâng cấp
2. Dừng dịch vụ một cách an toàn
3. Cập nhật file
4. Migrate database (nếu schema thay đổi)
5. Giữ nguyên cấu hình
6. Khởi động lại dịch vụ

### Sao lưu Thủ công Trước khi Nâng cấp

```bash
sudo systemctl stop ucm
sudo cp /opt/ucm/data/ucm.db ~/ucm-backup-$(date +%Y%m%d).db
sudo cp /etc/ucm/ucm.env ~/ucm-config-backup.env
sudo systemctl start ucm
```

### Hoàn tác

```bash
sudo systemctl stop ucm

# Khôi phục database
sudo cp /opt/ucm/data/backups/ucm-pre-upgrade-*.db /opt/ucm/data/ucm.db

# Cài đặt lại phiên bản trước
sudo dpkg -i ucm_<phiên-bản-trước>_all.deb

sudo systemctl start ucm
```

---

## Nâng cấp Gói RPM

### Dùng DNF/YUM

```bash
# Tải phiên bản mới (thay VERSION, ví dụ 2.48)
wget https://github.com/NeySlim/ultimate-ca-manager/releases/latest/download/ucm-VERSION-1.noarch.rpm

# Nâng cấp
sudo dnf upgrade ./ucm-VERSION-1.noarch.rpm
```

### Sao lưu Thủ công

```bash
sudo systemctl stop ucm
sudo cp /opt/ucm/data/ucm.db ~/ucm-backup-$(date +%Y%m%d).db
sudo systemctl start ucm
```

---

## Nâng cấp Cài đặt từ Nguồn

### Cài đặt Dựa trên Git

```bash
# 1. Dừng dịch vụ
sudo systemctl stop ucm

# 2. Sao lưu database
sudo cp /opt/ucm/data/ucm.db ~/ucm-backup-$(date +%Y%m%d).db

# 3. Tải cập nhật
cd /opt/ucm
git fetch --tags
git checkout <version-tag>

# 4. Cập nhật dependency
cd backend
pip install -r requirements.txt --upgrade

# 5. Khởi động lại dịch vụ
sudo systemctl start ucm
```

Các migration database chạy tự động khi khởi động.

---

## Lưu ý Theo Phiên bản

### Nâng cấp lên v2.48 từ v2.1.x

**Không có thay đổi phá vỡ tương thích** — có thể nâng cấp trực tiếp.

> **Lưu ý:** UCM chuyển từ Semantic Versioning (2.1.x) sang định dạng Major.Build (2.48) từ bản phát hành này. Bước nhảy phiên bản từ 2.1.x lên 2.48 là có chủ ý và bình thường.

**Mới trong v2.48:**
- Bộ test backend toàn diện (1364 test, ~95% độ phủ route)
- Hệ thống ucm-watcher để khởi động lại dịch vụ an toàn và tự cập nhật
- Huy hiệu thử nghiệm cho các tính năng chưa kiểm tra (mTLS, HSM, SSO)
- Luồng đăng nhập 2FA TOTP với thiết lập QR code
- Cơ chế tự cập nhật qua GitHub releases

**Tự cập nhật (DEB/RPM):**
UCM hiện có thể kiểm tra và cài đặt cập nhật tự động. Dịch vụ systemd ucm-watcher theo dõi các signal file:
- `/opt/ucm/data/.restart_requested` — kích hoạt khởi động lại dịch vụ
- `/opt/ucm/data/.update_pending` — kích hoạt cài đặt gói + khởi động lại

Không cần thao tác thủ công — các cập nhật được kích hoạt từ trang Settings > System.

### Nâng cấp lên v2.1.0 từ v2.0.x

**Không có thay đổi phá vỡ tương thích** — có thể nâng cấp trực tiếp.

**Tính năng mới:**
- Khớp chuỗi chứng chỉ dựa trên AKI/SKI (migration tự động khi khởi động)
- Scheduler sửa chuỗi (task nền hàng giờ)
- Widget sửa chuỗi trên trang CAs
- Loại trùng lặp trong Smart Import (ngăn CA trùng lặp)
- Giao diện quản lý Webhook
- i18n 9 ngôn ngữ

**Migration tự động:**
- Khi khởi động lần đầu, UCM điền các trường SKI/AKI cho tất cả CA và chứng chỉ hiện có
- CA và chứng chỉ mồ côi tự động được kết nối lại nếu CA cha tồn tại
- CA trùng lặp (cùng Subject Key Identifier) được gộp lại

Không cần thao tác — toàn bộ migration diễn ra tự động.

### Nâng cấp từ v1.8.x lên v2.0.x

**Nâng cấp phiên bản lớn** -- dữ liệu được migrate tự động.

- Đường dẫn database chuyển từ `/var/lib/ucm/` sang `/opt/ucm/data/`
- Frontend thay thế: HTMX -> React 18
- Xác thực: JWT -> session cookie
- Bản sao lưu được tạo tự động trong quá trình nâng cấp

Các bước:
1. Quy trình nâng cấp tiêu chuẩn (cài đặt gói mới)
2. Không cần thay đổi cấu hình
3. Kiểm tra nhật ký: `journalctl -u ucm -n 50`

---

## Xử lý Sự cố

### Nâng cấp Thất bại - Dịch vụ Không Khởi động

```bash
# Kiểm tra nhật ký
sudo journalctl -u ucm -n 100 --no-pager

# Các cách sửa phổ biến:

# 1. Vấn đề quyền
sudo chown -R ucm:ucm /opt/ucm/data
sudo chown -R ucm:ucm /var/log/ucm

# 2. Thiếu dependency
sudo apt-get install -f     # Debian/Ubuntu
sudo dnf install -y ucm     # RHEL

# 3. Database bị hỏng
sudo systemctl stop ucm
sudo cp /opt/ucm/data/backups/ucm-pre-upgrade-*.db /opt/ucm/data/ucm.db
sudo systemctl start ucm
```

### Mất Cấu hình

```bash
sudo cp ~/ucm-config-backup.env /etc/ucm/ucm.env
sudo systemctl restart ucm
```

### Xung đột Cổng Sau Nâng cấp

```bash
sudo netstat -tlnp | grep 8443
# Đổi cổng trong /etc/ucm/ucm.env: HTTPS_PORT=8444
sudo systemctl restart ucm
```

---

## Thực hành Tốt nhất

### Trước khi Nâng cấp

1. Đọc ghi chú phát hành để biết các thay đổi phá vỡ tương thích
2. Sao lưu database thủ công
3. Kiểm tra trong môi trường staging trước
4. Đảm bảo đủ dung lượng đĩa cho bản sao lưu

### Sau khi Nâng cấp

1. Kiểm tra trạng thái dịch vụ: `systemctl status ucm`
2. Xem lại nhật ký để tìm lỗi
3. Kiểm tra đăng nhập và các thao tác cơ bản
4. Xác minh CA và chứng chỉ hiện có

---

## Hỗ trợ

- **Nhật ký:** `journalctl -u ucm -f` hoặc `docker logs -f ucm`
