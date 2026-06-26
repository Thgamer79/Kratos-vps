# ⚡ KRATOS-SSH Manager

```
██╗  ██╗██████╗  █████╗ ████████╗ ██████╗ ███████╗
██║ ██╔╝██╔══██╗██╔══██╗╚══██╔══╝██╔═══██╗██╔════╝
█████╔╝ ██████╔╝███████║   ██║   ██║   ██║███████╗
██╔═██╗ ██╔══██╗██╔══██║   ██║   ██║   ██║╚════██║
██║  ██╗██║  ██║██║  ██║   ██║   ╚██████╔╝███████║
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝  ╚═╝    ╚═════╝ ╚══════╝
              S S H   M A N A G E R
```

> Sistema profissional de gerenciamento SSH com tema Kratos (God of War).  
> Vermelho | Preto | Branco — Visual forte, terminal moderno.

---

## 🚀 Instalação Rápida

```bash
curl -sO https://raw.githubusercontent.com/Thgamer79/Kratos-vps/refs/heads/main/kratosSSHplus.sh && chmod +x kratosSSHplus.sh && bash kratosSSHplus.sh instalar
```

## 📌 Compatibilidade

| Sistema          | Versão         |
|------------------|----------------|
| Ubuntu           | 18.04 / 20.04 / 22.04 / 24.04 |
| Debian           | 10 / 11        |

---

## ✅ Funcionalidades

| Módulo                  | Status  |
|-------------------------|---------|
| Gerenciador de Usuários | ✅ |
| Monitor Online (SSH)    | ✅ |
| OpenSSH (portas)        | ✅ |
| Dropbear                | ✅ |
| Squid Proxy             | ✅ |
| BadVPN (UDP GW)         | ✅ |
| SlowDNS Tunnel          | ✅ |
| WebSocket Security      | ✅ |
| Proxy HTTP/SOCKS        | ✅ |
| SSL Tunnel (stunnel4)   | ✅ |
| SSLH Multiplex          | ✅ |
| OpenVPN                 | ✅ |
| Bot SSH Telegram        | ✅ |
| SpeedTest               | ✅ |
| Backup de Usuários      | ✅ |
| Limiter de Conexões     | ✅ |
| Block Torrent           | ✅ |
| Otimizador de RAM       | ✅ |
| Banner SSH Personalizado| ✅ |

---

## 🎨 Banner SSH Padrão

```
╔══════════════════════════════╗
║         KRATOS-SSH          ║
║    Sistema Premium SSH      ║
║      Acesso Autorizado      ║
╚══════════════════════════════╝
```

---

## 📂 Estrutura do Sistema

```
/etc/kratos-ssh/
├── proxy.py          ← Proxy HTTP/SOCKS
├── wsproxy.py        ← WebSocket Security
├── open.py           ← Proxy OpenVPN
├── senha/            ← Senhas dos usuários
├── userteste/        ← Usuários temporários
├── backups/          ← Backups do sistema
├── dns/              ← Configurações SlowDNS
│   ├── dns-server
│   ├── server.key
│   ├── server.pub
│   └── autodns
└── Exp               ← Contador de expirados

/etc/IP               ← IP público do servidor
/etc/bannerssh        ← Banner do SSH
/etc/autostart        ← Serviços de autostart
/root/usuarios.db     ← Base de usuários
/bin/menu             ← Atalho do painel
```

---

## 🛠 Uso

```bash
# Abrir painel
menu

# Instalação completa
bash kratosSSHplus.sh instalar

# Aplicar banner padrão
bash kratosSSHplus.sh banner_padrao

# Limpeza de usuários expirados (cron)
bash kratosSSHplus.sh expcleaner_auto
```

---

## 🔐 Diretórios Compatíveis

Para retrocompatibilidade, o KRATOS-SSH cria um link simbólico:

```
/etc/SSHPlus → /etc/kratos-ssh
```

Scripts antigos que referenciam `/etc/SSHPlus` continuam funcionando.

---

## ⚡ Créditos

**KRATOS-SSH Manager** — Sistema Profissional SSH  
Versão 1.0.0 — Tema God of War

---

> *"Fecha os teus olhos e lembra do que és."* — Kratos
