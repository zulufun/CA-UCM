# Tài liệu Bảo mật

Ultimate CA Manager triển khai các tính năng bảo mật toàn diện để bảo vệ hạ tầng PKI của bạn.

## Tính năng Bảo mật

### 1. Mã hóa Khóa Riêng tư

Tất cả khóa riêng tư (CA và chứng chỉ) đều được mã hóa khi lưu trữ bằng **Fernet** (AES-256-CBC với HMAC-SHA256).

#### Cấu hình

Mã hóa khóa riêng tư được quản lý từ **Settings** > **Security** trong giao diện web. Khóa chính được lưu tại `/etc/ucm/master.key`.

Hoặc qua API (dùng session cookie):

```bash
# Mã hóa khóa hiện có (chạy thử trước)
curl -k -b cookies.txt -X POST https://localhost:8443/api/v2/system/security/encrypt-all-keys \
  -H "Content-Type: application/json" \
  -d '{"dry_run": true}'

# Sau đó thực sự mã hóa
curl -k -b cookies.txt -X POST https://localhost:8443/api/v2/system/security/encrypt-all-keys \
  -H "Content-Type: application/json" \
  -d '{"dry_run": false}'
```

#### Lưu trữ Khóa
- Khóa được lưu mã hóa trong database với tiền tố `ENC:`
- Chỉ giải mã khi cần (xuất, ký)
- Khóa gốc không bao giờ được ghi log

---

### 2. Bảo vệ CSRF

Bảo vệ Cross-Site Request Forgery cho tất cả các yêu cầu thay đổi trạng thái.

#### Luồng Token
1. Phản hồi đăng nhập/xác minh bao gồm `csrf_token`
2. Client lưu token trong `sessionStorage`
3. Client gửi header `X-CSRF-Token` khi POST/PUT/DELETE/PATCH
4. Server xác thực chữ ký và thời hạn token

#### Định dạng Token
```
timestamp:nonce:hmac_signature
```
- Có hiệu lực trong 24 giờ
- Được ký bằng SECRET_KEY

#### Đường dẫn Miễn trừ
- `/api/v2/auth/login` (cần lấy token)
- `/acme/`, `/scep/`, `/ocsp`, `/cdp/` (endpoint giao thức)
- `/api/health` (giám sát)

---

### 3. Chính sách Mật khẩu

Bắt buộc mật khẩu mạnh cho tất cả tài khoản người dùng.

#### Yêu cầu
| Quy tắc | Giá trị |
|---------|---------|
| Độ dài tối thiểu | 8 ký tự |
| Độ dài tối đa | 128 ký tự |
| Bắt buộc chữ hoa | Có |
| Bắt buộc chữ thường | Có |
| Bắt buộc chữ số | Có |
| Bắt buộc ký tự đặc biệt | Có |
| Ký tự đặc biệt cho phép | `!@#$%^&*()_+-=[]{}|;:,.<>?` |

#### Mẫu Bị Chặn
- Mật khẩu phổ biến (password123, admin, v.v.)
- 4+ ký tự liên tiếp (abcd, 1234)
- 4+ ký tự lặp lại (aaaa, 1111)

#### API Endpoint
```bash
# Lấy chính sách
GET /api/v2/users/password-policy

# Kiểm tra độ mạnh (trả về điểm 0-100)
POST /api/v2/users/password-strength
{"password": "MyP@ssw0rd!"}
```

---

### 4. Giới hạn Tốc độ

Bảo vệ chống tấn công brute force và DoS.

#### Giới hạn Mặc định

| Mẫu Endpoint | Yêu cầu/phút | Burst |
|--------------|--------------|-------|
| `/api/v2/auth/login` | 10 | 3 |
| `/api/v2/auth/register` | 5 | 2 |
| `/api/v2/certificates/issue` | 30 | 5 |
| `/api/v2/cas` | 30 | 5 |
| `/api/v2/backup` | 5 | 2 |
| `/api/v2/users` | 60 | 10 |
| `/api/v2/certificates` | 120 | 20 |
| `/acme/`, `/scep/` | 300 | 50 |
| `/ocsp`, `/cdp/` | 500 | 100 |
| Mặc định | 120 | 20 |

#### Header Phản hồi
```
X-RateLimit-Limit: 120
X-RateLimit-Remaining: 115
X-RateLimit-Reset: 1706789123
```

#### Khi Bị Giới hạn (429)
```json
{
  "success": false,
  "error": "Rate limit exceeded",
  "retry_after": 45
}
```

#### Cấu hình
```bash
# Lấy cấu hình và thống kê
GET /api/v2/system/security/rate-limit

# Thêm IP vào danh sách trắng
PUT /api/v2/system/security/rate-limit
{"whitelist_add": ["192.168.1.100"]}

# Đặt lại bộ đếm cho IP
POST /api/v2/system/security/rate-limit/reset
{"ip": "192.168.1.50"}
```

---

### 5. Nhật ký Kiểm tra

Ghi log toàn diện tất cả hành động liên quan đến bảo mật.

#### Hành động Được Ghi log
- Xác thực (đăng nhập, đăng xuất, thất bại)
- Quản lý người dùng (tạo, cập nhật, xóa)
- Thao tác chứng chỉ (phát hành, thu hồi, xuất)
- Thao tác CA (tạo, xóa, ký)
- Thay đổi cài đặt
- Sự kiện bảo mật (bị giới hạn tốc độ, từ chối quyền)

#### Chính sách Lưu trữ
```bash
# Lấy cài đặt lưu trữ
GET /api/v2/system/audit/retention

# Cập nhật lưu trữ (ngày)
PUT /api/v2/system/audit/retention
{"retention_days": 365, "auto_cleanup": true}

# Dọn dẹp thủ công
POST /api/v2/system/audit/cleanup
{"retention_days": 90}
```

Mặc định: 90 ngày, tự động dọn dẹp hàng ngày lúc nửa đêm.

---

### 6. Cảnh báo Hết hạn Chứng chỉ

Thông báo email chủ động trước khi chứng chỉ hết hạn.

#### Lịch Cảnh báo
- 30 ngày trước khi hết hạn
- 14 ngày trước khi hết hạn
- 7 ngày trước khi hết hạn
- 1 ngày trước khi hết hạn

#### Cấu hình
```bash
# Lấy cài đặt
GET /api/v2/system/alerts/expiry

# Cập nhật cài đặt
PUT /api/v2/system/alerts/expiry
{
  "enabled": true,
  "alert_days": [30, 14, 7, 1],
  "recipients": ["admin@example.com"]
}

# Liệt kê chứng chỉ sắp hết hạn
GET /api/v2/system/alerts/expiring-certs?days=30

# Kiểm tra thủ công
POST /api/v2/system/alerts/expiry/check
```

Yêu cầu cấu hình SMTP tại Settings > Email.

---

## Thực hành Bảo mật Tốt nhất

### 1. Thiết lập Ban đầu
```bash
# 1. Đổi mật khẩu admin mặc định ngay lập tức
# 2. Tạo và đặt khóa mã hóa
# 3. Cấu hình HTTPS với chứng chỉ phù hợp
# 4. Đặt SECRET_KEY mạnh trong /etc/ucm/ucm.env
```

### 2. Biến Môi trường
```bash
# /etc/ucm/ucm.env
SECRET_KEY=<chuỗi-64-ký-tự-ngẫu-nhiên>
KEY_ENCRYPTION_KEY=<fernet-key>
FLASK_ENV=production
```

### 3. Bảo mật Mạng
- Chạy sau reverse proxy (nginx, Caddy)
- Bật tường lửa, hạn chế truy cập cổng 8443
- Dùng chứng chỉ TLS đúng (không dùng self-signed trong môi trường production)

### 4. Bảo mật Bản sao lưu
- Bản sao lưu được mã hóa bao gồm khóa mã hóa
- Lưu trữ bản sao lưu an toàn ngoài máy chủ
- Kiểm tra quy trình khôi phục thường xuyên

---

## Giám sát Bảo mật

### Dashboard Kiểm tra
Truy cập chỉ số bảo mật tại Settings > Audit Logs:
- Lần đăng nhập thất bại
- Yêu cầu bị giới hạn tốc độ
- Sự kiện từ chối quyền
- Thao tác chứng chỉ

### Task Theo lịch
| Task | Chu kỳ | Mô tả |
|------|--------|-------|
| `audit_log_cleanup` | Hàng ngày | Xóa nhật ký kiểm tra cũ |
| `cert_expiry_alerts` | Hàng ngày | Gửi thông báo hết hạn |
| `crl_auto_regen` | Hàng giờ | Tái tạo CRL sắp hết hạn |

---

## Báo cáo Lỗ hổng Bảo mật

Nếu bạn phát hiện lỗ hổng bảo mật, vui lòng báo cáo một cách có trách nhiệm:

1. **KHÔNG** tạo issue công khai trên GitHub
2. Mở [GitHub Security Advisory](https://github.com/NeySlim/ultimate-ca-manager/security/advisories)
3. Bao gồm: mô tả, các bước tái hiện, đánh giá mức độ ảnh hưởng
4. Cho phép 90 ngày để sửa trước khi công bố công khai

---

## Nhật ký Thay đổi Bảo mật

| Phiên bản | Ngày | Thay đổi |
|-----------|------|----------|
| 2.1.0 | 2026-02-19 | SSO (LDAP/OAuth2/SAML) với giới hạn tốc độ, sửa lỗi injection bộ lọc LDAP, CSRF trên endpoint SSO, RBAC 4 vai trò (admin/operator/auditor/viewer), 28 test bảo mật SSO |
| 2.0.2 | 2026-01-31 | Mã hóa khóa riêng tư, CSRF, chính sách mật khẩu, giới hạn tốc độ |
| 2.0.0 | 2026-01-29 | Khung bảo mật ban đầu, xác thực session, RBAC |
