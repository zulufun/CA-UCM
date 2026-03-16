#!/bin/bash
# UCM Docker Entrypoint Script
# Comprehensive environment configuration and initialization

set -e

# Error handler
trap 'echo "❌ Error on line $LINENO. Exiting."; exit 1' ERR

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Banner
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Ultimate CA Manager - Docker         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

generate_secret() {
    python3 -c 'import secrets; print(secrets.token_hex(32))'
}

validate_port() {
    local port=$1
    if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; then
        return 0
    else
        return 1
    fi
}

validate_fqdn() {
    local fqdn=$1
    if [[ "$fqdn" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_email() {
    local email=$1
    if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# =============================================================================
# ENVIRONMENT VARIABLE DEFAULTS
# =============================================================================

# Core Settings
# shellcheck disable=SC2223
: ${UCM_FQDN:="ucm.local"}
: ${UCM_HTTPS_PORT:=8443}
: ${UCM_HTTP_PORT:=8080}
: ${UCM_DEBUG:=false}
: ${UCM_LOG_LEVEL:="INFO"}

# Security
: ${UCM_SECRET_KEY:=$(generate_secret)}
: ${UCM_JWT_SECRET:=$(generate_secret)}
: ${UCM_SESSION_TIMEOUT:=3600}
: ${UCM_JWT_EXPIRATION:=86400}

# Database
: ${UCM_DATABASE_PATH:="/opt/ucm/data/ucm.db"}
: ${UCM_BACKUP_ENABLED:=true}
: ${UCM_BACKUP_RETENTION_DAYS:=30}

# SMTP Configuration
: ${UCM_SMTP_ENABLED:=false}
: ${UCM_SMTP_SERVER:=""}
: ${UCM_SMTP_PORT:=587}
: ${UCM_SMTP_USERNAME:=""}
: ${UCM_SMTP_PASSWORD:=""}
: ${UCM_SMTP_FROM:="noreply@${UCM_FQDN}"}
: ${UCM_SMTP_TLS:=true}

# Caching
: ${UCM_CACHE_ENABLED:=true}
: ${UCM_CACHE_TYPE:="simple"}
: ${UCM_CACHE_DEFAULT_TIMEOUT:=300}

# mTLS Configuration
: ${UCM_MTLS_ENABLED:=false}
: ${UCM_MTLS_CA_ID:=""}
: ${UCM_MTLS_REQUIRE_CERT:=false}

# Certificate Settings
: ${UCM_DEFAULT_VALIDITY_DAYS:=365}
: ${UCM_DEFAULT_KEY_SIZE:=4096}
: ${UCM_DEFAULT_HASH_ALGO:="SHA256"}

# ACME Settings
: ${UCM_ACME_ENABLED:=true}
: ${UCM_ACME_DIRECTORY_URL:="https://${UCM_FQDN}:${UCM_HTTPS_PORT}/acme/directory"}

# Initial Admin User
: ${UCM_INITIAL_ADMIN_USERNAME:="admin"}
: ${UCM_INITIAL_ADMIN_EMAIL:="admin@${UCM_FQDN}"}
: ${UCM_INITIAL_ADMIN_PASSWORD:="changeme123"}

# =============================================================================
# VALIDATION
# =============================================================================

echo -e "${BLUE}🔍 Validating configuration...${NC}"

# Validate FQDN
if ! validate_fqdn "$UCM_FQDN"; then
    echo -e "${RED}❌ Invalid FQDN: $UCM_FQDN${NC}"
    echo "   FQDN must be a valid domain name (e.g., ucm.example.com)"
    exit 1
fi

# Validate ports
if ! validate_port "$UCM_HTTPS_PORT"; then
    echo -e "${RED}❌ Invalid HTTPS port: $UCM_HTTPS_PORT${NC}"
    exit 1
fi

if ! validate_port "$UCM_HTTP_PORT"; then
    echo -e "${RED}❌ Invalid HTTP port: $UCM_HTTP_PORT${NC}"
    exit 1
fi

# Validate SMTP settings if enabled
if [ "$UCM_SMTP_ENABLED" = "true" ]; then
    if [ -z "$UCM_SMTP_SERVER" ]; then
        echo -e "${YELLOW}⚠️  SMTP enabled but no server configured${NC}"
        UCM_SMTP_ENABLED=false
    elif ! validate_email "$UCM_SMTP_FROM"; then
        echo -e "${YELLOW}⚠️  Invalid SMTP FROM address: $UCM_SMTP_FROM${NC}"
        UCM_SMTP_FROM="noreply@${UCM_FQDN}"
    fi
fi

echo -e "${GREEN}✅ Configuration validated${NC}"

# =============================================================================
# DIRECTORY SETUP
# =============================================================================

echo -e "${BLUE}📁 Setting up directories...${NC}"

# Unified data path: /opt/ucm/data (same as DEB/RPM)
DATA_PATH="/opt/ucm/data"

# Migration: if old path has data, migrate everything to new path
OLD_DATA_PATH="/app/backend/data"
if [ -d "$OLD_DATA_PATH" ] && [ "$(ls -A $OLD_DATA_PATH 2>/dev/null)" ]; then
    echo -e "${YELLOW}   Checking for data migration from $OLD_DATA_PATH...${NC}"
    # Copy everything that doesn't already exist in new path
    for item in "$OLD_DATA_PATH"/*; do
        basename_item=$(basename "$item")
        # Rename 'cas' → 'ca' (old Docker naming mismatch)
        target_name="$basename_item"
        if [ "$basename_item" = "cas" ]; then
            target_name="ca"
        fi
        if [ ! -e "$DATA_PATH/$target_name" ]; then
            echo -e "${YELLOW}   Migrating $basename_item → $target_name...${NC}"
            cp -a "$item" "$DATA_PATH/$target_name" 2>/dev/null || true
        elif [ -d "$item" ] && [ -d "$DATA_PATH/$target_name" ]; then
            # Merge directories: copy files that don't exist in destination
            for subitem in "$item"/*; do
                sub_basename=$(basename "$subitem")
                if [ ! -e "$DATA_PATH/$target_name/$sub_basename" ]; then
                    echo -e "${YELLOW}   Migrating $target_name/$sub_basename...${NC}"
                    cp -a "$subitem" "$DATA_PATH/$target_name/" 2>/dev/null || true
                fi
            done
        fi
    done
    echo -e "${GREEN}✅ Data migration complete${NC}"
fi

# Create necessary directories (must match backend/config/settings.py)
mkdir -p "$DATA_PATH"/{ca,certs,private,crl,scep,backups,sessions,logs,temp} 2>/dev/null || true
chmod 755 "$DATA_PATH" 2>/dev/null || true
chmod 700 "$DATA_PATH"/{ca,certs,private,backups} 2>/dev/null || true

# Fix permissions to ensure UCM user can write (entrypoint runs as root)
echo -e "${BLUE}🔧 Fixing file permissions...${NC}"
chown -R 1000:1000 "$DATA_PATH" 2>/dev/null || true

echo -e "${GREEN}✅ Directories ready${NC}"

# =============================================================================
# CONFIGURATION FILE GENERATION
# =============================================================================

echo -e "${BLUE}⚙️  Generating configuration...${NC}"

# Create env file from environment variables with write fallbacks
ENV_FILE_WRITTEN=""
ENV_CANDIDATES=("/etc/ucm/ucm.env" "$DATA_PATH/ucm.env" "/tmp/ucm.env")

for ENV_FILE in "${ENV_CANDIDATES[@]}"; do
    ENV_DIR=$(dirname "$ENV_FILE")
    mkdir -p "$ENV_DIR" 2>/dev/null || true

    # Skip unwritable candidates to avoid noisy permission errors
    if ! TEST_ENV_FILE=$(mktemp "$ENV_DIR/.ucm-env-write-test.XXXXXX" 2>/dev/null); then
        continue
    fi
    rm -f "$TEST_ENV_FILE" 2>/dev/null || true

    if cat > "$ENV_FILE" <<EOF
# UCM Configuration - Auto-generated by Docker entrypoint
# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

# Core Settings
FQDN=${UCM_FQDN}
HTTPS_PORT=${UCM_HTTPS_PORT}
HTTP_PORT=${UCM_HTTP_PORT}
DEBUG=${UCM_DEBUG}
LOG_LEVEL=${UCM_LOG_LEVEL}

# Security
SECRET_KEY=${UCM_SECRET_KEY}
JWT_SECRET_KEY=${UCM_JWT_SECRET}
SESSION_TIMEOUT=${UCM_SESSION_TIMEOUT}
JWT_EXPIRATION=${UCM_JWT_EXPIRATION}

# Database
DATABASE_PATH=${UCM_DATABASE_PATH}
BACKUP_ENABLED=${UCM_BACKUP_ENABLED}
BACKUP_RETENTION_DAYS=${UCM_BACKUP_RETENTION_DAYS}

# SMTP Configuration
SMTP_ENABLED=${UCM_SMTP_ENABLED}
SMTP_SERVER=${UCM_SMTP_SERVER}
SMTP_PORT=${UCM_SMTP_PORT}
SMTP_USERNAME=${UCM_SMTP_USERNAME}
SMTP_PASSWORD=${UCM_SMTP_PASSWORD}
SMTP_FROM=${UCM_SMTP_FROM}
SMTP_TLS=${UCM_SMTP_TLS}

# Caching
CACHE_ENABLED=${UCM_CACHE_ENABLED}
CACHE_TYPE=${UCM_CACHE_TYPE}
CACHE_DEFAULT_TIMEOUT=${UCM_CACHE_DEFAULT_TIMEOUT}

# mTLS Configuration
MTLS_ENABLED=${UCM_MTLS_ENABLED}
MTLS_CA_ID=${UCM_MTLS_CA_ID}
MTLS_REQUIRE_CERT=${UCM_MTLS_REQUIRE_CERT}

# Certificate Defaults
DEFAULT_VALIDITY_DAYS=${UCM_DEFAULT_VALIDITY_DAYS}
DEFAULT_KEY_SIZE=${UCM_DEFAULT_KEY_SIZE}
DEFAULT_HASH_ALGO=${UCM_DEFAULT_HASH_ALGO}

# ACME Settings
ACME_ENABLED=${UCM_ACME_ENABLED}
ACME_DIRECTORY_URL=${UCM_ACME_DIRECTORY_URL}

# Initial Admin User (used on first run)
INITIAL_ADMIN_USERNAME=${UCM_INITIAL_ADMIN_USERNAME}
INITIAL_ADMIN_EMAIL=${UCM_INITIAL_ADMIN_EMAIL}
INITIAL_ADMIN_PASSWORD=${UCM_INITIAL_ADMIN_PASSWORD}

EOF
    then

        chmod 600 "$ENV_FILE" 2>/dev/null || true
        ENV_FILE_WRITTEN="$ENV_FILE"
        break
    fi
done

if [ -n "$ENV_FILE_WRITTEN" ]; then
    echo -e "${GREEN}✅ Configuration file created at: $ENV_FILE_WRITTEN${NC}"
else
    echo -e "${YELLOW}⚠️  Could not write env file (read-only filesystem?)${NC}"
    echo -e "${YELLOW}   Continuing with exported environment variables only${NC}"
fi

# =============================================================================
# HTTPS CERTIFICATE SETUP
# =============================================================================

echo -e "${BLUE}🔐 Setting up HTTPS certificate...${NC}"

CERT_PATH="/opt/ucm/data/https_cert.pem"
KEY_PATH="/opt/ucm/data/https_key.pem"

HAS_EXISTING_CERT=false
if [ -f "$CERT_PATH" ] && [ -f "$KEY_PATH" ]; then
    HAS_EXISTING_CERT=true
fi

# Check if target TLS paths are writable (directory + existing file if present)
CERT_PATH_WRITABLE=true
CERT_DIR=$(dirname "$CERT_PATH")
KEY_DIR=$(dirname "$KEY_PATH")

if ! TEST_CERT_FILE=$(mktemp "$CERT_DIR/.ucm-cert-write-test.XXXXXX" 2>/dev/null); then
    CERT_PATH_WRITABLE=false
else
    rm -f "$TEST_CERT_FILE" 2>/dev/null || true
fi

if ! TEST_KEY_FILE=$(mktemp "$KEY_DIR/.ucm-key-write-test.XXXXXX" 2>/dev/null); then
    CERT_PATH_WRITABLE=false
else
    rm -f "$TEST_KEY_FILE" 2>/dev/null || true
fi

if [ -e "$CERT_PATH" ] && [ ! -w "$CERT_PATH" ]; then
    CERT_PATH_WRITABLE=false
fi

if [ -e "$KEY_PATH" ] && [ ! -w "$KEY_PATH" ]; then
    CERT_PATH_WRITABLE=false
fi

FALLBACK_CERT_DIR="/tmp/ucm-https"
mkdir -p "$FALLBACK_CERT_DIR" 2>/dev/null || true

# Check if custom certificates provided via ENV
if [ -n "$UCM_HTTPS_CERT" ] && [ -n "$UCM_HTTPS_KEY" ]; then
    echo -e "${CYAN}   Using custom certificates from ENV...${NC}"
    if [ "$CERT_PATH_WRITABLE" = "true" ]; then
        TARGET_CERT_PATH="$CERT_PATH"
        TARGET_KEY_PATH="$KEY_PATH"
    else
        TARGET_CERT_PATH="$FALLBACK_CERT_DIR/https_cert.pem"
        TARGET_KEY_PATH="$FALLBACK_CERT_DIR/https_key.pem"
        export HTTPS_CERT_PATH="$TARGET_CERT_PATH"
        export HTTPS_KEY_PATH="$TARGET_KEY_PATH"
        echo -e "${YELLOW}⚠️  /opt/ucm/data not writable for TLS files; using $FALLBACK_CERT_DIR${NC}"
    fi

    echo "$UCM_HTTPS_CERT" > "$TARGET_CERT_PATH"
    echo "$UCM_HTTPS_KEY" > "$TARGET_KEY_PATH"
    chmod 600 "$TARGET_KEY_PATH"
    chmod 644 "$TARGET_CERT_PATH"
    echo -e "${GREEN}✅ Custom certificates installed${NC}"
# Check if certificates exist in volume
elif [ "$HAS_EXISTING_CERT" = "true" ]; then
    echo -e "${GREEN}✅ Using existing certificates${NC}"
# Generate self-signed certificate
else
    echo -e "${YELLOW}   Generating self-signed certificate...${NC}"
    
    # Get container's hostname and IP (IPv4 only for certificate)
    CONTAINER_HOSTNAME=$(hostname)
    CONTAINER_IP=$(hostname -i 2>/dev/null | tr ' ' '\n' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -1 || echo "127.0.0.1")
    
    # Create OpenSSL config for SAN (Chrome/Edge compatibility)
    cat > /tmp/openssl.cnf <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = State
L = City
O = Ultimate CA Manager
OU = IT
CN = ${UCM_FQDN}

[v3_req]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
basicConstraints = CA:FALSE

[alt_names]
DNS.1 = ${UCM_FQDN}
DNS.2 = localhost
DNS.3 = ${CONTAINER_HOSTNAME}
DNS.4 = *.local
DNS.5 = pve
IP.1 = 127.0.0.1
IP.2 = ${CONTAINER_IP}
EOF
    
    TEMP_CERT_PATH="$FALLBACK_CERT_DIR/https_cert.pem"
    TEMP_KEY_PATH="$FALLBACK_CERT_DIR/https_key.pem"

    # Generate certificate in writable temp location first
    if openssl req -x509 -newkey rsa:4096 -nodes \
        -keyout "$TEMP_KEY_PATH" \
        -out "$TEMP_CERT_PATH" \
        -days 365 \
        -config /tmp/openssl.cnf \
        -extensions v3_req 2>&1; then

        chmod 600 "$TEMP_KEY_PATH"
        chmod 644 "$TEMP_CERT_PATH"

        if [ "$CERT_PATH_WRITABLE" = "true" ] && cp "$TEMP_CERT_PATH" "$CERT_PATH" 2>/dev/null && cp "$TEMP_KEY_PATH" "$KEY_PATH" 2>/dev/null; then
            chmod 600 "$KEY_PATH" 2>/dev/null || true
            chmod 644 "$CERT_PATH" 2>/dev/null || true
        else
            export HTTPS_CERT_PATH="$TEMP_CERT_PATH"
            export HTTPS_KEY_PATH="$TEMP_KEY_PATH"
            echo -e "${YELLOW}⚠️  /opt/ucm/data not writable for TLS files; using $FALLBACK_CERT_DIR${NC}"
        fi

        rm -f /tmp/openssl.cnf
        
        echo -e "${GREEN}✅ Self-signed certificate generated${NC}"
        echo -e "${YELLOW}   ⚠️  For production, use a trusted certificate!${NC}"
    else
        echo -e "${RED}❌ Failed to generate certificate${NC}"
        rm -f /tmp/openssl.cnf
        exit 1
    fi
fi

# =============================================================================
# DATABASE INITIALIZATION
# =============================================================================

echo -e "${BLUE}💾 Checking database...${NC}"

if [ ! -f "$UCM_DATABASE_PATH" ]; then
    echo -e "${YELLOW}   First run detected - database will be auto-created${NC}"
    echo -e "${CYAN}   Default credentials:${NC}"
    echo "   • Username: admin"
    echo "   • Password: changeme123"
    echo -e "   ${RED}⚠️  CHANGE THIS PASSWORD IMMEDIATELY!${NC}"
else
    echo -e "${GREEN}✅ Database exists${NC}"
    
    # Database backup if enabled
    if [ "$UCM_BACKUP_ENABLED" = "true" ]; then
        BACKUP_DIR="/opt/ucm/data/backups"
        BACKUP_FILE="$BACKUP_DIR/ucm-backup-$(date +%Y%m%d-%H%M%S).db"
        
        # Create backup
        cp "$UCM_DATABASE_PATH" "$BACKUP_FILE"
        echo -e "${GREEN}✅ Database backup created${NC}"
        
        # Clean old backups
        find "$BACKUP_DIR" -name "ucm-backup-*.db" -mtime "+$UCM_BACKUP_RETENTION_DAYS" -delete 2>/dev/null || true
    fi
fi

# =============================================================================
# DISPLAY CONFIGURATION SUMMARY
# =============================================================================

echo ""
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║       Configuration Summary            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}🌐 Network:${NC}"
echo "   • FQDN:        ${UCM_FQDN}"
echo "   • HTTPS Port:  ${UCM_HTTPS_PORT}"
echo "   • HTTP Port:   ${UCM_HTTP_PORT}"
echo ""
echo -e "${GREEN}💾 Storage:${NC}"
echo "   • Database:    ${UCM_DATABASE_PATH}"
echo "   • Data Dir:    /opt/ucm/data"
echo "   • Backup:      ${UCM_BACKUP_ENABLED}"
echo ""
echo -e "${GREEN}📧 Email:${NC}"
echo "   • SMTP:        ${UCM_SMTP_ENABLED}"
if [ "$UCM_SMTP_ENABLED" = "true" ]; then
    echo "   • Server:      ${UCM_SMTP_SERVER}:${UCM_SMTP_PORT}"
    echo "   • From:        ${UCM_SMTP_FROM}"
fi
echo ""
echo -e "${GREEN}🔒 Security:${NC}"
echo "   • mTLS:        ${UCM_MTLS_ENABLED}"
echo "   • Debug:       ${UCM_DEBUG}"
echo "   • Log Level:   ${UCM_LOG_LEVEL}"
echo ""
echo -e "${GREEN}🔧 Features:${NC}"
echo "   • ACME:        ${UCM_ACME_ENABLED}"
echo "   • Caching:     ${UCM_CACHE_ENABLED}"
echo ""
echo -e "${CYAN}════════════════════════════════════════${NC}"
echo ""

# =============================================================================
# HEALTH CHECK
# =============================================================================

# Create health check endpoint marker with writable fallback
if ! touch /opt/ucm/.docker-ready 2>/dev/null; then
    touch /tmp/.docker-ready 2>/dev/null || true
fi

# Export environment variables for Python app (without UCM_ prefix)
export FQDN="${UCM_FQDN}"
export HTTPS_PORT="${UCM_HTTPS_PORT}"
export HTTP_PORT="${UCM_HTTP_PORT}"
export DEBUG="${UCM_DEBUG}"
export LOG_LEVEL="${UCM_LOG_LEVEL}"
export SECRET_KEY="${UCM_SECRET_KEY}"
export JWT_SECRET_KEY="${UCM_JWT_SECRET}"
export SESSION_TIMEOUT="${UCM_SESSION_TIMEOUT}"
export JWT_EXPIRATION="${UCM_JWT_EXPIRATION}"
export DATABASE_PATH="${UCM_DATABASE_PATH}"
export BACKUP_ENABLED="${UCM_BACKUP_ENABLED}"
export BACKUP_RETENTION_DAYS="${UCM_BACKUP_RETENTION_DAYS}"
export SMTP_ENABLED="${UCM_SMTP_ENABLED}"
export SMTP_SERVER="${UCM_SMTP_SERVER}"
export SMTP_PORT="${UCM_SMTP_PORT}"
export SMTP_USERNAME="${UCM_SMTP_USERNAME}"
export SMTP_PASSWORD="${UCM_SMTP_PASSWORD}"
export SMTP_FROM="${UCM_SMTP_FROM}"
export SMTP_TLS="${UCM_SMTP_TLS}"
export CACHE_ENABLED="${UCM_CACHE_ENABLED}"
export CACHE_TYPE="${UCM_CACHE_TYPE}"
export CACHE_DEFAULT_TIMEOUT="${UCM_CACHE_DEFAULT_TIMEOUT}"
export MTLS_ENABLED="${UCM_MTLS_ENABLED}"
export MTLS_CA_ID="${UCM_MTLS_CA_ID}"
export MTLS_REQUIRE_CERT="${UCM_MTLS_REQUIRE_CERT}"
export INITIAL_ADMIN_USERNAME="${UCM_INITIAL_ADMIN_USERNAME}"
export INITIAL_ADMIN_EMAIL="${UCM_INITIAL_ADMIN_EMAIL}"
export INITIAL_ADMIN_PASSWORD="${UCM_INITIAL_ADMIN_PASSWORD}"
export ACME_ENABLED="${UCM_ACME_ENABLED}"

# =============================================================================
# HSM / SoftHSM AUTO-INIT
# =============================================================================
if command -v softhsm2-util >/dev/null 2>&1; then
    # Check if any token exists
    TOKEN_COUNT=$(softhsm2-util --show-slots 2>/dev/null | grep -c "Label:" || true)
    if [ "$TOKEN_COUNT" -eq 0 ] || [ "${HSM_AUTO_INIT:-true}" = "true" ] && ! softhsm2-util --show-slots 2>/dev/null | grep -q "UCM-Default"; then
        echo -e "${CYAN}🔐 Initializing SoftHSM default token...${NC}"
        HSM_PIN="${HSM_PIN:-$(openssl rand -hex 8)}"
        HSM_SO_PIN="${HSM_SO_PIN:-$(openssl rand -hex 8)}"
        softhsm2-util --init-token --free --label "UCM-Default" \
            --pin "$HSM_PIN" --so-pin "$HSM_SO_PIN" 2>/dev/null && \
        echo -e "${GREEN}   ✅ SoftHSM token 'UCM-Default' initialized (PIN: $HSM_PIN)${NC}" || \
        echo -e "${YELLOW}   ⚠️  SoftHSM token init skipped (may already exist)${NC}"
        export HSM_DEFAULT_PIN="$HSM_PIN"
    else
        echo -e "${GREEN}🔐 SoftHSM tokens found${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  SoftHSM not available - HSM features disabled${NC}"
fi

echo -e "${GREEN}🚀 Starting UCM...${NC}"
echo -e "${CYAN}   Access: https://${UCM_FQDN}:${UCM_HTTPS_PORT}${NC}"
echo ""
echo -e "${BLUE}📋 Executing command: $*${NC}"
echo ""

# Drop privileges and execute as ucm user
exec gosu ucm "$@"
