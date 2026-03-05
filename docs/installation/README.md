
## System Requirements

### Minimum Requirements
- **CPU:** 2 cores
- **RAM:** 2 GB
- **Storage:** 5 GB free space
- **OS:** Linux (any distribution)

### Recommended Requirements
- **CPU:** 4 cores
- **RAM:** 4 GB
- **Storage:** 20 GB free space (for CA data and backups)

### Software Requirements
- **Docker:** 20.10+ (for Docker installation)
- **Python:** 3.11+ (for source installation)
- **Database:** SQLite (included)

## Installation Methods


### Method 4: From Source

**For development or custom deployments.**

```bash
# Clone repository
git clone https://github.com/NeySlim/ultimate-ca-manager.git
cd ultimate-ca-manager

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r backend/requirements.txt

# Run
python wsgi.py
```

**Access:** https://localhost:8443 or https://your-server-fqdn:8443
---

## First Login

After installation, access UCM at **https://localhost:8443** (or **https://your-server-fqdn:8443** for remote access)

**Default Credentials:**
- **Username:** admin
- **Password:** `changeme123`

**IMPORTANT:** Change the default password immediately after first login!



## Data Locations

### Docker
- **Data:** `/opt/ucm/data` (inside container, mount as volume)
- **Volume:** `ucm-data` (Docker volume)
- **Config:** Environment variables

### DEB/RPM Packages
- **Data:** `/opt/ucm/data`
- **Config:** `/etc/ucm/ucm.env`
- **Logs:** `/var/log/ucm/`
- **Service:** `/etc/systemd/system/ucm.service`

### Source Installation
- **Data:** `./backend/data` (relative to repository root)
- **Config:** Environment variables or `/etc/ucm/ucm.env`
- **Logs:** `/var/log/ucm/ucm.log`

---

## Next Steps

After installation:

1. **Change default password** — Settings → Users & Groups
2. **Configure HTTPS certificate** — Upload a trusted certificate or use the auto-generated one
3. **Create your first CA** — Dashboard → Create Certificate Authority
4. **Configure email notifications** (optional) — Settings → SMTP
5. **Enable ACME/SCEP** (optional) — ACME / SCEP pages

---
## Additional Resources

- [Docker Deployment Guide](docker.md)
- [Upgrade Guide](../../UPGRADE.md)
- [Redis for HA](../REDIS.md)
