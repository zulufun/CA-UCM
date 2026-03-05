# Hướng dẫn Người dùng UCM

Hướng dẫn bắt đầu nhanh để sử dụng Ultimate CA Manager.

---

## Bắt đầu

### Đăng nhập Lần đầu

1. Truy cập `https://your-server:8443`
2. Đăng nhập với thông tin mặc định: `admin` / `changeme123`
3. **Quan trọng:** Đổi mật khẩu ngay trong phần cài đặt Tài khoản

### Điều hướng

UCM sử dụng bố cục 3 cột:
- **Sidebar** (bên trái, 52px) -- Icon điều hướng chính
- **Explorer** -- Danh sách các mục của trang hiện tại
- **Chi tiết** (flex) -- Chi tiết và hành động của mục được chọn

### Phím tắt

| Phím tắt | Hành động |
|----------|-----------|
| `Cmd/Ctrl + K` | Mở Command Palette |
| `Escape` | Đóng modal/menu |

---

## Quản lý Chứng chỉ

### Tạo Chứng chỉ

1. Vào trang **Certificates**
2. Nhấp nút **+ New Certificate**
3. Điền vào biểu mẫu:
   - **Common Name** - Định danh chính (ví dụ: `www.example.com`)
   - **Subject Alternative Names** - Domain/IP bổ sung
   - **Issuing CA** - Chọn CA cha
   - **Template** - Dùng cài sẵn hoặc tùy chỉnh
   - **Validity** - Thời hạn hiệu lực chứng chỉ
4. Nhấp **Create**

### Xuất Chứng chỉ

1. Chọn một chứng chỉ trong bảng
2. Trong panel chi tiết, nhấp **Export**
3. Chọn định dạng:
   - **PEM** - Định dạng chuẩn (chứng chỉ + khóa)
   - **PKCS12** - Gói tương thích Windows/Java
   - **DER** - Định dạng nhị phân
4. Đặt mật khẩu (cho PKCS12)
5. Tải xuống hoặc sao chép vào clipboard

### Thu hồi Chứng chỉ

1. Chọn chứng chỉ
2. Nhấp **Revoke** trong panel chi tiết
3. Chọn lý do thu hồi
4. Xác nhận hành động
5. Chứng chỉ tự động được thêm vào CRL

---

## Quản lý CA

### Tạo Root CA

1. Vào trang **Certificate Authorities**
2. Nhấp **+ New CA**
3. Chọn loại **Root CA**
4. Cấu hình:
   - **Common Name** - Định danh CA
   - **Organization** - Tên tổ chức của bạn
   - **Key Type** - Khuyến nghị RSA 4096 hoặc ECDSA P-384
   - **Validity** - Thường từ 10-20 năm cho Root
5. Nhấp **Create**

### Tạo Intermediate CA

1. Vào trang **Certificate Authorities**
2. Nhấp **+ New CA**
3. Chọn loại **Intermediate CA**
4. Chọn **Parent CA** từ danh sách Root CA của bạn
5. Cấu hình các cài đặt (thường 5-10 năm hiệu lực)
6. Nhấp **Create**

### Chế độ xem Phân cấp CA

- Chuyển đổi giữa chế độ **Grid** và **Tree** bằng bộ chuyển đổi view
- Chế độ Tree hiển thị quan hệ cha-con
- Nhấp vào bất kỳ CA nào để xem chi tiết và chứng chỉ đã phát hành

---

## Quản lý CSR

### Ký CSR

1. Vào trang **CSRs**
2. Tải lên file CSR hoặc dán nội dung PEM
3. Chọn trong danh sách
4. Nhấp **Sign**
5. Chọn:
   - **Issuing CA** - CA nào sẽ ký
   - **Template** - Cấu hình chứng chỉ
   - **Validity** - Ghi đè mặc định của template
6. Nhấp **Sign CSR**
7. Tải xuống hoặc sao chép chứng chỉ đã ký

---

## Template

Template xác định cài đặt mặc định cho chứng chỉ.

### Tạo Template

1. Vào trang **Templates**
2. Nhấp **+ New Template**
3. Cấu hình:
   - **Name** - Tên mô tả
   - **Key Usage** - Digital Signature, Key Encipherment, v.v.
   - **Extended Key Usage** - Server Auth, Client Auth, v.v.
   - **Default Validity** - Ngày/tháng/năm
   - **Subject Constraints** - Trường bắt buộc/cho phép
4. Nhấp **Save**

### Template Tích hợp sẵn

| Template | Trường hợp sử dụng |
|----------|--------------------|
| Web Server | Chứng chỉ HTTPS |
| Client Auth | Chứng chỉ người dùng |
| Code Signing | Ký phần mềm |
| Email (S/MIME) | Mã hóa email |

---

## Quản lý Người dùng

### Tạo Người dùng

1. Vào trang **Users** (yêu cầu quyền admin)
2. Nhấp **+ New User**
3. Điền vào:
   - **Username** - Tên đăng nhập
   - **Email** - Dùng cho thông báo
   - **Role** - Admin, Operator, Auditor, hoặc Viewer
   - **Temporary Password** - Người dùng sẽ đổi ở lần đăng nhập đầu tiên
4. Nhấp **Create**

### Vai trò & Quyền hạn

| Vai trò | Quyền hạn |
|---------|-----------|
| **Admin** | Toàn quyền, quản lý người dùng, cài đặt |
| **Operator** | Tạo/quản lý chứng chỉ, CA, CSR, giao thức |
| **Auditor** | Chỉ đọc toàn bộ tài nguyên (ngoại trừ người dùng/cài đặt) |
| **Viewer** | Chỉ đọc chứng chỉ, CA, CSR, template, trust store |

---

## Đăng nhập Một lần (SSO)

UCM hỗ trợ các nhà cung cấp danh tính bên ngoài để xác thực:

- **LDAP / Active Directory** — Xác thực bằng bind với ánh xạ nhóm sang vai trò
- **OAuth2** — Google, GitHub, Azure AD, hoặc bất kỳ nhà cung cấp OpenID Connect nào
- **SAML 2.0** — Nhà cung cấp danh tính doanh nghiệp (Okta, Azure AD, ADFS)

Cấu hình SSO tại **Settings** → tab **SSO** (chỉ admin). Mỗi loại nhà cung cấp hỗ trợ ánh xạ vai trò tự động dựa trên thành viên nhóm.

---

## Cài đặt Bảo mật

### Bật 2FA (TOTP)

1. Vào **Account** → tab **Security**
2. Nhấp **Enable 2FA**
3. Quét mã QR bằng ứng dụng xác thực
4. Nhập mã xác minh
5. Lưu mã dự phòng ở nơi an toàn

### Thêm Khóa WebAuthn

1. Vào **Account** → tab **Security**
2. Nhấp **Add Security Key**
3. Cắm và chạm vào khóa phần cứng của bạn
4. Đặt tên cho khóa để nhận biết

---

## Cấu hình Giao thức

### ACME Server

Bật phát hành chứng chỉ tương thích Let's Encrypt:

1. Vào **Settings** → tab **ACME**
2. Bật ACME server
3. Cấu hình:
   - **Base URL** - URL công khai để xử lý challenge
   - **Default CA** - CA cho các chứng chỉ được phát hành
   - **Allowed Domains** - Giới hạn phát hành
4. Client sử dụng: `https://your-server:8443/acme/directory`

### SCEP Server

Bật tự động đăng ký thiết bị:

1. Vào **Settings** → tab **SCEP**
2. Bật SCEP server
3. Cấu hình:
   - **Challenge Password** - Mật khẩu bí mật đăng ký
   - **CA for Signing** - CA phát hành
   - **Certificate Template** - Cấu hình mặc định
4. Thiết bị sử dụng: `https://your-server:8443/scep`

### OCSP Responder

Xác thực chứng chỉ theo thời gian thực:

1. OCSP được bật tự động
2. URL: `https://your-server:8443/ocsp`
3. Cấu hình trong cài đặt CA cho các extension CDP/AIA

---

## Giao diện Theme

Thay đổi theme giao diện:

1. Nhấp vào **avatar người dùng** (dưới cùng sidebar) để mở menu người dùng
2. Chọn submenu **Theme**
3. Chọn từ 3 bảng màu, mỗi bảng có biến thể Sáng và Tối:
   - Gray (mặc định)
   - Purple Night
   - Orange Sunset
4. Hoặc chọn **Follow System** để khớp với tùy chọn sáng/tối của hệ điều hành

Theme được lưu qua các session.

---

## Sử dụng trên Mobile

UCM tương thích với thiết bị di động:

- **Bottom Sheet** - Nhấp vào thanh peek để xem danh sách explorer
- **Vuốt** - Kéo để thay đổi kích thước explorer
- **Nhấp để Chọn** - Chạm vào mục để xem chi tiết
- **Tự động Đóng** - Sheet đóng khi chọn mục

---

## Xử lý Sự cố

### Không Đăng nhập được

1. Kiểm tra username/mật khẩu
2. Xóa cache trình duyệt
3. Thử chế độ ẩn danh
4. Kiểm tra nhật ký máy chủ: `journalctl -u ucm -f`

### Tạo Chứng chỉ Thất bại

1. Xác minh CA có khóa riêng tư hợp lệ
2. Kiểm tra thời hạn hiệu lực CA
3. Xem lại thông báo lỗi trong phần thông báo

### SCEP/ACME Không Hoạt động

1. Xác minh dịch vụ đã được bật trong Settings
2. Kiểm tra firewall cho phép cổng 8443
3. Xác minh cấu hình DNS/hostname
4. Kiểm tra bằng `curl https://server:8443/scep`

---

## Tài nguyên Thêm

- [Tài liệu tham khảo API](API_REFERENCE.md)
- [Hướng dẫn Cài đặt](installation/README.md)
- [Hướng dẫn Docker](installation/docker.md)
- [Nhật ký thay đổi](../CHANGELOG.md)
