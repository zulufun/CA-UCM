# Tính năng Nâng cao của UCM

Tất cả tính năng đều được tích hợp vào UCM như chức năng cốt lõi. Không có phiên bản "Pro" hay "Community" riêng biệt — tất cả đều được đóng gói trong một codebase thống nhất dưới `api/v2/`.

## Tổng quan Tính năng

| Tính năng | Trạng thái | Module Backend |
|-----------|------------|----------------|
| Quản lý Chứng chỉ | Ổn định | `api/v2/certificates.py` |
| Nhiều CA | Ổn định | `api/v2/cas.py` |
| Giao thức ACME | Ổn định | `api/v2/acme.py` |
| Giao thức SCEP | Ổn định | `api/v2/scep.py` |
| Nhóm Người dùng | Ổn định | `api/v2/groups.py` |
| Vai trò RBAC Tùy chỉnh | Ổn định | `api/v2/rbac.py` |
| SSO (LDAP/OAuth2/SAML) | Thử nghiệm | `api/v2/sso.py` |
| Tích hợp HSM | Thử nghiệm | `api/v2/hsm.py` |
| Xác thực mTLS | Thử nghiệm | `api/v2/mtls.py` |
| WebAuthn/FIDO2 | Ổn định | `api/v2/webauthn.py` |
| 2FA TOTP | Ổn định | `api/v2/account.py` |
| Chính sách Chứng chỉ | Thử nghiệm | `api/v2/policies.py` |
| Webhooks | Ổn định | `api/v2/webhooks.py` |
| Trust Store | Ổn định | `api/v2/truststore.py` |
| Nhật ký Kiểm tra Nâng cao | Ổn định | `api/v2/audit.py` |
| Tự cập nhật (ucm-watcher) | Ổn định | `services/updates.py` |

> Các tính năng đánh dấu **Thử nghiệm** đã hoạt động nhưng có thể chưa được kiểm tra đầy đủ. Chúng hiển thị huy hiệu "Experimental" trong giao diện.

---

## Nhóm Người dùng

Tổ chức người dùng thành các nhóm với quyền hạn được chia sẻ.

### Tính năng
- Tạo không giới hạn số lượng nhóm
- Gán nhiều người dùng vào mỗi nhóm
- Xác định quyền hạn ở cấp độ nhóm
- Kế thừa vai trò từ thành viên nhóm

### Nhóm Mặc định
- **Administrators** - Toàn quyền hệ thống
- **Certificate Operators** - Quản lý chứng chỉ và CSR
- **Auditors** - Quyền đọc nhật ký kiểm tra

### API Endpoint
```
GET /api/v2/groups - Liệt kê nhóm
POST /api/v2/groups - Tạo nhóm
GET /api/v2/groups/:id - Lấy chi tiết nhóm
PUT /api/v2/groups/:id - Cập nhật nhóm
DELETE /api/v2/groups/:id - Xóa nhóm
POST /api/v2/groups/:id/members - Thêm thành viên
DELETE /api/v2/groups/:id/members/:uid - Xóa thành viên
```

---

## Vai trò RBAC Tùy chỉnh

Xác định quyền hạn chi tiết vượt ra ngoài các vai trò tích hợp sẵn.

### Tính năng
- Tạo vai trò tùy chỉnh với quyền hạn cụ thể
- Kế thừa từ vai trò cơ bản (admin, operator, auditor, viewer)
- Kiểm soát quyền hạn chi tiết theo từng loại tài nguyên
- Phân cấp vai trò với kế thừa quyền hạn

### Danh mục Quyền hạn
- Chứng chỉ: đọc, ghi, xóa, thu hồi, gia hạn
- CA: đọc, ghi, xóa, ký
- CSR: đọc, ghi, xóa, ký
- Người dùng: đọc, ghi, xóa
- Cài đặt: đọc, ghi
- Kiểm tra: đọc
- HSM: đọc, ghi, xóa
- SSO: đọc, ghi, xóa

### API Endpoint
```
GET /api/v2/rbac/roles - Liệt kê vai trò tùy chỉnh
POST /api/v2/rbac/roles - Tạo vai trò
GET /api/v2/rbac/roles/:id - Lấy chi tiết vai trò
PUT /api/v2/rbac/roles/:id - Cập nhật vai trò
DELETE /api/v2/rbac/roles/:id - Xóa vai trò
GET /api/v2/rbac/permissions - Liệt kê tất cả quyền hạn
```

---

## Tích hợp SSO

Đăng nhập một lần với các nhà cung cấp danh tính doanh nghiệp.

### Nhà cung cấp Được Hỗ trợ
- **LDAP/Active Directory** - Xác thực bind với đồng bộ nhóm
- **OAuth2/OIDC** - OpenID Connect với các nhà cung cấp lớn
- **SAML 2.0** - Liên kết SAML doanh nghiệp

### Tính năng
- Tự động tạo người dùng khi đăng nhập SSO lần đầu
- Tự động cập nhật thông tin người dùng ở mỗi lần đăng nhập
- Ánh xạ nhóm SSO sang vai trò UCM
- Nhiều nhà cung cấp cùng lúc
- Kiểm tra kết nối trước khi bật

### Cấu hình LDAP
```json
{
  "provider_type": "ldap",
  "ldap_server": "ldap.example.com",
  "ldap_port": 389,
  "ldap_use_ssl": true,
  "ldap_base_dn": "dc=example,dc=com",
  "ldap_bind_dn": "cn=admin,dc=example,dc=com",
  "ldap_user_filter": "(uid={username})"
}
```

### Cấu hình OAuth2
```json
{
  "provider_type": "oauth2",
  "oauth2_client_id": "ucm-client",
  "oauth2_auth_url": "https://idp.example.com/oauth/authorize",
  "oauth2_token_url": "https://idp.example.com/oauth/token",
  "oauth2_userinfo_url": "https://idp.example.com/oauth/userinfo",
  "oauth2_scopes": ["openid", "profile", "email"]
}
```

### API Endpoint
```
GET /api/v2/sso/providers - Liệt kê nhà cung cấp
POST /api/v2/sso/providers - Tạo nhà cung cấp
PUT /api/v2/sso/providers/:id - Cập nhật nhà cung cấp
DELETE /api/v2/sso/providers/:id - Xóa nhà cung cấp
POST /api/v2/sso/providers/:id/test - Kiểm tra kết nối
POST /api/v2/sso/providers/:id/toggle - Bật/tắt
GET /api/v2/sso/available - Công khai: nhà cung cấp có sẵn để đăng nhập
```

---

## Tích hợp HSM

Hỗ trợ Hardware Security Module để lưu trữ khóa an toàn.

### Loại HSM Được Hỗ trợ
- **PKCS#11** - HSM cục bộ (SafeNet, Thales, SoftHSM)
- **AWS CloudHSM** - Cụm HSM được quản lý bởi AWS
- **Azure Key Vault** - Lưu trữ khóa được quản lý bởi Azure
- **Google Cloud KMS** - Quản lý khóa trên Google Cloud

### Tính năng
- Lưu trữ khóa riêng tư CA trong HSM
- Tạo khóa trực tiếp trong HSM
- Theo dõi sử dụng khóa và kiểm tra
- Giám sát sức khỏe kết nối
- Nhiều nhà cung cấp HSM

### Cấu hình PKCS#11
```json
{
  "provider_type": "pkcs11",
  "pkcs11_library_path": "/usr/lib/softhsm/libsofthsm2.so",
  "pkcs11_slot_id": 0,
  "pkcs11_token_label": "UCM Token"
}
```

### Loại Khóa
- RSA (2048, 3072, 4096 bit)
- ECDSA (P-256, P-384, P-521)
- AES (128, 256 bit) để mã hóa

### API Endpoint
```
GET /api/v2/hsm/providers - Liệt kê nhà cung cấp HSM
POST /api/v2/hsm/providers - Tạo nhà cung cấp
PUT /api/v2/hsm/providers/:id - Cập nhật nhà cung cấp
DELETE /api/v2/hsm/providers/:id - Xóa nhà cung cấp
POST /api/v2/hsm/providers/:id/test - Kiểm tra kết nối
GET /api/v2/hsm/keys - Liệt kê tất cả khóa
POST /api/v2/hsm/providers/:id/keys - Tạo khóa
DELETE /api/v2/hsm/keys/:id - Hủy khóa
GET /api/v2/hsm/stats - Thống kê HSM
```

---

## Hỗ trợ

- Tài liệu: https://github.com/NeySlim/ultimate-ca-manager/wiki
- Thảo luận: https://github.com/NeySlim/ultimate-ca-manager/discussions
- Vấn đề: https://github.com/NeySlim/ultimate-ca-manager/issues
