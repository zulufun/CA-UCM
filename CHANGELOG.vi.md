# Nhật ký thay đổi

Tất cả các thay đổi đáng chú ý của Ultimate CA Manager sẽ được ghi lại trong tệp này.

Định dạng dựa trên [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Từ phiên bản v2.48 trở đi, UCM sử dụng định dạng phiên bản Major.Build (ví dụ: 2.48, 2.49). Các bản phát hành trước đó sử dụng Semantic Versioning.

---

## [Chưa phát hành]

---

## [2.51] - 2026-02-28

### Thêm mới
- **Trang quản lý EST** — giao diện cấu hình EST đầy đủ (RFC 7030) với các tab cấu hình, thống kê và thông tin endpoint; API quản lý backend (`/api/v2/est/config`, `/stats`)
- **Bỏ tạm giữ chứng chỉ** — endpoint `POST /certificates/<id>/unhold` để xóa trạng thái certificateHold; nút bấm trong panel chi tiết frontend kèm hộp thoại xác nhận
- **Trạng thái hệ thống mở rộng** — dashboard hiện hiển thị 8 huy hiệu dịch vụ: ACME, SCEP, EST, OCSP, CRL, Tự động gia hạn (kèm số lượng đang chờ), SMTP, Webhooks
- **Cập nhật thời gian thực qua WebSocket** — kết nối tất cả emitter backend (CRUD chứng chỉ, CA, người dùng, cài đặt, kiểm tra) để đẩy cập nhật trực tiếp lên dashboard và bảng dữ liệu
- **Thanh điều hướng sidebar dạng accordion** — nhóm phần có thể thu gọn với hiệu ứng mượt mà, kiểu dáng tinh tế (rộng 200px), drawer dạng bottom sheet trên mobile
- **Cập nhật Help trong ứng dụng** — tài liệu dành cho EST, bỏ tạm giữ chứng chỉ, tạo CSR, trạng thái hệ thống mở rộng
- **Form tạo CSR** — tạo CSR trực tiếp từ giao diện với đầy đủ trường DN và tùy chọn khóa
- **Form cấp chứng chỉ nâng cao** — đầy đủ tùy chọn bao gồm key usage, extended key usage, SAN và thời hạn hiệu lực

### Thay đổi
- **Chuẩn hóa mật độ giao diện toàn cục** — thống nhất tỷ lệ thành phần (~34px chiều cao): Input, Select, Textarea, SearchBar, Button đều được căn chỉnh; padding Card thu gọn; hàng bảng được siết lại (font 13px, padding giảm); khung icon 28→24px trong bảng
- **Sidebar cài đặt** — đồng bộ với nav chính (200px, chữ 13px, thanh accent cho trạng thái active)
- **Đường cong biểu đồ Dashboard** — chuyển từ nội suy monotone sang basis (B-spline) để đường cong mượt hơn
- **Điều hướng Sidebar** — flyout dạng mega-menu theo hover, sau đó tinh chỉnh thành accordion với trạng thái mở/đóng bền vững

### Sửa lỗi
- **Crash OCSP do cert null** — dùng `add_response_by_hash` khi dữ liệu `.crt` của chứng chỉ bị thiếu thay vì crash
- **Ký OCSP bằng HSM** — thêm `_HsmPrivateKeyWrapper` để ủy quyền ký OCSP response cho các nhà cung cấp HSM
- **Số chứng chỉ hết hạn trên Dashboard** — backend giờ trả về đúng số chứng chỉ đã hết hạn; `expiring_soon` loại trừ chứng chỉ đã hết hạn
- **Khoảng cách widget System Health** — sửa padding giữa header và nội dung (desktop + mobile)
- **Flyout menu chồng chéo** — ngăn menu hiển thị đè lên nhau khi hover nhanh bằng debounce
- **Trải nghiệm sau cài đặt** — cải thiện script post-install DEB/RPM với các lựa chọn FQDN và URL API chính xác
- **Dọn dẹp file thừa** — xóa các file lỗi thời và các component không dùng

---

## [2.50] - 2026-02-22

### Thêm mới
- **Thiết kế lại kiến trúc đăng nhập** — viết lại hoàn toàn luồng xác thực với state machine (init → username → auth → 2fa/ldap), tự động phát hiện phương thức, và đăng nhập tự động mTLS không cần tương tác
- **Đăng nhập tự động mTLS** — xác thực chứng chỉ client diễn ra hoàn toàn trong TLS handshake qua middleware; không cần POST thủ công, cert trình duyệt → session → tự chuyển hướng đến dashboard
- **Kiểm tra session AuthContext trên tất cả route** — bỏ guard bỏ qua `/login`; `checkSession()` hiện luôn gọi `/auth/verify` khi mount, cho phép phát hiện đăng nhập tự động mTLS
- **Trạng thái `sessionChecked`** — boolean mới trong AuthContext được expose cho các component, ngăn flash form đăng nhập trong khi xác minh session
- **Endpoint `/auth/methods` nâng cao** — trả về `mtls_status` (auto_logged_in/present_not_enrolled/not_present), `mtls_user`, và `sso_providers` trong một lần gọi

### Thay đổi
- **Middleware mTLS** — viết lại sạch với helper `_extract_certificate()` (DRY), `g.mtls_cert_info` để tái sử dụng qua các endpoint, xử lý session cũ đúng cách
- **LoginPage** — xóa logic đăng nhập cascade; mỗi phương thức xác thực độc lập với chuyển đổi trạng thái riêng; WebAuthn tự động hiện prompt sau khi nhập username nếu phát hiện khóa
- **Route `/login` trong App.jsx** — hiển thị `PageLoader` khi đang kiểm tra session, sau đó chuyển hướng nếu đã xác thực

### Sửa lỗi
- **Injection peercert mTLS** — custom Gunicorn worker (`MTLSWebSocketHandler`) trích xuất bytes DER của peercert vào WSGI environ
- **Tên CA OpenSSL 3.x** — hack ctypes trong `gunicorn_config.py` để gửi tên CA client trong CertificateRequest
- **So sánh datetime có múi giờ** — sửa crash trong `mtls_auth_service.py` khi so sánh datetime naive vs aware
- **Không khớp định dạng số serial** — chuẩn hóa so khớp serial hex/decimal trong `mtls_auth_service.py`
- **Lỗi SSL của Scheduler khi khởi động** — thêm khoảng chờ 30 giây trước khi thực thi task theo lịch đầu tiên
- **Session cũ chặn mTLS** — middleware giờ xác thực session hiện tại trước khi bỏ qua xử lý chứng chỉ
- **`checkSession()` dương tính giả** — giờ kiểm tra đúng `userData.authenticated` trước khi đặt `isAuthenticated=true`

---

## [2.49] - 2026-02-22

### Sửa lỗi
- **Endpoint đăng nhập mTLS** — `login_mtls()` thiếu decorator `@bp.route`, gây ra 404 khi đăng nhập bằng chứng chỉ client
- **Tạo tài khoản ACME** — thêm route `POST /acme/accounts` còn thiếu; nút "Tạo Tài Khoản" trả về 404
- **Vô hiệu hóa tài khoản ACME** — thêm route `POST /acme/accounts/<id>/deactivate` còn thiếu
- **Tạo CRL** — `crlService.generate()` giờ gọi đúng endpoint backend `/crl/<caId>/regenerate`

### Thay đổi
- **CHANGELOG** — viết lại hoàn toàn với các mục chính xác cho tất cả phiên bản từ 2.1.1 đến 2.48 (trích xuất từ git log)

---

## [2.48] - 2026-02-22

> Nhảy phiên bản từ 2.1.6 lên 2.48: UCM chuyển từ Semantic Versioning sang định dạng Major.Build.

### Thêm mới
- **Bộ test backend toàn diện** — 1364 test bao phủ tất cả 347 API route (~95% độ phủ route)
- **Quản lý chứng chỉ client mTLS** — vòng đời đầy đủ (liệt kê, xuất, thu hồi, xóa) qua API `/api/v2/user-certificates` (6 endpoint), trang User Certificates, modal đăng ký mTLS, xuất PKCS12, cấu hình mTLS Gunicorn động, quản lý mTLS từng người dùng của admin
- **Luồng đăng nhập 2FA TOTP** — xác thực hai yếu tố đầy đủ với thiết lập QR code và xác minh khi đăng nhập
- **Huy hiệu thử nghiệm** — chỉ báo trực quan cho các tính năng chưa được kiểm tra (mTLS, HSM, SSO) trong trang Settings và Account
- **Hệ thống ucm-watcher** — quản lý dịch vụ dựa trên systemd path thay thế các lệnh systemctl trực tiếp; xử lý yêu cầu khởi động lại và cập nhật gói thông qua signal file
- **Cơ chế tự cập nhật** — backend kiểm tra GitHub releases API, tải gói, kích hoạt ucm-watcher để cài đặt
- **Kiểm tra pre-commit** — đồng bộ i18n, test frontend (450), test backend (1364), kiểm tra icon — tất cả chạy trước mỗi commit

### Thay đổi
- **Sơ đồ phiên bản** — chuyển từ Semantic Versioning (2.1.x) sang Major.Build (2.48) để theo dõi phát hành đơn giản hơn
- **Một file VERSION duy nhất** — xóa bản sao `backend/VERSION`; file `VERSION` ở root repo là nguồn dữ liệu duy nhất
- **Khởi động lại dịch vụ** — tập trung hóa qua signal file (`/opt/ucm/data/.restart_requested`) thay vì gọi systemctl trực tiếp
- **Đổi tên nhánh** — nhánh phát triển đổi tên từ `2.1.0-dev`/`2.2.0-dev` thành `dev`
- **Đóng gói RPM** — các unit systemd đổi tên từ `ucm-updater` thành `ucm-watcher` để đồng nhất với DEB
- **Tiện ích `buildQueryString` tập trung** — tất cả 10 frontend service giờ dùng `buildQueryString()` từ `apiClient.js`
- **Xóa opacity Tailwind** — thay thế pattern `bg-x/40` bằng tiện ích CSS `color-mix`

### Sửa lỗi
- **Lỗi build RPM** — spec tham chiếu đến file không tồn tại `ucm-updater.path`/`ucm-updater.service`
- **Ngày trong changelog RPM** — sửa tên ngày trong tuần sai gây cảnh báo ngày không hợp lệ
- **Độ sâu cây CA** — kết xuất đệ quy cho phân cấp không giới hạn độ sâu
- **Phân tích cú pháp DN** — hỗ trợ cả định dạng ngắn (`CN=`) và dài (`commonName=`)
- **Modal đổi mật khẩu** — nút đóng (X) giờ đóng đúng modal
- **Endpoint bật 2FA** — sửa lỗi 500 trên `/api/v2/account/2fa/enable`
- **Xuất PEM** — dùng ký tự xuống dòng thực trong ghép nối PEM
- **Xử lý blob xuất** — các trang giờ xử lý đúng giá trị trả về của `apiClient` (dữ liệu trực tiếp, không phải wrapper `{ data }`)
- **Bug params trong `groups.service.js`** — đang truyền `{ params }` vào `apiClient.get()` khiến query parameter bị bỏ qua

### Bảo mật
- **1364 test bảo mật backend** — tất cả endpoint xác thực, ủy quyền và RBAC được kiểm tra
- **Xác minh rate limiting** — xác nhận bảo vệ brute-force trên tất cả endpoint xác thực qua test
- **Thực thi CSRF** — tất cả endpoint thay đổi trạng thái được xác minh yêu cầu CSRF token

---

## [2.1.6] - 2026-02-21

Bản phát hành dọn dẹp phiên bản — không có thay đổi code.

---

## [2.1.5] - 2026-02-21

### Sửa lỗi
- **Phân tích cú pháp SAN** — phân tích chuỗi SAN thành mảng có kiểu (DNS, IP, Email, URI) để hiển thị và chỉnh sửa đúng

---

## [2.1.4] - 2026-02-21

### Sửa lỗi
- **Mật khẩu khóa được mã hóa** — trường mật khẩu giờ được hiển thị trong SmartImport cho khóa riêng tư được mã hóa
- **i18n điều hướng mobile** — dùng key dịch ngắn cho các mục nav trên mobile
- **Icon mobile bị thiếu** — thêm các icon Gavel, Stamp, ChartBar vào AppShell mobile nav

---

## [2.1.3] - 2026-02-21

### Sửa lỗi
- **Kích thước khóa ECDSA** — tùy chọn kích thước khóa đúng (256, 384, 521) và ánh xạ backend (sửa #22)

---

## [2.1.2] - 2026-02-21

### Sửa lỗi
- **Tạo Sub CA** — sửa CA cha bị bỏ qua + mất trường DN + rò rỉ chi tiết lỗi + crash khi import

### Bảo mật
- **Flask 3.1.2 → 3.1.3** — CVE-2026-27205

---

## [2.1.1] - 2026-02-20

### Sửa lỗi
- **Đồng bộ phiên bản DB** — `app.version` trong database giờ được đồng bộ từ file VERSION khi khởi động
- **Import OPNsense** — sửa JSON.stringify kép trên API client POST, thêm kiểm tra kiểu cho trường JSON lồng nhau
- **Trạng thái DNS provider** — sửa kwarg `status` trong các endpoint DNS provider
- **Screenshots** — thay thế bằng screenshots đúng giao diện dark theme 1920×1080

### Thay đổi
- Hợp nhất changelog — gộp tất cả mục pre-release 2.1.0 thành một mục duy nhất
- CI: loại trừ tag `rc` khỏi Docker tag `latest`
- CI: tự động đẩy DOCKERHUB_README.md lên Docker Hub khi phát hành

---

## [2.1.0] - 2026-02-19

### Thêm mới
- **Xác thực SSO** — LDAP/Active Directory, OAuth2 (Google, GitHub, Azure AD), SAML 2.0 với ánh xạ nhóm sang vai trò
- **Module Quản trị** — chính sách chứng chỉ, quy trình phê duyệt, báo cáo theo lịch
- **Vai trò Auditor** — vai trò hệ thống mới với quyền đọc toàn bộ dữ liệu vận hành ngoại trừ cài đặt và quản lý người dùng
- **RBAC 4 vai trò** — Administrator, Operator, Auditor, Viewer với quyền chi tiết + vai trò tùy chỉnh
- **DNS provider ACME** — 48 nhà cung cấp với giao diện lưới thẻ và logo SVG chính thức
- **Cửa sổ chi tiết nổi** — nhấp vào bất kỳ hàng bảng nào để mở panel chi tiết có thể kéo, thay đổi kích thước với các hành động (xuất, gia hạn, thu hồi, xóa)
- **Trình chỉnh sửa template email** — khung chia đôi với mã nguồn HTML + xem trước trực tiếp và 6 biến template
- **Cảnh báo hết hạn chứng chỉ** — ngưỡng cấu hình được, người nhận, nút kiểm tra ngay
- **Tích hợp SoftHSM** — thiết lập SoftHSM2 tự động cho DEB, RPM và Docker với tạo khóa PKCS#11
- **Khớp chuỗi AKI/SKI** — quan hệ chuỗi theo mật mã thay vì khớp DN dễ gãy
- **Scheduler sửa chuỗi** — task nền hàng giờ để điền ngược SKI/AKI, kết nối lại orphan, loại bỏ trùng lặp CA
- **Backup v2.0** — backup/restore đầy đủ tất cả bảng database (trước đây chỉ 5, giờ bao gồm groups, RBAC, templates, trust store, SSO, HSM, API key, SMTP, policies, v.v.)
- **Tái tạo file** — dịch vụ khởi động tái tạo các file chứng chỉ/khóa bị thiếu từ database
- **Tên file dễ đọc** — `{cn-slug}-{refid}.ext` thay vì chỉ UUID
- **Biểu đồ Dashboard** — bộ chọn ngày, chuỗi hết hạn, truy vấn được tối ưu, biểu đồ donut với gradient
- **Giao diện cài đặt SSO** — các section có thể thu gọn, kiểm tra kết nối/ánh xạ LDAP, preset nhà cung cấp OAuth2, tự động tải metadata SAML
- **Nút SSO trên trang đăng nhập** — các nút xác thực SSO trước form đăng nhập nội bộ
- **Lưu phương thức đăng nhập** — ghi nhớ username + phương thức xác thực qua các session
- **Linter ESLint + Ruff** — phát hiện stale closure, biến không xác định, vi phạm hook, lỗi import
- **Bộ chọn chứng chỉ SP cho SAML** — chọn chứng chỉ nào đưa vào metadata SP
- **Preset danh bạ LDAP** — template OpenLDAP, Active Directory, Custom
- **Nhân đôi template** — endpoint clone: POST /templates/{id}/duplicate
- **Hành động xuất thống nhất** — component ExportActions tái sử dụng được với trường mật khẩu P12 inline
- **Xác thực chuỗi trust store** — trạng thái chuỗi trực quan kèm bundle xuất
- **Kết nối lại dịch vụ** — đếm ngược 30 giây với kiểm tra sẵn sàng health + WebSocket
- **Thông tin phiên bản trong Settings** — phiên bản, thông tin hệ thống, uptime, bộ nhớ, liên kết đến tài liệu
- **Webhooks** — tab quản lý trong Settings cho CRUD webhook, kiểm tra và lọc sự kiện
- **Component Select có tìm kiếm**
- **i18n đầy đủ** — hơn 2273 key cho tất cả 9 ngôn ngữ (EN, FR, DE, ES, IT, PT, UK, ZH, JA)

### Thay đổi
- Đổi tên vai trò RBAC hệ thống "User" → "Viewer" với quyền hạn chế
- Đơn giản hóa theme thành 3 nhóm: Gray, Purple Night, Orange Sunset (× Light/Dark)
- Hợp nhất API route — xóa module `features/`; tất cả route dưới `api/v2/`
- Không còn phân biệt Pro/Community — tất cả tính năng đều là core
- Layer dịch vụ SSO tách ra thành `sso.service.js`
- Bảng dùng kích thước cột tỷ lệ, hành động chuyển sang cửa sổ chi tiết
- Navbar mobile với dropdown người dùng, lưới nav 5 cột gọn
- WebSocket/CORS tự phát hiện hostname ngắn và port động
- Mật khẩu mặc định luôn là `changeme123` (không ngẫu nhiên)
- Xóa gcc/build-essential không cần thiết khỏi dependencies DEB/RPM

### Sửa lỗi
- **Bộ lọc nhóm LDAP bị lỗi** khi DN người dùng chứa ký tự đặc biệt (`escape_filter_chars`)
- **17 bug tìm thấy bởi linter** — biến không xác định, import thiếu, conditional hook trong 6 file
- **CSRF token không được lưu** khi đăng nhập đa phương thức — gây ra 403 trên POST/PUT/DELETE
- **Select dropdown ẩn sau modal** — sửa z-index Radix portal
- **Metadata SP SAML không hợp lệ schema** — giờ dùng builder python3-saml
- **Từ chối CORS origin** làm hỏng WebSocket trên Docker và cài đặt mới
- **Biểu đồ Dashboard** — lỗi width/height(-1), gradient ID, API react-grid-layout
- **6 endpoint API bị hỏng** — không khớp schema giữa model và database
- **Xung đột z-index** giữa confirm dialog, toast và cửa sổ nổi
- **Tải CSR** — không khớp endpoint (`/download` → `/export`)
- **Xuất PFX/P12** — thiếu prompt mật khẩu trong cửa sổ chi tiết nổi
- **postinst auto-update DEB** — các unit systemd updater chưa bao giờ được bật
- Sửa force_password_change không được đặt khi tạo admin mới
- Sửa vòng lặp vô hạn trong reports do canWrite trong deps useCallback
- Xóa 23 câu lệnh console.error khỏi code production

### Bảo mật
- **Xóa JWT** — chỉ dùng session cookie + API key (giảm bề mặt tấn công)
- **cryptography** nâng cấp từ 46.0.3 lên 46.0.5 (CVE-2026-26007)
- Rate limiting SSO trên lần thử đăng nhập LDAP kèm khóa tài khoản
- Xác thực CSRF token trên tất cả endpoint SSO
- Thực thi quyền RBAC trên tất cả trang frontend và cửa sổ nổi
- Sửa SQL injection và ngăn rò rỉ debug
- Thêm security header Referrer-Policy
- Xác thực vai trò theo danh sách vai trò được phép
- Chi tiết lỗi nội bộ không còn bị rò rỉ ra API client
- 28 test bảo mật SSO mới

---

## [2.0.7] - 2026-02-13

### Sửa lỗi
- **Đóng gói** — đảm bảo script có thể thực thi sau `chmod 644` toàn cục
- **Tự cập nhật** — thay thế shell command injection bằng systemd trigger
- **Đóng gói** — khởi động lại dịch vụ khi nâng cấp thay vì chỉ start

---

## [2.0.6] - 2026-02-12

### Sửa lỗi
- **Import OPNsense** — nút import không hiện sau khi kiểm tra kết nối

### Bảo mật
- **cryptography** nâng cấp từ 46.0.3 lên 46.0.5 (CVE-2026-26007)

---

## [2.0.4] - 2026-02-11

### Sửa lỗi
- **Form cấp chứng chỉ** — tùy chọn Select và tên trường bị hỏng
- **SSL/gevent** — gevent monkey-patch sớm cho bug đệ quy Python 3.13, safe_requests trong OPNsense import
- **Docker** — sửa tên thư mục data và migration, dùng `.env.docker.example`
- **VERSION** — tập trung hóa file VERSION làm nguồn dữ liệu duy nhất

---

## [2.0.1] - 2026-02-08

### Sửa lỗi
- **Đường dẫn cert HTTPS** — dùng `DATA_DIR` động thay vì đường dẫn cứng
- **Docker** — `worker_class` WebSocket (geventwebsocket), khởi động lại cert HTTPS dùng `SIGTERM`
- **Khởi động lại dịch vụ** — khởi động lại đáng tin cậy qua sudoers để áp dụng cert HTTPS
- **WebSocket** — handler kết nối chấp nhận tham số auth
- **Phiên bản** — nguồn dữ liệu duy nhất từ `frontend/package.json`

---

## [2.0.0] - 2026-02-07

### Cải tiến bảo mật (từ beta2)

- **Nút Hiện/Ẩn mật khẩu** — Tất cả trường mật khẩu có nút bật tắt hiển thị
- **Chỉ báo độ mạnh mật khẩu** — Đồng hồ đo độ mạnh trực quan với 5 cấp độ (Yếu → Mạnh)
- **Luồng Quên mật khẩu** — Đặt lại mật khẩu qua email với token bảo mật
- **Buộc đổi mật khẩu** — Admin có thể yêu cầu đổi mật khẩu lần đăng nhập kế tiếp
- **Cảnh báo hết hạn session** — Cảnh báo trước 5 phút khi session sắp hết với tùy chọn gia hạn

### Cải tiến Dashboard

- **Hiển thị phiên bản động** — Hiển thị phiên bản hiện tại
- **Chỉ báo có bản cập nhật** — Thông báo trực quan khi có cập nhật mới
- **Layout cố định** — Padding và khoảng cách đúng trong tất cả widget dashboard

### Sửa lỗi

- Sửa lỗi cuộn của dashboard
- Sửa padding trong widget System Health
- Sửa padding trong biểu đồ Certificate Activity
- Khôi phục chế độ xem CA phân cấp

---

## [2.0.0-beta1] - 2026-02-06

### Thiết kế lại giao diện hoàn toàn

Bản phát hành lớn với frontend React 18 hoàn toàn mới thay thế giao diện HTMX cũ.

#### Stack Frontend Mới
- **React 18** với Vite để build nhanh
- **Radix UI** cho các component dễ tiếp cận
- **CSS tùy chỉnh** với biến theme
- **Layout Split-View** với thiết kế đáp ứng

#### Tính năng mới
- **12 biến thể Theme** — 6 màu theme (Gray, Ocean, Purple, Forest, Sunset, Cyber) × chế độ Sáng/Tối
- **Nhóm người dùng** — Tổ chức người dùng theo nhóm dựa trên quyền
- **Template chứng chỉ** — Cấu hình chứng chỉ được định nghĩa sẵn
- **Smart Import** — Trình phân tích thông minh cho cert, key, CSR
- **Công cụ chứng chỉ** — Kiểm tra SSL, giải mã CSR, giải mã chứng chỉ, khớp khóa, chuyển đổi định dạng
- **Command Palette** — Tìm kiếm toàn cục Ctrl+K với các hành động nhanh
- **Trust Store** — Quản lý chứng chỉ CA tin cậy
- **Quản lý ACME** — Theo dõi tài khoản, lịch sử đơn hàng, trạng thái thách thức
- **Nhật ký kiểm tra** — Ghi log hành động đầy đủ với lọc, xuất và xác minh toàn vẹn
- **Biểu đồ Dashboard** — Xu hướng chứng chỉ (7 ngày), biểu đồ tròn phân phối trạng thái
- **Nguồn cấp hoạt động** — Hiển thị hành động gần đây theo thời gian thực

#### Cải tiến giao diện
- **Thiết kế đáp ứng** — Mobile-first với layout thích ứng
- **Điều hướng Mobile** — Menu lưới với hỗ trợ vuốt
- **Điều hướng bằng bàn phím** — Hỗ trợ phím đầy đủ
- **Cập nhật thời gian thực** — Làm mới trực tiếp dựa trên WebSocket
- **Font Inter + JetBrains Mono**
- **Help theo ngữ cảnh** — Modal trợ giúp trên mỗi trang

#### Cải tiến Backend
- **API v2** — RESTful JSON API dưới `/api/v2/`
- **Đường dẫn thống nhất** — Cùng cấu trúc cho DEB/RPM/Docker (`/opt/ucm/`)
- **Tự động migration** — Nâng cấp liền mạch v1.8.x → v2.0.0 với backup
- **Tự động tái tạo CRL** — Scheduler nền để làm mới CRL
- **API Health Check** — Endpoint giám sát hệ thống
- **Hỗ trợ WebSocket** — Thông báo sự kiện thời gian thực

#### Triển khai
- **CI/CD thống nhất** — Workflow duy nhất cho DEB/RPM/Docker
- **Gói đã kiểm tra** — DEB (Debian 12) và RPM (Fedora 43) đã xác minh
- **Python venv** — Dependencies được cô lập

---

## [1.8.3] - 2026-01-10

### Sửa lỗi

#### Đã sửa
- **Dependency Nginx** — Nginx giờ thực sự là tùy chọn
- **Chế độ Standalone** — UCM chạy không cần reverse proxy
- **Đóng gói** — Sửa workflow GitHub Actions

#### Tài liệu
- Tất cả hướng dẫn đã cập nhật lên v1.8.3
- Tùy chọn triển khai được ghi lại rõ ràng

---

## [1.8.2] - 2026-01-10

### Cải tiến

- Xác thực xuất cho tất cả định dạng (PEM, DER, PKCS#12)
- Xem trước theme trực quan với lưới xem trước trực tiếp
- Tương thích đường dẫn Docker/Native
- Modal xuất PKCS#12 toàn cục

---

## [1.8.0-beta] - 2026-01-09

### Tính năng chính

- **Xác thực mTLS** — Đăng nhập bằng chứng chỉ client
- **REST API v1** — API đầy đủ để tự động hóa
- **Import OPNsense** — Import trực tiếp từ firewall
- **Thông báo Email** — Cảnh báo hết hạn chứng chỉ

---

## [1.7.0] - 2026-01-08

### Tính năng

- **ACME Server** — Tương thích với Let's Encrypt
- **WebAuthn/FIDO2** — Hỗ trợ khóa bảo mật phần cứng
- **Sidebar thu gọn** — Cải thiện điều hướng
- **Hệ thống Theme** — 8 giao diện đẹp

---

## [1.6.0] - 2026-01-05

### Cải tiến giao diện

- Xóa hoàn toàn Tailwind CSS
- Thanh cuộn có chủ đề tùy chỉnh
- Trang thông tin CRL
- Thiết kế đáp ứng đầy đủ

---

## [1.0.0] - 2025-12-15

### Phát hành lần đầu

- Quản lý Certificate Authority
- Vòng đời chứng chỉ (tạo, ký, thu hồi)
- SCEP server
- OCSP responder
- Phân phối CRL/CDP
- Quản trị qua web
