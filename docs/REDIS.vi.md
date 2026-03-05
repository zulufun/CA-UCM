# Hướng dẫn Tích hợp Redis

UCM hỗ trợ Redis để cache phân tán và giới hạn tốc độ. Redis là **tùy chọn** - UCM hoạt động hoàn toàn bình thường mà không cần Redis, sử dụng bộ nhớ trong.

## Khi nào Cần Dùng Redis

| Trường hợp | Cần Redis? |
|------------|------------|
| Một instance UCM duy nhất | Không |
| Nhiều instance UCM (cân bằng tải) | Có |
| Cài đặt tính khả dụng cao | Có |
| Giới hạn tốc độ bền vững qua các lần khởi động lại | Có |
| UCM với nhiều người dùng đồng thời | Khuyến nghị |

## Tính năng Được Bật khi Dùng Redis

- **Giới hạn Tốc độ Phân tán**: Giới hạn được chia sẻ trên tất cả worker/instance
- **Cache Dùng chung**: Giảm sử dụng bộ nhớ và đảm bảo tính nhất quán của cache
- **Session Bền vững**: Session tồn tại qua các lần khởi động lại UCM

---

## Cài đặt

### Docker (Khuyến nghị)

```bash
# Dùng file overlay Redis
docker compose -f docker-compose.yml -f docker-compose.redis.yml up -d
```

Hoặc bỏ ghi chú dịch vụ Redis trong `docker-compose.yml`.

### Debian / Ubuntu

```bash
# Cài đặt Redis server
sudo apt update
sudo apt install -y redis-server

# Bật và khởi động
sudo systemctl enable redis-server
sudo systemctl start redis-server

# Kiểm tra
redis-cli ping # Nên trả về PONG
```

### CentOS / RHEL / Rocky Linux

```bash
# Cài đặt Redis
sudo dnf install -y redis

# Bật và khởi động
sudo systemctl enable redis
sudo systemctl start redis

# Kiểm tra
redis-cli ping # Nên trả về PONG
```

### Alpine Linux

```bash
apk add redis
rc-update add redis default
rc-service redis start
```

---

## Cấu hình

Thêm vào `/etc/ucm/ucm.env`:

```bash
# Redis cục bộ
UCM_REDIS_URL=redis://localhost:6379/0

# Redis có mật khẩu
UCM_REDIS_URL=redis://:mypassword@localhost:6379/0

# Redis từ xa
UCM_REDIS_URL=redis://redis.example.com:6379/0

# Redis Sentinel (tính khả dụng cao)
UCM_REDIS_URL=redis+sentinel://sentinel1:26379,sentinel2:26379/mymaster/0
```

Sau đó khởi động lại UCM:
```bash
sudo systemctl restart ucm
```

---

## Xác minh Tích hợp Redis

Kiểm tra nhật ký UCM sau khi khởi động lại:

```bash
# Nên hiển thị "Redis" thay vì "Memory"
journalctl -u ucm --no-pager | grep -i "cache\|rate"
```

Kết quả mong đợi:
```
✓ Cache enabled (Redis)
✓ Rate limiting enabled (Redis - distributed)
```

---

## Bảo mật Redis

### Chỉ bind vào localhost (mặc định)

Chỉnh sửa `/etc/redis/redis.conf`:
```
bind 127.0.0.1
```

### Bật xác thực

```
requirepass your_strong_password_here
```

### Vô hiệu hóa các lệnh nguy hiểm

```
rename-command FLUSHALL ""
rename-command FLUSHDB ""
rename-command CONFIG ""
```

Khởi động lại Redis sau khi thay đổi:
```bash
sudo systemctl restart redis
```

---

## Xử lý Sự cố

### UCM không dùng Redis

1. Kiểm tra Redis đang chạy: `redis-cli ping`
2. Kiểm tra UCM_REDIS_URL đã được đặt: `grep REDIS /etc/ucm/ucm.env`
3. Kiểm tra nhật ký UCM: `journalctl -u ucm -n 50`

### Kết nối bị từ chối

```bash
# Kiểm tra Redis đang lắng nghe
ss -tlnp | grep 6379

# Kiểm tra tường lửa (nếu dùng Redis từ xa)
sudo firewall-cmd --list-ports
```

### Vấn đề Bộ nhớ

Redis được cấu hình với giới hạn bộ nhớ trong docker-compose:
```
--maxmemory 128mb --maxmemory-policy allkeys-lru
```

Điều chỉnh theo nhu cầu của bạn. Với hầu hết các triển khai UCM, 64-256MB là đủ.
