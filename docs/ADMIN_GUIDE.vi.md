# Hướng dẫn Quản trị UCM

Hướng dẫn quản trị và cấu hình Ultimate CA Manager.

---

## Tổng quan Cấu hình

UCM lưu dữ liệu tại:
- **Cơ sở dữ liệu** -- `/opt/ucm/data/ucm.db` (SQLite)
- **Thư mục dữ liệu** -- `/opt/ucm/data/` (chứng chỉ, khóa, bản sao lưu)
- **Cấu hình** -- `/etc/ucm/ucm.env` (DEB/RPM) hoặc biến môi trường (Docker)
- **Nhật ký** -- `/var/log/ucm/` (DEB/RPM) hoặc stdout (Docker)

---

## Cấu hình Máy chủ

### Biến Môi trường

| Biến | Mặc định | Mô tả |
|------|----------|-------|
| `UCM_SECRET_KEY` | (tự tạo) | Khóa ký session |
| `UCM_HOST` | `0.0.0.0` | Địa chỉ bind |
| `UCM_PORT` | `8443` | Cổng HTTPS |
| `UCM_DATA_DIR` | `/opt/ucm/data` | Lưu trữ dữ liệu |
| `UCM_LOG_LEVEL` | `INFO` | Mức độ chi tiết log |
| `UCM_HTTPS_CERT` | (tự động) | Chứng chỉ máy chủ |
| `UCM_HTTPS_KEY` | (tự động) | Khóa riêng tư máy chủ |

### Dịch vụ Systemd

```bash
# Kiểm tra trạng thái
sudo systemctl status ucm

# Khởi động lại dịch vụ
sudo systemctl restart ucm

# Xem nhật ký
sudo journalctl -u ucm -f

# Bật tự khởi động cùng hệ thống
sudo systemctl enable ucm
```

Dịch vụ chạy với người dùng `ucm` và quyền hạn chế (NoNewPrivileges, ProtectSystem=strict).

### Xoay vòng Nhật ký

Nhật ký được xoay vòng tự động qua logrotate:
- Vị trí: `/etc/logrotate.d/ucm`
- Xoay vòng: Hàng ngày, giữ 14 bản
- Nén: gzip

Xem [LOG_ROTATION.md](LOG_ROTATION.md) để biết thêm chi tiết.

---

## Cấu hình Bảo mật

### Chứng chỉ HTTPS

UCM tự động tạo chứng chỉ tự ký khi chạy lần đầu.

**Thay thế bằng chứng chỉ tin cậy:**

1. Vào **Settings** > tab **Security**
2. Chọn chứng chỉ từ CA của bạn
3. Nhấp **Apply HTTPS Certificate**
4. Khởi động lại dịch vụ: `sudo systemctl restart ucm`

**Hoặc qua file:**
```bash
sudo cp /path/to/cert.pem /opt/ucm/data/https_cert.pem
sudo cp /path/to/key.pem /opt/ucm/data/https_key.pem
sudo chown ucm:ucm /opt/ucm/data/https_*.pem
sudo systemctl restart ucm
```

### Bảo mật Session

Cấu hình tại **Settings** > **Security**:

| Cài đặt | Mặc định | Mô tả |
|---------|----------|-------|
| Thời gian hết hạn Session | 24h | Tự đăng xuất sau thời gian không hoạt động |
| Số Session tối đa | 5 | Giới hạn session trên mỗi người dùng |
| Bắt buộc 2FA | Không | Yêu cầu MFA cho tất cả người dùng |

### Phương thức Xác thực

Bật/tắt tại **Settings** > **Security**:

- **Mật khẩu** -- Username/password tiêu chuẩn
- **2FA TOTP** -- Mật khẩu một lần theo thời gian
- **WebAuthn** -- Khóa bảo mật phần cứng
- **mTLS** -- Xác thực bằng chứng chỉ client

### Quản lý Chứng chỉ mTLS

Chứng chỉ client mTLS có thể được đăng ký từ tab **Account → mTLS**. Sau khi đăng ký, chứng chỉ được UCM quản lý hoàn toàn:

- **Trang User Certificates** (`/user-certificates`) — Trang chuyên dụng để liệt kê, xuất, thu hồi và xóa tất cả chứng chỉ client mTLS
- **Xuất** — Tải xuống dạng PEM (kèm khóa và chuỗi) hoặc PKCS12 (bảo vệ bằng mật khẩu)
- **Thu hồi** — Thu hồi với lý do (khóa bị lộ, đã thay thế, v.v.)
- **RBAC** — Viewer chỉ thấy chứng chỉ của mình; operator và admin thấy tất cả

---

## Thông báo Email

### Cấu hình SMTP

Cấu hình cài đặt SMTP tại **Settings → Email** để bật thông báo email:

- **SMTP Host/Port** — Địa chỉ và cổng máy chủ mail
- **Thông tin đăng nhập** — Username và mật khẩu (nếu cần)
- **Mã hóa** — Không có, STARTTLS, hoặc SSL/TLS
- **Địa chỉ gửi** — Email gửi cho tất cả thông báo
- **Loại nội dung** — HTML, Plain Text, hoặc Cả hai
- **Người nhận cảnh báo** — Một hoặc nhiều địa chỉ email để nhận cảnh báo hết hạn

Dùng nút **Test** để gửi email kiểm tra và xác minh kết nối.

### Trình chỉnh sửa Template Email

Tùy chỉnh template email thông báo qua trình chỉnh sửa tích hợp sẵn:

1. Vào **Settings → Email → Email Template**
2. Nhấp **Edit Template** để mở cửa sổ chỉnh sửa nổi
3. Chuyển đổi giữa tab **HTML** và **Plain Text**
4. Chỉnh sửa mã nguồn template bên trái, xem trước trực tiếp bên phải
5. Các biến có sẵn: `{{title}}`, `{{content}}`, `{{datetime}}`, `{{instance_url}}`, `{{logo}}`, `{{title_color}}`
6. Nhấp **Save** để áp dụng, hoặc **Reset to Default** để khôi phục template mặc định của UCM

### Cảnh báo Hết hạn

Khi SMTP đã cấu hình, bật cảnh báo hết hạn chứng chỉ tự động:

- Bật/tắt thông báo
- Chọn ngưỡng cảnh báo (90, 60, 30, 14, 7, 3, 1 ngày trước khi hết hạn)
- **Check Now** kích hoạt quét ngay tất cả chứng chỉ

---

## Sao lưu & Khôi phục

### Tạo Bản sao lưu

**Qua giao diện:**
1. Vào **Settings** > tab **Backup**
2. Nhấp **Create Backup**
3. Nhập mật khẩu mã hóa
4. Tải xuống file `.ucmbkp`

**Qua dòng lệnh:**
```bash
sudo systemctl stop ucm
sudo cp /opt/ucm/data/ucm.db ~/ucm-backup-$(date +%Y%m%d).db
sudo systemctl start ucm
```

### Khôi phục Bản sao lưu

**Qua giao diện:**
1. Vào **Settings** > tab **Backup**
2. Nhấp **Restore Backup**
3. Tải lên file `.ucmbkp`
4. Nhập mật khẩu mã hóa

### Nội dung Bản sao lưu

- Tất cả chứng chỉ và khóa riêng tư
- Phân cấp CA
- Người dùng và cài đặt
- Nhật ký kiểm tra
- Template

---

## Quản lý Cơ sở dữ liệu

### Cơ sở dữ liệu SQLite

Vị trí: `/opt/ucm/data/ucm.db`

**Tối ưu hóa cơ sở dữ liệu:**
```bash
sudo systemctl stop ucm
sqlite3 /opt/ucm/data/ucm.db "VACUUM;"
sudo systemctl start ucm
```

**Xuất cơ sở dữ liệu:**
```bash
sqlite3 /opt/ucm/data/ucm.db ".dump" > ucm_dump.sql
```

### Bảng Cơ sở dữ liệu

| Bảng | Mục đích |
|------|----------|
| `users` | Tài khoản người dùng |
| `certificates` | Bản ghi chứng chỉ |
| `certificate_authorities` | Bản ghi CA |
| `audit_logs` | Nhật ký kiểm tra hoạt động |
| `settings` | Cài đặt ứng dụng |
| `templates` | Template chứng chỉ |
| `acme_accounts` | Tài khoản ACME client |
| `scep_requests` | Yêu cầu đăng ký SCEP |

---

## Quản trị Giao thức

### Phân phối CRL

**Cấu hình endpoint CRL:**
1. URL CRL: `https://your-server:8443/crl/<ca-id>.crl`
2. Cấu hình trong cài đặt CA > tab CRL
3. Đặt khoảng thời gian tái tạo

### Cấu hình OCSP

OCSP responder chạy tự động:
- URL: `https://your-server:8443/ocsp`
- Ký: Sử dụng chứng chỉ CA phát hành
- Cache: Cache response 5 phút

### Quản trị ACME

Xem tài khoản và đơn hàng ACME trong trang ACME, hoặc qua API:

```bash
curl -k -b cookies.txt https://localhost:8443/api/v2/acme/accounts
```

### Quản trị SCEP

Xem các yêu cầu SCEP đang chờ trong trang SCEP, hoặc qua API:

```bash
curl -k -b cookies.txt https://localhost:8443/api/v2/scep/requests?status=pending
```

---

## Quản trị Người dùng

### Đặt lại Mật khẩu

**Admin đặt lại:**
1. Vào trang **Users**
2. Chọn người dùng
3. Nhấp **Reset Password**
4. Đặt mật khẩu tạm thời
5. Người dùng phải đổi mật khẩu ở lần đăng nhập tiếp theo

### Quản lý Vai trò

| Vai trò | Chứng chỉ | CA | Người dùng | Cài đặt |
|---------|------------|-----|------------|---------|
| Admin | Toàn quyền | Toàn quyền | Toàn quyền | Toàn quyền |
| Operator | Toàn quyền | Toàn quyền | Đọc | Đọc |
| Auditor | Đọc | Đọc | Không | Không |
| Viewer | Đọc (giới hạn) | Đọc | Không | Không |

### API Key

Người dùng có thể tạo API key để tự động hóa:
1. Vào **Account** > **API Keys**
2. Nhấp **Generate Key**
3. Sao chép key (chỉ hiển thị một lần)
4. Dùng trong header `X-API-Key`

---

## Giám sát

### Kiểm tra Sức khỏe

```bash
curl -k https://localhost:8443/api/health
# Hoặc từ xa: curl -k https://your-server-fqdn:8443/api/health
```

### Chỉ số Giám sát

Các chỉ số quan trọng cần theo dõi:
- Ngày hết hạn chứng chỉ
- Thời hạn hiệu lực CA
- Dung lượng đĩa cho thư mục dữ liệu
- Kích thước cơ sở dữ liệu

### Nhật ký Kiểm tra

Tất cả hành động đều được ghi lại:
- Vào trang **Audit**
- Lọc theo hành động, người dùng, ngày tháng
- Xuất CSV để tuân thủ quy định

---

## Nâng cấp

Xem [UPGRADE.md](../UPGRADE.md) để biết các bước migration theo từng phiên bản.

---

## Xử lý Sự cố

### Dịch vụ Không Khởi động

```bash
# Kiểm tra nhật ký
sudo journalctl -u ucm -n 100

# Kiểm tra quyền
ls -la /opt/ucm/data/
sudo chown -R ucm:ucm /opt/ucm/data/

# Kiểm tra cổng
sudo netstat -tlpn | grep 8443
```

### Cơ sở dữ liệu Bị Khóa

```bash
# Tìm tiến trình đang khóa
fuser /opt/ucm/data/ucm.db

# Dừng dịch vụ và sửa
sudo systemctl stop ucm
sqlite3 /opt/ucm/data/ucm.db "PRAGMA integrity_check;"
sudo systemctl start ucm
```

---

## Tham khảo

- [Hướng dẫn Người dùng](USER_GUIDE.md)
- [Tài liệu tham khảo API](API_REFERENCE.md)
- [Cài đặt](installation/README.md)
- [Nhật ký thay đổi](../CHANGELOG.md)
