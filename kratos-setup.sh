#!/bin/bash
# ============================================================
#   KRATOS VPN SERVER - SETUP & MANAGER v2.0
#   2026 | Xray-core + Nginx + SSL + SQLite
#   Suporte: Ubuntu 20/22/24 | Debian 11/12
# ============================================================

# ── Cores ────────────────────────────────────────────────────
R='\033[1;31m'  G='\033[1;32m'  Y='\033[1;33m'
B='\033[1;34m'  C='\033[1;36m'  W='\033[1;37m'
P='\033[1;35m'  NC='\033[0m'
BG_BLUE='\033[44;1;37m'  BG_RED='\033[41;1;37m'

# ── Caminhos ─────────────────────────────────────────────────
KRATOS_DIR="/opt/kratos"
XRAY_DIR="/usr/local/bin"
XRAY_CONF="/etc/xray"
XRAY_LOG="/var/log/xray"
DB="$KRATOS_DIR/users.db"
CONF_FILE="$KRATOS_DIR/kratos.conf"
LOG_DIR="/var/log/kratos"
VERSION="2.0.0"

# ── Verificação de root ───────────────────────────────────────
[[ $EUID -ne 0 ]] && {
    echo -e "${R}[ERRO]${NC} Execute como root: sudo bash $0"
    exit 1
}

# ── Detectar OS ──────────────────────────────────────────────
detect_os() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS_NAME="$ID"
        OS_VER="$VERSION_ID"
    else
        echo -e "${R}[ERRO]${NC} Sistema operacional não reconhecido."
        exit 1
    fi
    [[ "$OS_NAME" =~ ^(ubuntu|debian)$ ]] || {
        echo -e "${R}[ERRO]${NC} Suporte apenas para Ubuntu/Debian."
        exit 1
    }
}

# ── Utilitários ──────────────────────────────────────────────
msg()  { echo -e "${G}[✔]${NC} $1"; }
warn() { echo -e "${Y}[!]${NC} $1"; }
err()  { echo -e "${R}[✘]${NC} $1"; }
info() { echo -e "${C}[i]${NC} $1"; }
sep()  { echo -e "${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }
header() {
    clear
    echo -e "${P}"
    echo "  ██╗  ██╗██████╗  █████╗ ████████╗ ██████╗ ███████╗"
    echo "  ██║ ██╔╝██╔══██╗██╔══██╗╚══██╔══╝██╔═══██╗██╔════╝"
    echo "  █████╔╝ ██████╔╝███████║   ██║   ██║   ██║███████╗"
    echo "  ██╔═██╗ ██╔══██╗██╔══██║   ██║   ██║   ██║╚════██║"
    echo "  ██║  ██╗██║  ██║██║  ██║   ██║   ╚██████╔╝███████║"
    echo "  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚══════╝"
    echo -e "${NC}"
    echo -e "  ${W}VPN SERVER MANAGER ${C}v${VERSION}${NC} │ ${Y}2026${NC} │ ${G}Xray-core + Nginx + SSL${NC}"
    sep
}

press_enter() {
    echo -e "\n${Y}[Enter para continuar...]${NC}"
    read -r
}

gen_uuid() { cat /proc/sys/kernel/random/uuid; }

gen_password() {
    tr -dc 'A-Za-z0-9@#$%' </dev/urandom | head -c 16
}

ip_publico() {
    curl -s4 https://api.ipify.org 2>/dev/null || \
    curl -s4 https://ifconfig.me 2>/dev/null || \
    hostname -I | awk '{print $1}'
}

# ── Banco de dados SQLite ─────────────────────────────────────
db_init() {
    [[ ! -d "$KRATOS_DIR" ]] && mkdir -p "$KRATOS_DIR"
    sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS users (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    username    TEXT UNIQUE NOT NULL,
    password    TEXT,
    uuid        TEXT UNIQUE,
    type        TEXT NOT NULL DEFAULT 'ssh',
    protocol    TEXT DEFAULT 'ssh',
    limit_conn  INTEGER DEFAULT 1,
    data_limit  INTEGER DEFAULT 0,
    data_used   INTEGER DEFAULT 0,
    created_at  TEXT DEFAULT (datetime('now')),
    expires_at  TEXT NOT NULL,
    status      TEXT DEFAULT 'active',
    note        TEXT
);
CREATE TABLE IF NOT EXISTS config (
    key   TEXT PRIMARY KEY,
    value TEXT
);
CREATE TABLE IF NOT EXISTS logs (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    action     TEXT,
    target     TEXT,
    details    TEXT,
    created_at TEXT DEFAULT (datetime('now'))
);
SQL
    msg "Banco de dados inicializado."
}

db_set() { sqlite3 "$DB" "INSERT OR REPLACE INTO config(key,value) VALUES('$1','$2');"; }
db_get() { sqlite3 "$DB" "SELECT value FROM config WHERE key='$1';"; }

db_log() {
    sqlite3 "$DB" "INSERT INTO logs(action,target,details) VALUES('$1','$2','$3');"
}

# ── Verificar instalação ──────────────────────────────────────
is_installed() {
    command -v "$1" &>/dev/null
}

xray_running() {
    systemctl is-active --quiet xray 2>/dev/null
}

nginx_running() {
    systemctl is-active --quiet nginx 2>/dev/null
}

# ── INSTALAÇÃO COMPLETA ───────────────────────────────────────
instalar_tudo() {
    header
    echo -e "${BG_BLUE}          INSTALAÇÃO COMPLETA KRATOS VPN          ${NC}\n"
    warn "Este processo vai instalar e configurar o servidor completo."
    echo -ne "\n${W}Deseja continuar? [s/N]: ${NC}"
    read -r confirm
    [[ ! "$confirm" =~ ^[sS]$ ]] && { warn "Cancelado."; return; }

    # ── Domínio ──
    sep
    echo -e "\n${C}CONFIGURAÇÃO DE DOMÍNIO${NC}\n"
    echo -ne "${W}Informe seu domínio (ex: vpn.meusite.com): ${NC}"
    read -r DOMAIN
    [[ -z "$DOMAIN" ]] && { err "Domínio inválido."; press_enter; return; }

    echo -ne "${W}Informe o email para SSL (Let's Encrypt): ${NC}"
    read -r SSL_EMAIL
    [[ -z "$SSL_EMAIL" ]] && { err "Email inválido."; press_enter; return; }

    # ── Portas ──
    echo -ne "${W}Porta SSH (padrão 22): ${NC}"
    read -r SSH_PORT
    SSH_PORT=${SSH_PORT:-22}

    echo -ne "${W}Porta Xray WebSocket (padrão 8080): ${NC}"
    read -r WS_PORT
    WS_PORT=${WS_PORT:-8080}

    sep
    info "Iniciando instalação..."
    sleep 1

    # 1. Atualizar sistema
    echo -e "\n${Y}[1/9]${NC} Atualizando sistema..."
    apt-get update -qq && apt-get upgrade -y -qq
    msg "Sistema atualizado."

    # 2. Dependências
    echo -e "${Y}[2/9]${NC} Instalando dependências..."
    apt-get install -y -qq \
        curl wget unzip jq sqlite3 \
        nginx certbot python3-certbot-nginx \
        ufw fail2ban net-tools \
        openssl qrencode bc \
        lsof cron
    msg "Dependências instaladas."

    # 3. Xray-core
    echo -e "${Y}[3/9]${NC} Instalando Xray-core..."
    instalar_xray_core
    msg "Xray-core instalado."

    # 4. Configurar SSH seguro
    echo -e "${Y}[4/9]${NC} Configurando SSH..."
    configurar_ssh "$SSH_PORT"
    msg "SSH configurado na porta $SSH_PORT."

    # 5. SSL com Certbot
    echo -e "${Y}[5/9]${NC} Obtendo certificado SSL para $DOMAIN..."
    obter_ssl "$DOMAIN" "$SSL_EMAIL"

    # 6. Nginx
    echo -e "${Y}[6/9]${NC} Configurando Nginx..."
    configurar_nginx "$DOMAIN" "$WS_PORT"
    msg "Nginx configurado."

    # 7. Xray config
    echo -e "${Y}[7/9]${NC} Gerando configuração Xray..."
    gerar_config_xray "$DOMAIN" "$WS_PORT"
    msg "Xray configurado."

    # 8. Firewall UFW
    echo -e "${Y}[8/9]${NC} Configurando firewall UFW..."
    configurar_ufw "$SSH_PORT"
    msg "Firewall configurado."

    # 9. Banco de dados + instalação do comando kratos
    echo -e "${Y}[9/9]${NC} Finalizando..."
    db_init
    db_set "domain"   "$DOMAIN"
    db_set "ssl_email" "$SSL_EMAIL"
    db_set "ssh_port" "$SSH_PORT"
    db_set "ws_port"  "$WS_PORT"
    db_set "installed" "$(date '+%Y-%m-%d %H:%M:%S')"
    instalar_comando_kratos
    configurar_fail2ban
    configurar_cron_limpeza

    systemctl restart xray nginx 2>/dev/null

    sep
    echo -e "\n${G}✔ INSTALAÇÃO CONCLUÍDA!${NC}\n"
    echo -e "  ${W}Domínio:${NC}  ${C}$DOMAIN${NC}"
    echo -e "  ${W}SSH:${NC}      ${C}$SSH_PORT${NC}"
    echo -e "  ${W}WS Port:${NC}  ${C}$WS_PORT${NC}"
    echo -e "  ${W}SSL:${NC}      ${G}Ativo${NC}"
    echo -e "\n  ${Y}Use o comando ${W}kratos${Y} para gerenciar o servidor.${NC}\n"
    db_log "INSTALL" "system" "Instalação completa - domínio: $DOMAIN"
    press_enter
}

instalar_xray_core() {
    # Busca última versão do Xray no GitHub
    XRAY_VER=$(curl -s "https://api.github.com/repos/XTLS/Xray-core/releases/latest" \
        | jq -r '.tag_name' 2>/dev/null)
    [[ -z "$XRAY_VER" ]] && XRAY_VER="v24.12.31"

    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)  XRAY_ARCH="64" ;;
        aarch64) XRAY_ARCH="arm64-v8a" ;;
        armv7*)  XRAY_ARCH="arm32-v7a" ;;
        *)        XRAY_ARCH="64" ;;
    esac

    XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VER}/Xray-linux-${XRAY_ARCH}.zip"

    wget -q "$XRAY_URL" -O /tmp/xray.zip || {
        err "Falha ao baixar Xray. Verificar conexão."
        return 1
    }

    mkdir -p /tmp/xray_extract
    unzip -q /tmp/xray.zip -d /tmp/xray_extract
    cp /tmp/xray_extract/xray "$XRAY_DIR/xray"
    chmod +x "$XRAY_DIR/xray"
    rm -rf /tmp/xray.zip /tmp/xray_extract

    mkdir -p "$XRAY_CONF" "$XRAY_LOG"

    # Serviço systemd para Xray
    cat > /etc/systemd/system/xray.service <<'SYSTEMD'
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls/xray-core
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
SYSTEMD

    systemctl daemon-reload
    systemctl enable xray --quiet
}

configurar_ssh() {
    local port="$1"
    # Backup
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.kratos

    sed -i "s/^#*Port .*/Port $port/" /etc/ssh/sshd_config
    sed -i "s/^#*MaxAuthTries .*/MaxAuthTries 3/" /etc/ssh/sshd_config
    sed -i "s/^#*LoginGraceTime .*/LoginGraceTime 30/" /etc/ssh/sshd_config

    # Permitir senha (necessário para usuários SSH VPN)
    sed -i "s/^#*PasswordAuthentication .*/PasswordAuthentication yes/" /etc/ssh/sshd_config

    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null
}

obter_ssl() {
    local domain="$1" email="$2"

    # Parar nginx temporariamente para certbot standalone
    systemctl stop nginx 2>/dev/null

    certbot certonly --standalone \
        --non-interactive \
        --agree-tos \
        --email "$email" \
        -d "$domain" \
        --quiet 2>/dev/null

    if [[ $? -eq 0 ]]; then
        msg "SSL obtido para $domain."
    else
        warn "Falha no SSL. Usando certificado autoassinado como fallback."
        mkdir -p /etc/xray/ssl
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /etc/xray/ssl/key.pem \
            -out /etc/xray/ssl/cert.pem \
            -subj "/CN=$domain" -quiet 2>/dev/null
    fi

    systemctl start nginx 2>/dev/null
}

configurar_nginx() {
    local domain="$1" ws_port="$2"

    cat > /etc/nginx/sites-available/kratos <<NGINX_CONF
# KRATOS VPN - Nginx Config
# Gerado em $(date)

server {
    listen 80;
    server_name $domain;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $domain;

    ssl_certificate     /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache   shared:SSL:10m;
    ssl_session_timeout 1d;

    # Ocultar versão do nginx
    server_tokens off;

    # Caminho padrão - página falsa
    location / {
        root /var/www/html;
        index index.html;
    }

    # VLESS WebSocket
    location /vless-ws {
        proxy_pass          http://127.0.0.1:$ws_port;
        proxy_http_version  1.1;
        proxy_set_header    Upgrade \$http_upgrade;
        proxy_set_header    Connection "upgrade";
        proxy_set_header    Host \$host;
        proxy_set_header    X-Real-IP \$remote_addr;
        proxy_read_timeout  86400;
    }

    # VMess WebSocket
    location /vmess-ws {
        proxy_pass          http://127.0.0.1:$(($ws_port + 1));
        proxy_http_version  1.1;
        proxy_set_header    Upgrade \$http_upgrade;
        proxy_set_header    Connection "upgrade";
        proxy_set_header    Host \$host;
        proxy_set_header    X-Real-IP \$remote_addr;
        proxy_read_timeout  86400;
    }

    # Trojan WebSocket
    location /trojan-ws {
        proxy_pass          http://127.0.0.1:$(($ws_port + 2));
        proxy_http_version  1.1;
        proxy_set_header    Upgrade \$http_upgrade;
        proxy_set_header    Connection "upgrade";
        proxy_set_header    Host \$host;
        proxy_set_header    X-Real-IP \$remote_addr;
        proxy_read_timeout  86400;
    }

    # SSH WebSocket (para conexão SSH over WebSocket)
    location /ssh-ws {
        proxy_pass          http://127.0.0.1:2082;
        proxy_http_version  1.1;
        proxy_set_header    Upgrade \$http_upgrade;
        proxy_set_header    Connection "upgrade";
        proxy_set_header    Host \$host;
        proxy_read_timeout  86400;
    }
}
NGINX_CONF

    ln -sf /etc/nginx/sites-available/kratos /etc/nginx/sites-enabled/kratos
    rm -f /etc/nginx/sites-enabled/default

    # Página fake para esconder o servidor
    cat > /var/www/html/index.html <<'HTML'
<!DOCTYPE html>
<html><head><title>Welcome</title></head>
<body><h1>It works!</h1></body></html>
HTML

    nginx -t -q 2>/dev/null && systemctl restart nginx
}

gerar_config_xray() {
    local domain="$1" ws_port="$2"
    local ssl_cert ssl_key

    if [[ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]]; then
        ssl_cert="/etc/letsencrypt/live/$domain/fullchain.pem"
        ssl_key="/etc/letsencrypt/live/$domain/privkey.pem"
    else
        ssl_cert="/etc/xray/ssl/cert.pem"
        ssl_key="/etc/xray/ssl/key.pem"
    fi

    # UUID padrão do admin (criado na instalação)
    ADMIN_UUID=$(gen_uuid)
    db_set "admin_uuid" "$ADMIN_UUID"

    # Gerar chaves para VLESS Reality
    REALITY_KEYS=$("$XRAY_DIR/xray" x25519 2>/dev/null)
    REALITY_PRIVATE=$(echo "$REALITY_KEYS" | grep "Private key:" | awk '{print $3}')
    REALITY_PUBLIC=$(echo "$REALITY_KEYS" | grep "Public key:"  | awk '{print $3}')
    REALITY_SHORT_ID=$(openssl rand -hex 8)
    db_set "reality_private" "$REALITY_PRIVATE"
    db_set "reality_public"  "$REALITY_PUBLIC"
    db_set "reality_shortid" "$REALITY_SHORT_ID"

    cat > "$XRAY_CONF/config.json" <<JSON
{
  "log": {
    "loglevel": "warning",
    "access": "$XRAY_LOG/access.log",
    "error":  "$XRAY_LOG/error.log"
  },
  "inbounds": [
    {
      "tag": "vless-ws-tls",
      "port": $ws_port,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [
          { "id": "$ADMIN_UUID", "flow": "", "email": "admin" }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/vless-ws" }
      },
      "sniffing": { "enabled": true, "destOverride": ["http","tls"] }
    },
    {
      "tag": "vmess-ws-tls",
      "port": $(($ws_port + 1)),
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          { "id": "$ADMIN_UUID", "alterId": 0, "email": "admin" }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/vmess-ws" }
      },
      "sniffing": { "enabled": true, "destOverride": ["http","tls"] }
    },
    {
      "tag": "trojan-ws-tls",
      "port": $(($ws_port + 2)),
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {
        "clients": [
          { "password": "$ADMIN_UUID", "email": "admin" }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/trojan-ws" }
      },
      "sniffing": { "enabled": true, "destOverride": ["http","tls"] }
    },
    {
      "tag": "vless-reality",
      "port": 8443,
      "protocol": "vless",
      "settings": {
        "clients": [
          { "id": "$ADMIN_UUID", "flow": "xtls-rprx-vision", "email": "admin" }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "www.microsoft.com:443",
          "xver": 0,
          "serverNames": ["www.microsoft.com"],
          "privateKey": "$REALITY_PRIVATE",
          "shortIds": ["$REALITY_SHORT_ID"]
        }
      },
      "sniffing": { "enabled": true, "destOverride": ["http","tls","quic"] }
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "tag": "direct" },
    { "protocol": "blackhole", "tag": "block" }
  ],
  "routing": {
    "rules": [
      { "type": "field", "ip": ["geoip:private"], "outboundTag": "direct" },
      { "type": "field", "domain": ["geosite:cn"], "outboundTag": "direct" }
    ]
  }
}
JSON
    msg "Config Xray gerada com UUID admin: $ADMIN_UUID"
}

configurar_ufw() {
    local ssh_port="$1"
    ufw --force reset -q
    ufw default deny incoming -q
    ufw default allow outgoing -q
    ufw allow "$ssh_port"/tcp comment 'SSH' -q
    ufw allow 80/tcp  comment 'HTTP' -q
    ufw allow 443/tcp comment 'HTTPS/TLS' -q
    ufw allow 8443/tcp comment 'VLESS Reality' -q
    ufw --force enable -q
}

configurar_fail2ban() {
    cat > /etc/fail2ban/jail.local <<'F2B'
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 5
backend  = auto

[sshd]
enabled  = true
port     = ssh
logpath  = %(sshd_log)s

[nginx-http-auth]
enabled  = true

[nginx-limit-req]
enabled  = true
filter   = nginx-limit-req
logpath  = /var/log/nginx/error.log
maxretry = 10
F2B
    systemctl enable fail2ban --quiet
    systemctl restart fail2ban 2>/dev/null
}

configurar_cron_limpeza() {
    # Cron para remover usuários expirados às 00:00
    CRON_CMD="0 0 * * * sqlite3 $DB \"UPDATE users SET status='expired' WHERE expires_at < datetime('now') AND status='active';\" >> $LOG_DIR/cron.log 2>&1"
    (crontab -l 2>/dev/null | grep -v "kratos"; echo "$CRON_CMD") | crontab -
    mkdir -p "$LOG_DIR"
}

instalar_comando_kratos() {
    # Baixar script do GitHub para garantir versão completa
    curl -sL "https://raw.githubusercontent.com/Thgamer79/Kratos-vps/main/kratos-setup.sh" \
        -o /usr/local/bin/kratos 2>/dev/null

    # Fallback: copiar o próprio script em execução
    if [[ ! -s /usr/local/bin/kratos ]]; then
        SCRIPT_PATH="$(realpath "$0")"
        [[ -f "$SCRIPT_PATH" ]] && cp "$SCRIPT_PATH" /usr/local/bin/kratos
    fi

    chmod +x /usr/local/bin/kratos
    msg "Comando 'kratos' instalado. Use em qualquer lugar."
}

# ── CRIAR USUÁRIO ─────────────────────────────────────────────
criar_usuario() {
    header
    echo -e "${BG_BLUE}              CRIAR NOVO USUÁRIO               ${NC}\n"
    sep

    echo -e "\n${W}Tipo de usuário:${NC}"
    echo -e "  ${C}[1]${NC} SSH"
    echo -e "  ${C}[2]${NC} VLESS WebSocket+TLS"
    echo -e "  ${C}[3]${NC} VMess WebSocket+TLS"
    echo -e "  ${C}[4]${NC} Trojan WebSocket+TLS"
    echo -e "  ${C}[5]${NC} VLESS Reality (sem domínio)"
    echo -e "  ${C}[0]${NC} Voltar"
    sep
    echo -ne "\n${W}Opção: ${NC}"
    read -r tipo_opt

    case "$tipo_opt" in
        1) TIPO="ssh";     PROTO="ssh" ;;
        2) TIPO="xray";    PROTO="vless-ws" ;;
        3) TIPO="xray";    PROTO="vmess-ws" ;;
        4) TIPO="xray";    PROTO="trojan-ws" ;;
        5) TIPO="xray";    PROTO="vless-reality" ;;
        0) return ;;
        *) err "Opção inválida."; press_enter; return ;;
    esac

    echo -ne "\n${W}Nome do usuário (3-16 chars): ${NC}"
    read -r USERNAME
    USERNAME=$(echo "$USERNAME" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_')

    if [[ ${#USERNAME} -lt 3 || ${#USERNAME} -gt 16 ]]; then
        err "Nome deve ter entre 3 e 16 caracteres."; press_enter; return
    fi

    # Verificar se já existe
    EXISTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE username='$USERNAME';")
    [[ "$EXISTS" -gt 0 ]] && { err "Usuário '$USERNAME' já existe."; press_enter; return; }

    echo -ne "${W}Senha (Enter para gerar automático): ${NC}"
    read -r PASSWORD
    [[ -z "$PASSWORD" ]] && PASSWORD=$(gen_password)

    echo -ne "${W}Dias de validade: ${NC}"
    read -r DIAS
    [[ ! "$DIAS" =~ ^[0-9]+$ ]] && { err "Dias inválido."; press_enter; return; }

    echo -ne "${W}Limite de conexões simultâneas (padrão 1): ${NC}"
    read -r LIMITE
    LIMITE=${LIMITE:-1}

    echo -ne "${W}Limite de dados em GB (0 = ilimitado): ${NC}"
    read -r DATA_LIMIT
    DATA_LIMIT=${DATA_LIMIT:-0}

    UUID=$(gen_uuid)
    EXPIRES=$(date -d "+${DIAS} days" '+%Y-%m-%d %H:%M:%S')

    # Salvar no banco
    sqlite3 "$DB" <<SQL
INSERT INTO users (username, password, uuid, type, protocol, limit_conn, data_limit, expires_at)
VALUES ('$USERNAME', '$PASSWORD', '$UUID', '$TIPO', '$PROTO', $LIMITE, $DATA_LIMIT, '$EXPIRES');
SQL

    if [[ "$TIPO" == "ssh" ]]; then
        # Criar usuário Linux
        useradd -M -s /bin/false -e "$(date -d "+${DIAS} days" '+%Y-%m-%d')" "$USERNAME" 2>/dev/null
        echo "$USERNAME:$PASSWORD" | chpasswd
    else
        # Adicionar UUID ao config do Xray
        adicionar_uuid_xray "$USERNAME" "$UUID" "$PROTO"
        systemctl restart xray 2>/dev/null
    fi

    db_log "CREATE_USER" "$USERNAME" "tipo=$PROTO dias=$DIAS"

    sep
    echo -e "\n${G}✔ Usuário criado com sucesso!${NC}\n"
    echo -e "  ${W}Usuário:   ${C}$USERNAME${NC}"
    echo -e "  ${W}Senha:     ${C}$PASSWORD${NC}"
    echo -e "  ${W}Tipo:      ${C}$PROTO${NC}"
    echo -e "  ${W}Validade:  ${C}$DIAS dias ($EXPIRES)${NC}"
    echo -e "  ${W}Conexões:  ${C}$LIMITE${NC}"

    if [[ "$TIPO" != "ssh" ]]; then
        echo -e "  ${W}UUID:      ${C}$UUID${NC}"
        echo ""
        gerar_link_conexao "$USERNAME" "$PROTO" "$UUID" "$PASSWORD"
    fi

    press_enter
}

adicionar_uuid_xray() {
    local user="$1" uuid="$2" proto="$3"
    local cfg="$XRAY_CONF/config.json"

    case "$proto" in
        vless-ws|vless-reality)
            jq --arg u "$uuid" --arg e "$user" \
               '(.inbounds[] | select(.tag == "vless-ws-tls" or .tag == "vless-reality") | .settings.clients) += [{"id": $u, "flow": "", "email": $e}]' \
               "$cfg" > /tmp/xray_tmp.json && mv /tmp/xray_tmp.json "$cfg"
            ;;
        vmess-ws)
            jq --arg u "$uuid" --arg e "$user" \
               '(.inbounds[] | select(.tag == "vmess-ws-tls") | .settings.clients) += [{"id": $u, "alterId": 0, "email": $e}]' \
               "$cfg" > /tmp/xray_tmp.json && mv /tmp/xray_tmp.json "$cfg"
            ;;
        trojan-ws)
            jq --arg p "$uuid" --arg e "$user" \
               '(.inbounds[] | select(.tag == "trojan-ws-tls") | .settings.clients) += [{"password": $p, "email": $e}]' \
               "$cfg" > /tmp/xray_tmp.json && mv /tmp/xray_tmp.json "$cfg"
            ;;
    esac
}

gerar_link_conexao() {
    local user="$1" proto="$2" uuid="$3" password="$4"
    local domain ws_port
    domain=$(db_get "domain")
    ws_port=$(db_get "ws_port")
    local reality_pub reality_sid
    reality_pub=$(db_get "reality_public")
    reality_sid=$(db_get "reality_shortid")

    sep
    echo -e "\n${Y}LINKS DE CONEXÃO:${NC}\n"

    case "$proto" in
        vless-ws)
            local link="vless://${uuid}@${domain}:443?encryption=none&security=tls&sni=${domain}&type=ws&path=%2Fvless-ws#KRATOS-${user}"
            echo -e "${W}VLESS WS+TLS:${NC}"
            echo -e "  ${C}$link${NC}"
            echo ""
            echo -e "${W}QR Code:${NC}"
            echo "$link" | qrencode -t ANSIUTF8 2>/dev/null || echo "  (instale qrencode para QR)"
            ;;
        vmess-ws)
            local vmess_json="{\"v\":\"2\",\"ps\":\"KRATOS-${user}\",\"add\":\"${domain}\",\"port\":\"443\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"${domain}\",\"path\":\"/vmess-ws\",\"tls\":\"tls\"}"
            local link="vmess://$(echo -n "$vmess_json" | base64 -w 0)"
            echo -e "${W}VMess WS+TLS:${NC}"
            echo -e "  ${C}$link${NC}"
            echo ""
            echo "$link" | qrencode -t ANSIUTF8 2>/dev/null
            ;;
        trojan-ws)
            local link="trojan://${uuid}@${domain}:443?security=tls&sni=${domain}&type=ws&path=%2Ftrojan-ws#KRATOS-${user}"
            echo -e "${W}Trojan WS+TLS:${NC}"
            echo -e "  ${C}$link${NC}"
            echo ""
            echo "$link" | qrencode -t ANSIUTF8 2>/dev/null
            ;;
        vless-reality)
            local link="vless://${uuid}@$(ip_publico):8443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.microsoft.com&fp=chrome&pbk=${reality_pub}&sid=${reality_sid}&type=tcp#KRATOS-${user}-Reality"
            echo -e "${W}VLESS Reality (sem censura):${NC}"
            echo -e "  ${C}$link${NC}"
            echo ""
            echo "$link" | qrencode -t ANSIUTF8 2>/dev/null
            ;;
    esac
}

# ── LISTAR USUÁRIOS ───────────────────────────────────────────
listar_usuarios() {
    header
    echo -e "${BG_BLUE}              USUÁRIOS CADASTRADOS              ${NC}\n"

    local total ativos expirados
    total=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users;")
    ativos=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE status='active' AND expires_at > datetime('now');")
    expirados=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE expires_at < datetime('now') OR status='expired';")

    echo -e "  ${W}Total:${NC} ${C}$total${NC}  │  ${G}Ativos: $ativos${NC}  │  ${R}Expirados: $expirados${NC}\n"
    sep

    printf "  %-16s %-14s %-12s %-10s %-20s %-8s\n" \
        "USUÁRIO" "TIPO" "PROTOCOLO" "LIMITE" "EXPIRA" "STATUS"
    sep

    sqlite3 -separator "|" "$DB" \
        "SELECT username, type, protocol, limit_conn, strftime('%d/%m/%Y',expires_at),
                CASE WHEN expires_at < datetime('now') THEN 'EXPIRADO'
                     WHEN status='active' THEN 'ATIVO'
                     ELSE upper(status) END
         FROM users ORDER BY status DESC, expires_at ASC;" | \
    while IFS="|" read -r name type proto limit exp status; do
        local color="$G"
        [[ "$status" == "EXPIRADO" ]] && color="$R"
        [[ "$status" == "SUSPENSO" ]] && color="$Y"
        printf "  ${color}%-16s${NC} %-14s %-12s %-10s %-20s ${color}%-8s${NC}\n" \
            "$name" "$type" "$proto" "$limit" "$exp" "$status"
    done

    sep
    press_enter
}

# ── DELETAR USUÁRIO ───────────────────────────────────────────
deletar_usuario() {
    header
    echo -e "${BG_RED}              DELETAR USUÁRIO               ${NC}\n"

    echo -ne "${W}Nome do usuário a deletar: ${NC}"
    read -r USERNAME

    EXISTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE username='$USERNAME';")
    [[ "$EXISTS" -eq 0 ]] && { err "Usuário '$USERNAME' não encontrado."; press_enter; return; }

    TIPO=$(sqlite3 "$DB" "SELECT type FROM users WHERE username='$USERNAME';")
    UUID=$(sqlite3 "$DB" "SELECT uuid FROM users WHERE username='$USERNAME';")
    PROTO=$(sqlite3 "$DB" "SELECT protocol FROM users WHERE username='$USERNAME';")

    echo -ne "\n${R}Confirmar exclusão de '$USERNAME'? [s/N]: ${NC}"
    read -r confirm
    [[ ! "$confirm" =~ ^[sS]$ ]] && { warn "Cancelado."; press_enter; return; }

    sqlite3 "$DB" "DELETE FROM users WHERE username='$USERNAME';"

    if [[ "$TIPO" == "ssh" ]]; then
        userdel -f "$USERNAME" 2>/dev/null
    else
        remover_uuid_xray "$UUID" "$PROTO"
        systemctl restart xray 2>/dev/null
    fi

    db_log "DELETE_USER" "$USERNAME" "tipo=$PROTO"
    msg "Usuário '$USERNAME' deletado com sucesso."
    press_enter
}

remover_uuid_xray() {
    local uuid="$1"
    local cfg="$XRAY_CONF/config.json"
    jq --arg u "$uuid" \
       '(.inbounds[].settings | if .clients then .clients |= map(select(.id != $u and .password != $u)) else . end)' \
       "$cfg" > /tmp/xray_tmp.json && mv /tmp/xray_tmp.json "$cfg"
}

# ── RENOVAR USUÁRIO ───────────────────────────────────────────
renovar_usuario() {
    header
    echo -e "${BG_BLUE}              RENOVAR USUÁRIO               ${NC}\n"

    echo -ne "${W}Nome do usuário: ${NC}"
    read -r USERNAME

    EXISTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE username='$USERNAME';")
    [[ "$EXISTS" -eq 0 ]] && { err "Usuário não encontrado."; press_enter; return; }

    echo -ne "${W}Dias a adicionar: ${NC}"
    read -r DIAS
    [[ ! "$DIAS" =~ ^[0-9]+$ ]] && { err "Valor inválido."; press_enter; return; }

    # Se já expirou, renova a partir de hoje. Se não, adiciona aos dias restantes.
    sqlite3 "$DB" <<SQL
UPDATE users
SET expires_at = datetime(
    CASE WHEN expires_at < datetime('now')
         THEN datetime('now')
         ELSE expires_at
    END, '+${DIAS} days'),
    status = 'active'
WHERE username = '$USERNAME';
SQL

    TIPO=$(sqlite3 "$DB" "SELECT type FROM users WHERE username='$USERNAME';")
    if [[ "$TIPO" == "ssh" ]]; then
        NEW_EXP=$(sqlite3 "$DB" "SELECT date(expires_at) FROM users WHERE username='$USERNAME';")
        chage -E "$NEW_EXP" "$USERNAME" 2>/dev/null
    fi

    NEW_EXP_FULL=$(sqlite3 "$DB" "SELECT expires_at FROM users WHERE username='$USERNAME';")
    db_log "RENEW_USER" "$USERNAME" "dias=$DIAS nova_exp=$NEW_EXP_FULL"

    msg "Usuário '$USERNAME' renovado por mais $DIAS dias."
    echo -e "  ${W}Nova expiração:${NC} ${C}$NEW_EXP_FULL${NC}"
    press_enter
}

# ── ONLINE / MONITOR ──────────────────────────────────────────
usuarios_online() {
    header
    echo -e "${BG_BLUE}              USUÁRIOS ONLINE               ${NC}\n"

    echo -e "${Y}SSH Online:${NC}"
    who 2>/dev/null | awk '{print "  "$1" desde "$3" "$4}' || echo "  Nenhum"
    echo ""

    echo -e "${Y}Conexões ativas (ss):${NC}"
    ss -tn state established 2>/dev/null | awk 'NR>1 {print "  "$0}' | head -20
    echo ""

    echo -e "${Y}Xray - conexões:${NC}"
    if [[ -f "$XRAY_LOG/access.log" ]]; then
        tail -20 "$XRAY_LOG/access.log" | awk '{print "  "$0}'
    else
        echo "  Log não disponível."
    fi

    press_enter
}

# ── STATUS DO SERVIDOR ────────────────────────────────────────
status_servidor() {
    header
    echo -e "${BG_BLUE}              STATUS DO SERVIDOR              ${NC}\n"

    local domain ip
    domain=$(db_get "domain" 2>/dev/null || echo "não configurado")
    ip=$(ip_publico)

    echo -e "  ${W}Domínio:${NC}  ${C}$domain${NC}"
    echo -e "  ${W}IP:${NC}       ${C}$ip${NC}"
    echo ""

    # Xray
    if xray_running; then
        echo -e "  ${G}● Xray:${NC}   RODANDO"
        XRAY_VER=$("$XRAY_DIR/xray" version 2>/dev/null | head -1 | awk '{print $2}')
        echo -e "    ${W}Versão:${NC} $XRAY_VER"
    else
        echo -e "  ${R}● Xray:${NC}   PARADO"
    fi

    # Nginx
    if nginx_running; then
        echo -e "  ${G}● Nginx:${NC}  RODANDO"
    else
        echo -e "  ${R}● Nginx:${NC}  PARADO"
    fi

    # SSL
    if [[ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]]; then
        EXP_SSL=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/$domain/fullchain.pem" 2>/dev/null \
            | cut -d= -f2)
        echo -e "  ${G}● SSL:${NC}    ATIVO (exp: $EXP_SSL)"
    else
        echo -e "  ${Y}● SSL:${NC}    Autoassinado"
    fi

    # Fail2ban
    if systemctl is-active --quiet fail2ban; then
        BANNED=$(fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $NF}')
        echo -e "  ${G}● F2ban:${NC}  ATIVO ($BANNED IPs banidos)"
    else
        echo -e "  ${R}● F2ban:${NC}  PARADO"
    fi

    echo ""
    sep
    echo -e "${Y}RECURSOS DO SISTEMA:${NC}"
    echo ""

    # CPU
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d% -f1)
    echo -e "  ${W}CPU:${NC}    ${C}${CPU}%${NC}"

    # RAM
    RAM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
    RAM_USED=$(free -m  | awk '/^Mem:/{print $3}')
    RAM_PCT=$(( RAM_USED * 100 / RAM_TOTAL ))
    echo -e "  ${W}RAM:${NC}    ${C}${RAM_USED}MB / ${RAM_TOTAL}MB (${RAM_PCT}%)${NC}"

    # Disco
    DISCO=$(df -h / | awk 'NR==2{print $3"/"$2" ("$5")"}')
    echo -e "  ${W}Disco:${NC}  ${C}$DISCO${NC}"

    # Uptime
    UPTIME=$(uptime -p 2>/dev/null || uptime)
    echo -e "  ${W}Uptime:${NC} ${C}$UPTIME${NC}"

    echo ""
    sep
    echo -e "${Y}USUÁRIOS:${NC}"
    TOTAL=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users;" 2>/dev/null || echo "0")
    ATIVOS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE status='active' AND expires_at > datetime('now');" 2>/dev/null || echo "0")
    EXPIR=$(sqlite3 "$DB"  "SELECT COUNT(*) FROM users WHERE expires_at < datetime('now');" 2>/dev/null || echo "0")
    echo -e "  ${G}Ativos:${NC}    $ATIVOS  │  ${R}Expirados:${NC} $EXPIR  │  ${W}Total:${NC} $TOTAL"

    press_enter
}

# ── VER LINK DE CONEXÃO ───────────────────────────────────────
ver_conexao_usuario() {
    header
    echo -e "${BG_BLUE}         INFORMAÇÕES DE CONEXÃO DO USUÁRIO        ${NC}\n"

    echo -ne "${W}Nome do usuário: ${NC}"
    read -r USERNAME

    local row
    row=$(sqlite3 -separator "|" "$DB" \
        "SELECT username, password, uuid, type, protocol, limit_conn, expires_at, status
         FROM users WHERE username='$USERNAME';")

    [[ -z "$row" ]] && { err "Usuário não encontrado."; press_enter; return; }

    IFS="|" read -r name pass uuid tipo proto limit exp status <<< "$row"

    sep
    echo -e "  ${W}Usuário:   ${C}$name${NC}"
    echo -e "  ${W}Senha:     ${C}$pass${NC}"
    echo -e "  ${W}Tipo:      ${C}$tipo${NC}"
    echo -e "  ${W}Protocolo: ${C}$proto${NC}"
    echo -e "  ${W}Conexões:  ${C}$limit${NC}"
    echo -e "  ${W}Expira:    ${C}$exp${NC}"
    echo -e "  ${W}Status:    $([ "$status" = "active" ] && echo "${G}ATIVO" || echo "${R}$status")${NC}"

    if [[ "$tipo" != "ssh" ]]; then
        gerar_link_conexao "$name" "$proto" "$uuid" "$pass"
    else
        local domain ssh_port ip
        domain=$(db_get "domain")
        ssh_port=$(db_get "ssh_port")
        ip=$(ip_publico)
        sep
        echo -e "\n${Y}DADOS SSH:${NC}"
        echo -e "  ${W}Host:   ${C}$ip${NC}"
        echo -e "  ${W}Porta:  ${C}$ssh_port${NC}"
        echo -e "  ${W}User:   ${C}$name${NC}"
        echo -e "  ${W}Senha:  ${C}$pass${NC}"
    fi

    press_enter
}

# ── RENOVAR SSL ───────────────────────────────────────────────
renovar_ssl() {
    header
    echo -e "${BG_BLUE}              RENOVAR CERTIFICADO SSL              ${NC}\n"
    certbot renew --quiet 2>/dev/null && {
        msg "SSL renovado com sucesso!"
        systemctl reload nginx 2>/dev/null
    } || {
        warn "Nenhum certificado precisava de renovação ou houve erro."
    }
    press_enter
}

# ── REINICIAR SERVIÇOS ────────────────────────────────────────
restart_servicos() {
    header
    echo -e "${BG_BLUE}              REINICIAR SERVIÇOS               ${NC}\n"
    echo -e "${Y}[1]${NC} Xray"
    echo -e "${Y}[2]${NC} Nginx"
    echo -e "${Y}[3]${NC} Fail2ban"
    echo -e "${Y}[4]${NC} Todos"
    echo -e "${Y}[0]${NC} Voltar"
    sep
    echo -ne "\n${W}Opção: ${NC}"
    read -r opt
    case "$opt" in
        1) systemctl restart xray    && msg "Xray reiniciado." ;;
        2) systemctl restart nginx   && msg "Nginx reiniciado." ;;
        3) systemctl restart fail2ban && msg "Fail2ban reiniciado." ;;
        4)
            systemctl restart xray nginx fail2ban
            msg "Todos os serviços reiniciados."
            ;;
        0) return ;;
    esac
    press_enter
}

# ── LIMPAR EXPIRADOS ──────────────────────────────────────────
limpar_expirados() {
    header
    echo -e "${BG_BLUE}              LIMPAR USUÁRIOS EXPIRADOS              ${NC}\n"

    EXPIRADOS=$(sqlite3 -separator "|" "$DB" \
        "SELECT username, type FROM users WHERE expires_at < datetime('now');")

    COUNT=$(echo "$EXPIRADOS" | grep -c '|' || echo 0)
    [[ "$COUNT" -eq 0 ]] && { info "Nenhum usuário expirado encontrado."; press_enter; return; }

    echo -e "${Y}Usuários que serão removidos:${NC}"
    echo "$EXPIRADOS" | while IFS="|" read -r name tipo; do
        echo -e "  ${R}✘${NC} $name ($tipo)"
    done

    echo -ne "\n${R}Confirmar remoção de $COUNT usuário(s)? [s/N]: ${NC}"
    read -r confirm
    [[ ! "$confirm" =~ ^[sS]$ ]] && { warn "Cancelado."; press_enter; return; }

    echo "$EXPIRADOS" | while IFS="|" read -r name tipo; do
        if [[ "$tipo" == "ssh" ]]; then
            userdel -f "$name" 2>/dev/null
        fi
    done

    # Remover UUIDs expirados do Xray
    sqlite3 -separator "|" "$DB" \
        "SELECT uuid, protocol FROM users WHERE expires_at < datetime('now') AND type='xray';" | \
    while IFS="|" read -r uuid proto; do
        remover_uuid_xray "$uuid" "$proto"
    done

    sqlite3 "$DB" "DELETE FROM users WHERE expires_at < datetime('now');"
    systemctl restart xray 2>/dev/null

    db_log "CLEANUP" "system" "removidos=$COUNT"
    msg "$COUNT usuário(s) expirado(s) removido(s)."
    press_enter
}

# ── ATUALIZAR XRAY ────────────────────────────────────────────
atualizar_xray() {
    header
    echo -e "${BG_BLUE}              ATUALIZAR XRAY-CORE              ${NC}\n"

    ATUAL=$("$XRAY_DIR/xray" version 2>/dev/null | head -1 | awk '{print $2}')
    NOVA=$(curl -s "https://api.github.com/repos/XTLS/Xray-core/releases/latest" \
        | jq -r '.tag_name' 2>/dev/null)

    echo -e "  ${W}Versão atual:${NC}  ${Y}$ATUAL${NC}"
    echo -e "  ${W}Versão mais nova:${NC} ${G}$NOVA${NC}\n"

    [[ "$ATUAL" == "${NOVA#v}" ]] && {
        info "Xray já está na versão mais recente."
        press_enter; return
    }

    echo -ne "${W}Atualizar agora? [s/N]: ${NC}"
    read -r confirm
    [[ ! "$confirm" =~ ^[sS]$ ]] && { warn "Cancelado."; press_enter; return; }

    systemctl stop xray 2>/dev/null
    instalar_xray_core
    systemctl start xray 2>/dev/null
    msg "Xray atualizado para $NOVA."
    press_enter
}

# ── BACKUP ────────────────────────────────────────────────────
fazer_backup() {
    header
    echo -e "${BG_BLUE}              BACKUP DO SERVIDOR              ${NC}\n"

    BKPDIR="/root/kratos_backup"
    mkdir -p "$BKPDIR"
    BKPFILE="$BKPDIR/backup_$(date '+%Y%m%d_%H%M%S').tar.gz"

    tar -czf "$BKPFILE" \
        "$KRATOS_DIR" \
        "$XRAY_CONF/config.json" \
        /etc/nginx/sites-available/kratos \
        2>/dev/null

    if [[ -f "$BKPFILE" ]]; then
        SIZE=$(du -sh "$BKPFILE" | cut -f1)
        msg "Backup criado: $BKPFILE ($SIZE)"
        db_log "BACKUP" "system" "arquivo=$BKPFILE"
    else
        err "Falha ao criar backup."
    fi
    press_enter
}

# ── DESINSTALAR ───────────────────────────────────────────────
desinstalar() {
    header
    echo -e "${BG_RED}              DESINSTALAR KRATOS VPN              ${NC}\n"
    warn "Isso removerá TUDO: Xray, configs, usuários do banco."
    echo -ne "\n${R}Digite 'CONFIRMAR' para prosseguir: ${NC}"
    read -r confirm
    [[ "$confirm" != "CONFIRMAR" ]] && { warn "Cancelado."; press_enter; return; }

    systemctl stop xray nginx fail2ban 2>/dev/null
    systemctl disable xray 2>/dev/null
    rm -f /etc/systemd/system/xray.service
    rm -f "$XRAY_DIR/xray"
    rm -rf "$XRAY_CONF"
    rm -rf "$KRATOS_DIR"
    rm -f /etc/nginx/sites-available/kratos
    rm -f /etc/nginx/sites-enabled/kratos
    rm -f /usr/local/bin/kratos
    systemctl daemon-reload
    systemctl restart nginx 2>/dev/null

    msg "Kratos VPN desinstalado."
    echo -e "\n${Y}Nginx e Fail2ban foram mantidos.${NC}"
    exit 0
}

# ── MENU PRINCIPAL ────────────────────────────────────────────
menu_principal() {
    while true; do
        header

        local DOMAIN IP XRAY_STATUS NGINX_STATUS
        DOMAIN=$(db_get "domain" 2>/dev/null || echo "Não configurado")
        IP=$(ip_publico)
        XRAY_STATUS=$(xray_running  && echo "${G}● ATIVO${NC}"  || echo "${R}● PARADO${NC}")
        NGINX_STATUS=$(nginx_running && echo "${G}● ATIVO${NC}" || echo "${R}● PARADO${NC}")

        echo -e "  ${W}IP:${NC} ${C}$IP${NC}  │  ${W}Domínio:${NC} ${C}$DOMAIN${NC}"
        echo -e "  Xray: $XRAY_STATUS  │  Nginx: $NGINX_STATUS"
        sep

        echo -e "\n  ${Y}USUÁRIOS${NC}"
        echo -e "  ${C}[1]${NC}  Criar usuário"
        echo -e "  ${C}[2]${NC}  Listar usuários"
        echo -e "  ${C}[3]${NC}  Deletar usuário"
        echo -e "  ${C}[4]${NC}  Renovar usuário"
        echo -e "  ${C}[5]${NC}  Ver link / dados de conexão"
        echo -e "  ${C}[6]${NC}  Editar usuário (senha/limites)"
        echo -e "  ${C}[7]${NC}  Suspender / Reativar usuário"
        echo -e "  ${C}[8]${NC}  Usuários online"
        echo -e "  ${C}[9]${NC}  Limpar expirados"

        echo -e "\n  ${Y}SERVIDOR${NC}"
        echo -e "  ${C}[10]${NC} Status do servidor"
        echo -e "  ${C}[11]${NC} Reiniciar serviços"

        echo -e "\n  ${Y}CONFIGURAÇÕES${NC}"
        echo -e "  ${C}[12]${NC} Configurações avançadas"

        echo -e "\n  ${C}[0]${NC}  Sair"
        sep
        echo -ne "\n${W}  ► Opção: ${NC}"
        read -r OPT

        case "$OPT" in
            1)  criar_usuario ;;
            2)  listar_usuarios ;;
            3)  deletar_usuario ;;
            4)  renovar_usuario ;;
            5)  ver_conexao_usuario ;;
            6)  editar_usuario ;;
            7)  suspender_usuario ;;
            8)  usuarios_online ;;
            9)  limpar_expirados ;;
            10) status_servidor ;;
            11) restart_servicos ;;
            12) menu_config ;;
            0)  echo -e "\n${G}Até logo!${NC}\n"; exit 0 ;;
            *)  err "Opção inválida." ; sleep 1 ;;
        esac
    done
}

# ── SUSPENDER / REATIVAR USUÁRIO ─────────────────────────────
suspender_usuario() {
    header
    echo -e "${BG_BLUE}           SUSPENDER / REATIVAR USUÁRIO           ${NC}\n"

    echo -ne "${W}Nome do usuário: ${NC}"
    read -r USERNAME

    local row
    row=$(sqlite3 -separator "|" "$DB" \
        "SELECT username, type, uuid, protocol, status FROM users WHERE username='$USERNAME';")
    [[ -z "$row" ]] && { err "Usuário não encontrado."; press_enter; return; }

    IFS="|" read -r name tipo uuid proto status <<< "$row"

    if [[ "$status" == "active" ]]; then
        echo -ne "\n${Y}Suspender '$USERNAME'? [s/N]: ${NC}"
        read -r confirm
        [[ ! "$confirm" =~ ^[sS]$ ]] && { warn "Cancelado."; press_enter; return; }

        sqlite3 "$DB" "UPDATE users SET status='suspended' WHERE username='$USERNAME';"

        if [[ "$tipo" == "ssh" ]]; then
            usermod -L "$USERNAME" 2>/dev/null
        else
            remover_uuid_xray "$uuid" "$proto"
            systemctl restart xray 2>/dev/null
        fi
        db_log "SUSPEND" "$USERNAME" ""
        warn "Usuário '$USERNAME' suspenso."
    else
        echo -ne "\n${G}Reativar '$USERNAME'? [s/N]: ${NC}"
        read -r confirm
        [[ ! "$confirm" =~ ^[sS]$ ]] && { warn "Cancelado."; press_enter; return; }

        sqlite3 "$DB" "UPDATE users SET status='active' WHERE username='$USERNAME';"

        if [[ "$tipo" == "ssh" ]]; then
            usermod -U "$USERNAME" 2>/dev/null
        else
            adicionar_uuid_xray "$name" "$uuid" "$proto"
            systemctl restart xray 2>/dev/null
        fi
        db_log "REACTIVATE" "$USERNAME" ""
        msg "Usuário '$USERNAME' reativado."
    fi
    press_enter
}

# ── ALTERAR SENHA / LIMITE ────────────────────────────────────
editar_usuario() {
    header
    echo -e "${BG_BLUE}              EDITAR USUÁRIO               ${NC}\n"

    echo -ne "${W}Nome do usuário: ${NC}"
    read -r USERNAME

    local row
    row=$(sqlite3 -separator "|" "$DB" \
        "SELECT username, password, type, limit_conn, data_limit FROM users WHERE username='$USERNAME';")
    [[ -z "$row" ]] && { err "Usuário não encontrado."; press_enter; return; }

    IFS="|" read -r name pass tipo limit_conn data_limit <<< "$row"

    echo -e "\n  ${W}[1]${NC} Alterar senha        (atual: ${C}$pass${NC})"
    echo -e "  ${W}[2]${NC} Alterar limite de conexões (atual: ${C}$limit_conn${NC})"
    echo -e "  ${W}[3]${NC} Alterar limite de dados GB (atual: ${C}$data_limit GB${NC})"
    echo -e "  ${W}[0]${NC} Voltar"
    sep
    echo -ne "\n${W}Opção: ${NC}"
    read -r opt

    case "$opt" in
        1)
            echo -ne "${W}Nova senha (Enter = gerar): ${NC}"
            read -r newpass
            [[ -z "$newpass" ]] && newpass=$(gen_password)
            sqlite3 "$DB" "UPDATE users SET password='$newpass' WHERE username='$USERNAME';"
            [[ "$tipo" == "ssh" ]] && echo "$USERNAME:$newpass" | chpasswd
            db_log "EDIT_PASS" "$USERNAME" ""
            msg "Senha alterada para: $newpass"
            ;;
        2)
            echo -ne "${W}Novo limite de conexões: ${NC}"
            read -r newlimit
            [[ "$newlimit" =~ ^[0-9]+$ ]] && {
                sqlite3 "$DB" "UPDATE users SET limit_conn=$newlimit WHERE username='$USERNAME';"
                msg "Limite atualizado para $newlimit conexões."
            } || err "Valor inválido."
            ;;
        3)
            echo -ne "${W}Novo limite de dados em GB (0=ilimitado): ${NC}"
            read -r newdata
            [[ "$newdata" =~ ^[0-9]+$ ]] && {
                sqlite3 "$DB" "UPDATE users SET data_limit=$newdata WHERE username='$USERNAME';"
                msg "Limite de dados: ${newdata}GB."
            } || err "Valor inválido."
            ;;
        0) return ;;
    esac
    press_enter
}

# ── INSTALAR SSH OVER WEBSOCKET ───────────────────────────────
instalar_ssh_ws() {
    header
    echo -e "${BG_BLUE}        INSTALAR SSH OVER WEBSOCKET (porta 443)       ${NC}\n"
    info "Permite conexão SSH pelo caminho /ssh-ws via HTTPS (porta 443)."
    info "Usado em apps como HTTP Custom, HTTP Injector, etc."
    echo ""
    echo -ne "${W}Instalar? [s/N]: ${NC}"
    read -r confirm
    [[ ! "$confirm" =~ ^[sS]$ ]] && { warn "Cancelado."; press_enter; return; }

    # Instalar websockify via pip3
    apt-get install -y -qq python3-pip 2>/dev/null
    pip3 install websockify -q 2>/dev/null

    local SSH_PORT
    SSH_PORT=$(db_get "ssh_port")
    [[ -z "$SSH_PORT" ]] && SSH_PORT=22

    # Serviço systemd para SSH WebSocket
    cat > /etc/systemd/system/ssh-ws.service <<SSHWS
[Unit]
Description=SSH over WebSocket
After=network.target

[Service]
ExecStart=/usr/local/bin/websockify --web /var/www/html 2082 127.0.0.1:${SSH_PORT}
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SSHWS

    systemctl daemon-reload
    systemctl enable ssh-ws --quiet
    systemctl restart ssh-ws

    db_log "INSTALL_SSH_WS" "system" "porta_ws=2082->$SSH_PORT"
    msg "SSH WebSocket instalado e rodando na porta 2082 (exposto em /ssh-ws via Nginx)."
    press_enter
}

# ── EXPORTAR CONFIG PARA APP ──────────────────────────────────
exportar_config_app() {
    header
    echo -e "${BG_BLUE}          EXPORTAR CONFIGURAÇÃO PARA APP          ${NC}\n"
    info "Gera um JSON com todos os servidores/protocolos disponíveis."
    info "O app Android usa esse endpoint para sincronizar os servidores."
    echo ""

    local domain ip ws_port ssh_port reality_pub reality_sid
    domain=$(db_get "domain")
    ip=$(ip_publico)
    ws_port=$(db_get "ws_port")
    ssh_port=$(db_get "ssh_port")
    reality_pub=$(db_get "reality_public")
    reality_sid=$(db_get "reality_shortid")

    local OUT="/var/www/html/config.json"

    cat > "$OUT" <<JSON
{
  "version": "2.0",
  "updated": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "servers": [
    {
      "name": "KRATOS BR-01",
      "host": "$domain",
      "ip": "$ip",
      "flag": "BR",
      "protocols": [
        {
          "type": "vless-ws-tls",
          "label": "VLESS WS+TLS",
          "host": "$domain",
          "port": 443,
          "path": "/vless-ws",
          "tls": true,
          "sni": "$domain"
        },
        {
          "type": "vmess-ws-tls",
          "label": "VMess WS+TLS",
          "host": "$domain",
          "port": 443,
          "path": "/vmess-ws",
          "tls": true,
          "sni": "$domain"
        },
        {
          "type": "trojan-ws-tls",
          "label": "Trojan WS+TLS",
          "host": "$domain",
          "port": 443,
          "path": "/trojan-ws",
          "tls": true,
          "sni": "$domain"
        },
        {
          "type": "vless-reality",
          "label": "VLESS Reality",
          "host": "$ip",
          "port": 8443,
          "publicKey": "$reality_pub",
          "shortId": "$reality_sid",
          "sni": "www.microsoft.com",
          "fingerprint": "chrome",
          "flow": "xtls-rprx-vision"
        },
        {
          "type": "ssh-ws",
          "label": "SSH WebSocket",
          "host": "$domain",
          "port": 443,
          "path": "/ssh-ws",
          "ssh_port": $ssh_port,
          "tls": true
        }
      ]
    }
  ]
}
JSON

    msg "Config exportada para: $OUT"
    echo -e "  ${W}URL pública:${NC} ${C}https://$domain/config.json${NC}"
    echo -e "\n  ${Y}O app Android vai apontar para essa URL para sincronizar.${NC}"
    press_enter
}

# ── LOGS DO SISTEMA ───────────────────────────────────────────
ver_logs() {
    header
    echo -e "${BG_BLUE}                  LOGS DO SISTEMA                  ${NC}\n"

    echo -e "${Y}[1]${NC} Logs de ações (Kratos)"
    echo -e "${Y}[2]${NC} Log de acesso Xray"
    echo -e "${Y}[3]${NC} Log de erros Xray"
    echo -e "${Y}[4]${NC} Log Nginx"
    echo -e "${Y}[0]${NC} Voltar"
    sep
    echo -ne "\n${W}Opção: ${NC}"
    read -r opt

    case "$opt" in
        1)
            echo -e "\n${Y}Últimas 30 ações:${NC}\n"
            sqlite3 "$DB" \
                "SELECT datetime(created_at,'localtime'), action, target, details
                 FROM logs ORDER BY id DESC LIMIT 30;" | \
            while IFS="|" read -r dt act tgt det; do
                echo -e "  ${C}[$dt]${NC} ${W}$act${NC} → $tgt ${Y}$det${NC}"
            done
            ;;
        2) [[ -f "$XRAY_LOG/access.log" ]] && tail -50 "$XRAY_LOG/access.log" || echo "Sem log." ;;
        3) [[ -f "$XRAY_LOG/error.log"  ]] && tail -50 "$XRAY_LOG/error.log"  || echo "Sem log." ;;
        4) [[ -f /var/log/nginx/access.log ]] && tail -50 /var/log/nginx/access.log || echo "Sem log." ;;
        0) return ;;
    esac

    press_enter
}

# ── MENU CONFIGURAÇÕES ────────────────────────────────────────
menu_config() {
    while true; do
        header
        echo -e "${BG_BLUE}              CONFIGURAÇÕES              ${NC}\n"
        echo -e "  ${C}[1]${NC} Instalar SSH over WebSocket"
        echo -e "  ${C}[2]${NC} Exportar config para App Android"
        echo -e "  ${C}[3]${NC} Renovar SSL"
        echo -e "  ${C}[4]${NC} Atualizar Xray-core"
        echo -e "  ${C}[5]${NC} Fazer backup"
        echo -e "  ${C}[6]${NC} Ver logs"
        echo -e "  ${C}[7]${NC} Desinstalar"
        echo -e "  ${C}[0]${NC} Voltar"
        sep
        echo -ne "\n${W}  ► Opção: ${NC}"
        read -r opt
        case "$opt" in
            1) instalar_ssh_ws ;;
            2) exportar_config_app ;;
            3) renovar_ssl ;;
            4) atualizar_xray ;;
            5) fazer_backup ;;
            6) ver_logs ;;
            7) desinstalar ;;
            0) return ;;
            *) err "Inválido."; sleep 1 ;;
        esac
    done
}

# ── PONTO DE ENTRADA ──────────────────────────────────────────
detect_os

# Se banco/instalação existir, vai pro menu. Se não, oferece instalar.
if [[ ! -f "$DB" ]]; then
    header
    echo -e "  ${Y}Kratos VPN não está instalado neste servidor.${NC}\n"
    echo -e "  ${C}[1]${NC} Instalar agora"
    echo -e "  ${C}[0]${NC} Sair"
    sep
    echo -ne "\n${W}  ► Opção: ${NC}"
    read -r opt
    case "$opt" in
        1) instalar_tudo ;;
        *) exit 0 ;;
    esac
fi

menu_principal
