# Hướng dẫn Triển khai HSM trên Docker

UCM tích hợp SoftHSM2 trong image Docker. Các tính năng HSM hoạt động ngay lập tức — không cần cấu hình thêm.

## Bắt đầu Nhanh

```bash
docker compose -f docker-compose.hsm.yml up -d
```

Khi khởi động lần đầu, một token SoftHSM mặc định (`UCM-Default`) sẽ được tự động khởi tạo. PIN được in ra trong nhật ký container.

## Token Bền vững

Gắn volume cho `/var/lib/softhsm/tokens` để giữ khóa HSM qua các lần khởi động lại container:

```bash
docker run -d --name ucm -p 8443:8443 \
  -v ucm-data:/opt/ucm/data \
  -v ucm-hsm:/var/lib/softhsm/tokens \
  neyslim/ultimate-ca-manager:latest
```

## Biến Môi trường

| Biến | Mặc định | Mô tả |
|------|----------|-------|
| `HSM_AUTO_INIT` | `true` | Tự động tạo token SoftHSM mặc định khi khởi động lần đầu |
| `HSM_PIN` | *(ngẫu nhiên)* | PIN cho token được khởi tạo tự động |
| `HSM_SO_PIN` | *(ngẫu nhiên)* | SO PIN cho token được khởi tạo tự động |

## Quản lý Token Thủ công

```bash
# Liệt kê token
docker exec ucm softhsm2-util --show-slots

# Tạo thêm token
docker exec ucm softhsm2-util --init-token --free \
  --label "MyToken" --pin 1234 --so-pin 5678

# Xóa token
docker exec ucm softhsm2-util --delete-token --serial <serial>
```

## HSM Phần cứng

Với HSM phần cứng (Thales, SafeNet, v.v.), gắn thư viện PKCS#11 của nhà cung cấp và thiết bị:

```yaml
services:
  ucm:
    image: neyslim/ultimate-ca-manager:latest
    devices:
      - /dev/pkcs11
    volumes:
      - /opt/vendor/lib:/opt/vendor/lib:ro
```

Sau đó cấu hình nhà cung cấp trong giao diện web UCM với đường dẫn thư viện của nhà cung cấp.

## HSM Đám mây

Cấu hình nhà cung cấp HSM đám mây qua giao diện web UCM (Settings → HSM):

- **AWS CloudHSM** — sử dụng PKCS#11 với thư viện CloudHSM client
- **Azure Key Vault** — yêu cầu `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`
- **Google Cloud KMS** — yêu cầu thông tin xác thực service account GCP

## Sao lưu & Khôi phục

```bash
# Sao lưu token
docker cp ucm:/var/lib/softhsm/tokens ./hsm-backup/

# Khôi phục token
docker cp ./hsm-backup/. ucm:/var/lib/softhsm/tokens/
```

Hoặc dùng Docker volume:

```bash
# Tạo file lưu trữ sao lưu
docker run --rm -v ucm-hsm:/data -v $(pwd):/backup \
  alpine tar czf /backup/hsm-tokens.tar.gz -C /data .
```
