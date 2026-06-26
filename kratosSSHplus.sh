#!/bin/bash
#====================================================================
#   ██╗  ██╗██████╗  █████╗ ████████╗ ██████╗ ███████╗
#   ██║ ██╔╝██╔══██╗██╔══██╗╚══██╔══╝██╔═══██╗██╔════╝
#   █████╔╝ ██████╔╝███████║   ██║   ██║   ██║███████╗
#   ██╔═██╗ ██╔══██╗██╔══██║   ██║   ██║   ██║╚════██║
#   ██║  ██╗██║  ██║██║  ██║   ██║   ╚██████╔╝███████║
#   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝  ╚═╝    ╚═════╝ ╚══════╝
#                   S S H   M A N A G E R
#====================================================================
#   SISTEMA    : KRATOS-SSH Manager
#   VERSAO     : 1.0.0
#   CRIADO EM  : 2025
#   REPOSITORIO: https://github.com/
#   SUPORTE    : Ubuntu 18.04 | 20.04 | 22.04 | 24.04
#                Debian 10 | 11
#====================================================================

# ============================================================
# VARIAVEIS GLOBAIS DE IDENTIDADE
# ============================================================
KRATOS_NAME="KRATOS-SSH"
KRATOS_VERSION="1.0.0"
KRATOS_DIR="/etc/kratos-ssh"
KRATOS_SENHA_DIR="/etc/kratos-ssh/senha"
KRATOS_DNS_DIR="/etc/kratos-ssh/dns"
KRATOS_DB="/root/usuarios.db"
KRATOS_AUTOSTART="/etc/autostart"

# ============================================================
# CORES - TEMA KRATOS (Vermelho | Branco | Preto)
# ============================================================
RED='\033[1;31m'
WHITE='\033[1;37m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
BLUE='\033[0;34m'
RESET='\033[0m'
BG_RED='\033[41;1;37m'
BG_BLUE='\033[44;1;37m'
BG_GREEN='\033[42;1;37m'
LINE='\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m'

# ============================================================
# BANNER PADRAO KRATOS-SSH
# ============================================================
kratos_banner_ssh() {
cat > /etc/bannerssh << 'BANNER_EOF'
╔══════════════════════════════╗
║         KRATOS-SSH          ║
║    Sistema Premium SSH      ║
║      Acesso Autorizado      ║
╚══════════════════════════════╝
BANNER_EOF
}

# ============================================================
# CABECALHO PADRAO DOS MENUS
# ============================================================
kratos_header() {
    local titulo="${1:-KRATOS-SSH}"
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════${RESET}"
    echo -e "${BG_RED}            ⚡  ${titulo}  ⚡             ${RESET}"
    echo -e "${BLUE}══════════════════════════════════════════════════${RESET}"
}

kratos_line() {
    echo -e "${LINE}"
}

# ============================================================
# FUNCAO DE PROGRESSO (BARRA DE CARREGAMENTO)
# ============================================================
fun_bar() {
    comando[0]="$1"
    comando[1]="${2:-sleep 1}"
    (
        [[ -e $HOME/fim ]] && rm $HOME/fim
        [[ ! -d $KRATOS_DIR ]] && rm -rf /bin/menu
        ${comando[0]} > /dev/null 2>&1
        ${comando[1]} > /dev/null 2>&1
        touch $HOME/fim
    ) > /dev/null 2>&1 &
    tput civis
    echo -ne "  ${YELLOW}[KRATOS-SSH] ${WHITE}Processando ${YELLOW}[${RESET}"
    while true; do
        for ((i=0; i<18; i++)); do
            echo -ne "${RED}#"
            sleep 0.1s
        done
        [[ -e $HOME/fim ]] && rm $HOME/fim && break
        echo -e "${YELLOW}]"
        sleep 1s
        tput cuu1
        tput dl1
        echo -ne "  ${YELLOW}[KRATOS-SSH] ${WHITE}Processando ${YELLOW}[${RESET}"
    done
    echo -e "${YELLOW}]${WHITE} -${GREEN} OK !${WHITE}"
    tput cnorm
}

fun_prog() {
    comando[0]="$1"
    ${comando[0]} > /dev/null 2>&1 &
    tput civis
    echo -ne "${GREEN}.${YELLOW}.${RED}. ${GREEN}"
    while [ -d /proc/$! ]; do
        for i in / - \\ \|; do
            sleep .1
            echo -ne "\e[1D$i"
        done
    done
    tput cnorm
    echo -e "\e[1DOK"
}

# ============================================================
# SISTEMA - INFO
# ============================================================
kratos_get_system() {
    if [[ "$(grep -c "Ubuntu" /etc/issue.net)" = "1" ]]; then
        system=$(cut -d' ' -f1 /etc/issue.net)
        system+=" "
        system+=$(cut -d' ' -f2 /etc/issue.net | awk -F "." '{print $1}')
    elif [[ "$(grep -c "Debian" /etc/issue.net)" = "1" ]]; then
        system=$(cut -d' ' -f1 /etc/issue.net)
        system+=" "
        system+=$(cut -d' ' -f3 /etc/issue.net)
    else
        system=$(cut -d' ' -f1 /etc/issue.net)
    fi
    echo "$system"
}

# ============================================================
# INSTALACAO DO KRATOS-SSH
# ============================================================
kratos_instalar() {
    clear
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════╗${RESET}"
    echo -e "${RED}║${WHITE}          INSTALADOR KRATOS-SSH v${KRATOS_VERSION}           ${RED}║${RESET}"
    echo -e "${RED}║${YELLOW}        Sistema Profissional SSH Manager         ${RED}║${RESET}"
    echo -e "${RED}╚══════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${YELLOW}[KRATOS-SSH]${WHITE} Verificando sistema..."

    # Verificar root
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "${RED}[ERRO]${WHITE} Execute como root!${RESET}"
        exit 1
    fi

    # Verificar sistema operacional
    if [[ ! -e /etc/debian_version ]]; then
        echo -e "${RED}[ERRO]${WHITE} Sistema não suportado. Use Ubuntu/Debian.${RESET}"
        exit 1
    fi

    echo -e "${YELLOW}[KRATOS-SSH]${WHITE} Instalando dependências..."
    fun_bar 'apt-get update -y' 'apt-get install -y wget curl screen python3 net-tools nload figlet speedtest-cli at'

    echo -e "${YELLOW}[KRATOS-SSH]${WHITE} Configurando diretórios..."
    kratos_setup_dirs

    echo -e "${YELLOW}[KRATOS-SSH]${WHITE} Configurando serviços..."
    kratos_setup_ssh
    kratos_setup_banner
    kratos_setup_autostart
    kratos_install_scripts
    kratos_setup_cron

    echo -e "${YELLOW}[KRATOS-SSH]${WHITE} Configurando IP do servidor..."
    IP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || curl -s ipv4.icanhazip.com)
    echo "$IP" > /etc/IP

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}║${WHITE}       KRATOS-SSH INSTALADO COM SUCESSO!         ${GREEN}║${RESET}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${YELLOW}  Digite ${GREEN}menu${YELLOW} para acessar o painel KRATOS-SSH${RESET}"
    echo ""
    sleep 2
    menu
}

# ============================================================
# CONFIGURAR DIRETORIOS
# ============================================================
kratos_setup_dirs() {
    mkdir -p $KRATOS_DIR
    mkdir -p $KRATOS_SENHA_DIR
    mkdir -p $KRATOS_DNS_DIR
    mkdir -p /etc/kratos-ssh/userteste
    mkdir -p /etc/kratos-ssh/backups
    [[ ! -f $KRATOS_DB ]] && touch $KRATOS_DB
    touch $KRATOS_DIR/Exp
    # Compatibilidade com caminhos antigos (KRATOS-SSH -> KRATOS-SSH)
    [[ -d /etc/kratos-ssh ]] && {
        cp -n /etc/kratos-ssh/senha/* $KRATOS_SENHA_DIR/ 2>/dev/null
    }
    # Links de compatibilidade
    [[ ! -L /etc/kratos-ssh ]] && {
        [[ ! -d /etc/kratos-ssh ]] && ln -s $KRATOS_DIR /etc/kratos-ssh 2>/dev/null
    }
}

# ============================================================
# CONFIGURAR SSH
# ============================================================
kratos_setup_ssh() {
    # Garantir /bin/false nos shells
    [[ $(grep -c "/bin/false" /etc/shells) = '0' ]] && echo "/bin/false" >> /etc/shells
    service ssh restart > /dev/null 2>&1
}

# ============================================================
# CONFIGURAR BANNER SSH PADRAO
# ============================================================
kratos_setup_banner() {
    kratos_banner_ssh
    # Ativar banner no SSH
    [[ $(grep -c "Banner" /etc/ssh/sshd_config) = '0' ]] && \
        echo "Banner /etc/bannerssh" >> /etc/ssh/sshd_config
    # Ativar no Dropbear (se instalado)
    [[ -e /etc/default/dropbear ]] && {
        [[ $(grep -c "DROPBEAR_BANNER" /etc/default/dropbear) = '0' ]] && \
            echo 'DROPBEAR_BANNER="/etc/bannerssh"' >> /etc/default/dropbear
    }
    service ssh restart > /dev/null 2>&1
}

# ============================================================
# CONFIGURAR AUTOSTART
# ============================================================
kratos_setup_autostart() {
    [[ ! -f $KRATOS_AUTOSTART ]] && touch $KRATOS_AUTOSTART
    chmod +x $KRATOS_AUTOSTART
    # Adicionar ao rc.local se não estiver
    if [[ -f /etc/rc.local ]]; then
        [[ $(grep -c "autostart" /etc/rc.local) = '0' ]] && \
            sed -i '$ i\bash /etc/autostart' /etc/rc.local
    fi
}

# ============================================================
# INSTALAR SCRIPTS NO /BIN
# ============================================================
kratos_install_scripts() {
    # Criar script principal de menu
    cp "$0" /bin/menu 2>/dev/null || {
        echo "#!/bin/bash" > /bin/menu
        echo "bash $0 menu \"\$@\"" >> /bin/menu
    }
    chmod +x /bin/menu

    # Criar marcadores de versão e licença
    echo "$KRATOS_VERSION" > /bin/versao
    echo "$KRATOS_VERSION" > /usr/lib/kratos-ssh
    echo "KRATOS-SSH @KRATOS" > /usr/lib/licence
    echo "KRATOS @KRATOS" >> /usr/lib/licence

    # Copiar arquivos Python (proxy/websocket)
    kratos_install_python_scripts
}

# ============================================================
# INSTALAR SCRIPTS PYTHON (WEBSOCKET / PROXY)
# ============================================================
kratos_install_python_scripts() {
    # wsproxy.py - WebSocket Security
    cat > $KRATOS_DIR/wsproxy.py << 'WSPROXY_EOF'
#!/usr/bin/env python
# encoding: utf-8
# KRATOS-SSH - WebSocket Security Proxy
import socket, threading, thread, select, signal, sys, time, getopt

PASS = ''
LISTENING_ADDR = '0.0.0.0'
try:
    LISTENING_PORT = int(sys.argv[1])
except:
    LISTENING_PORT = 80
BUFLEN = 4096 * 4
TIMEOUT = 60
MSG = 'KRATOS-SSH'
COR = '<font color="red">'
FTAG = '</font>'
DEFAULT_HOST = "127.0.0.1:22"
RESPONSE = "HTTP/1.1 101 " + str(COR) + str(MSG) + str(FTAG) + "\r\n\r\n"

class Server(threading.Thread):
    def __init__(self, host, port):
        threading.Thread.__init__(self)
        self.running = False
        self.host = host
        self.port = port
        self.threads = []
        self.threadsLock = threading.Lock()
        self.logLock = threading.Lock()

    def run(self):
        self.soc = socket.socket(socket.AF_INET)
        self.soc.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.soc.settimeout(2)
        self.soc.bind((self.host, self.port))
        self.soc.listen(0)
        self.running = True
        try:
            while self.running:
                try:
                    c, addr = self.soc.accept()
                    c.setblocking(1)
                except socket.timeout:
                    continue
                conn = ConnectionHandler(c, self, addr)
                conn.start()
                self.addConn(conn)
        finally:
            self.running = False
            self.soc.close()

    def printLog(self, log):
        self.logLock.acquire()
        print log
        self.logLock.release()

    def addConn(self, conn):
        try:
            self.threadsLock.acquire()
            if self.running:
                self.threads.append(conn)
        finally:
            self.threadsLock.release()

    def removeConn(self, conn):
        try:
            self.threadsLock.acquire()
            self.threads.remove(conn)
        finally:
            self.threadsLock.release()

    def close(self):
        try:
            self.running = False
            self.threadsLock.acquire()
            threads = list(self.threads)
            for c in threads:
                c.close()
        finally:
            self.threadsLock.release()

class ConnectionHandler(threading.Thread):
    def __init__(self, socClient, server, addr):
        threading.Thread.__init__(self)
        self.clientClosed = False
        self.targetClosed = True
        self.client = socClient
        self.client_buffer = ''
        self.server = server
        self.log = 'KRATOS-SSH Connection: ' + str(addr)

    def close(self):
        try:
            if not self.clientClosed:
                self.client.shutdown(socket.SHUT_RDWR)
                self.client.close()
        except:
            pass
        finally:
            self.clientClosed = True
        try:
            if not self.targetClosed:
                self.target.shutdown(socket.SHUT_RDWR)
                self.target.close()
        except:
            pass
        finally:
            self.targetClosed = True

    def run(self):
        try:
            self.client_buffer = self.client.recv(BUFLEN)
            hostPort = self.findHeader(self.client_buffer, 'X-Real-Host')
            if hostPort == '':
                hostPort = DEFAULT_HOST
            split = self.findHeader(self.client_buffer, 'X-Split')
            if split != '':
                self.client.recv(BUFLEN)
            if hostPort != '':
                passwd = self.findHeader(self.client_buffer, 'X-Pass')
                if len(PASS) != 0 and passwd == PASS:
                    self.methods(hostPort)
                elif len(PASS) != 0 and passwd != PASS:
                    self.client.send('HTTP/1.1 400 WrongPass!\r\n\r\n')
                elif hostPort.startswith('127.0.0.1') or hostPort.startswith(LISTENING_ADDR):
                    self.methods(hostPort)
                else:
                    self.methods(hostPort)
            else:
                print '- No X-Real-Host!'
                self.client.send('HTTP/1.1 400 NoXRealHost!\r\n\r\n')
        except Exception as e:
            self.server.printLog('ConnectionHandler: ' + str(e))
            pass
        finally:
            self.close()

    def findHeader(self, head, header):
        aux = head.find(header + ': ')
        if aux == -1:
            return ''
        aux = head.find(':', aux)
        head = head[aux+2:]
        aux = head.find('\r\n')
        if aux == -1:
            return ''
        return head[:aux]

    def connect(self, hostPort):
        host, port = hostPort.split(':')
        self.target = socket.create_connection((host, int(port)))
        self.targetClosed = False

    def methods(self, hostPort):
        self.connect(hostPort)
        self.client.send(RESPONSE)
        self.client_buffer = ''
        self.server.printLog(self.log)
        self.forward()

    def forward(self):
        socs = [self.client, self.target]
        count = 0
        error = False
        while True:
            count += 1
            (recv, _, erro) = select.select(socs, [], socs, 3)
            if error:
                break
            for in_ in recv:
                try:
                    data = in_.recv(BUFLEN)
                    if len(data) == 0:
                        break
                    if in_ is self.target:
                        self.client.send(data)
                    else:
                        while data:
                            byte = self.target.send(data)
                            data = data[byte:]
                except:
                    error = True
                    break
            for err in erro:
                error = True
                break

def main(host=LISTENING_ADDR, port=LISTENING_PORT):
    print("\n\033[1;31m╔══════════════════════════════╗\033[0m")
    print("\033[1;31m║\033[1;37m       KRATOS-SSH WS         \033[1;31m║\033[0m")
    print("\033[1;31m║\033[1;33m  WebSocket Security Proxy   \033[1;31m║\033[0m")
    print("\033[1;31m╚══════════════════════════════╝\033[0m")
    print('\n\033[1;32mPorta\033[1;37m: ' + str(port))
    print('\033[1;32mStatus\033[1;37m: Online\n')
    server = Server(host, port)
    server.start()
    try:
        while True:
            time.sleep(2)
    except KeyboardInterrupt:
        print('\n\033[1;31mKRATOS-SSH WS: Encerrando...\033[0m')
        server.close()

main()
WSPROXY_EOF

    # proxy.py - Proxy HTTP/SOCKS
    cat > $KRATOS_DIR/proxy.py << 'PROXY_EOF'
#!/usr/bin/env python3
# encoding: utf-8
# KRATOS-SSH - Proxy HTTP/SOCKS
import socket, threading, select, signal, sys, time
from os import system
system("clear")

IP = '0.0.0.0'
try:
    PORT = int(sys.argv[1])
except:
    PORT = 80
PASS = ''
BUFLEN = 8196 * 8
TIMEOUT = 60
MSG = 'KRATOS-SSH'
COR = '<font color="red">'
FTAG = '</font>'
DEFAULT_HOST = '0.0.0.0:22'
RESPONSE = "HTTP/1.1 200 " + str(COR) + str(MSG) + str(FTAG) + "\r\n\r\n"

class Server(threading.Thread):
    def __init__(self, host, port):
        threading.Thread.__init__(self)
        self.running = False
        self.host = host
        self.port = port
        self.threads = []
        self.threadsLock = threading.Lock()
        self.logLock = threading.Lock()

    def run(self):
        self.soc = socket.socket(socket.AF_INET)
        self.soc.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.soc.settimeout(2)
        self.soc.bind((self.host, self.port))
        self.soc.listen(0)
        self.running = True
        try:
            while self.running:
                try:
                    c, addr = self.soc.accept()
                    c.setblocking(1)
                except socket.timeout:
                    continue
                conn = ConnectionHandler(c, self, addr)
                conn.start()
                self.addConn(conn)
        finally:
            self.running = False
            self.soc.close()

    def printLog(self, log):
        self.logLock.acquire()
        print(log)
        self.logLock.release()

    def addConn(self, conn):
        try:
            self.threadsLock.acquire()
            if self.running:
                self.threads.append(conn)
        finally:
            self.threadsLock.release()

    def removeConn(self, conn):
        try:
            self.threadsLock.acquire()
            self.threads.remove(conn)
        finally:
            self.threadsLock.release()

    def close(self):
        try:
            self.running = False
            self.threadsLock.acquire()
            threads = list(self.threads)
            for c in threads:
                c.close()
        finally:
            self.threadsLock.release()

class ConnectionHandler(threading.Thread):
    def __init__(self, socClient, server, addr):
        threading.Thread.__init__(self)
        self.clientClosed = False
        self.targetClosed = True
        self.client = socClient
        self.client_buffer = ''
        self.server = server
        self.log = 'KRATOS Connection: ' + str(addr)

    def close(self):
        try:
            if not self.clientClosed:
                self.client.shutdown(socket.SHUT_RDWR)
                self.client.close()
        except:
            pass
        finally:
            self.clientClosed = True
        try:
            if not self.targetClosed:
                self.target.shutdown(socket.SHUT_RDWR)
                self.target.close()
        except:
            pass
        finally:
            self.targetClosed = True

    def run(self):
        try:
            self.client_buffer = self.client.recv(BUFLEN)
            hostPort = self.findHeader(self.client_buffer, 'X-Real-Host')
            if hostPort == '':
                hostPort = DEFAULT_HOST
            if hostPort != '':
                passwd = self.findHeader(self.client_buffer, 'X-Pass')
                if len(PASS) != 0 and passwd == PASS:
                    self.methods(hostPort)
                elif len(PASS) != 0 and passwd != PASS:
                    self.client.send(b'HTTP/1.1 400 WrongPass!\r\n\r\n')
                else:
                    self.methods(hostPort)
            else:
                self.client.send(b'HTTP/1.1 400 NoHost!\r\n\r\n')
        except Exception as e:
            self.server.printLog('ConnectionHandler: ' + str(e))
        finally:
            self.close()

    def findHeader(self, head, header):
        if isinstance(head, bytes):
            head = head.decode('utf-8', errors='ignore')
        aux = head.find(header + ': ')
        if aux == -1:
            return ''
        aux = head.find(':', aux)
        head = head[aux+2:]
        aux = head.find('\r\n')
        if aux == -1:
            return ''
        return head[:aux]

    def connect(self, hostPort):
        host, port = hostPort.split(':')
        self.target = socket.create_connection((host, int(port)))
        self.targetClosed = False

    def methods(self, hostPort):
        self.connect(hostPort)
        self.client.send(RESPONSE.encode())
        self.client_buffer = ''
        self.server.printLog(self.log)
        self.forward()

    def forward(self):
        socs = [self.client, self.target]
        error = False
        while True:
            (recv, _, erro) = select.select(socs, [], socs, 3)
            if error:
                break
            for in_ in recv:
                try:
                    data = in_.recv(BUFLEN)
                    if len(data) == 0:
                        break
                    if in_ is self.target:
                        self.client.send(data)
                    else:
                        while data:
                            byte = self.target.send(data)
                            data = data[byte:]
                except:
                    error = True
                    break
            for err in erro:
                error = True
                break

def main(host=IP, port=PORT):
    print("\n\033[1;31m╔══════════════════════════════╗\033[0m")
    print("\033[1;31m║\033[1;37m     KRATOS-SSH PROXY        \033[1;31m║\033[0m")
    print("\033[1;31m║\033[1;33m   Proxy HTTP/SOCKS Ativo    \033[1;31m║\033[0m")
    print("\033[1;31m╚══════════════════════════════╝\033[0m")
    print('\n\033[1;32mPorta\033[1;37m: ' + str(port))
    server = Server(host, port)
    server.start()
    try:
        while True:
            time.sleep(2)
    except KeyboardInterrupt:
        print('\n\033[1;31mKRATOS-SSH Proxy: Encerrando...\033[0m')
        server.close()

main()
PROXY_EOF

    # open.py - Proxy OpenVPN
    cat > $KRATOS_DIR/open.py << 'OPENPY_EOF'
#!/usr/bin/env python3
# encoding: utf-8
# KRATOS-SSH - OpenVPN Proxy
import socket, threading, select, sys, time

IP = '0.0.0.0'
try:
    PORT = int(sys.argv[1])
except:
    PORT = 80
BUFLEN = 8196 * 8
TIMEOUT = 60
MSG = 'KRATOS-SSH'
COR = '<font color="red">'
FTAG = '</font>'
DEFAULT_HOST = '0.0.0.0:1194'
RESPONSE = "HTTP/1.1 200 " + str(COR) + str(MSG) + str(FTAG) + "\r\n\r\n"

class ProxyThread(threading.Thread):
    def __init__(self, client, addr):
        threading.Thread.__init__(self)
        self.client = client
        self.addr = addr

    def run(self):
        try:
            data = self.client.recv(BUFLEN)
            host, port = DEFAULT_HOST.split(':')
            target = socket.create_connection((host, int(port)))
            self.client.send(RESPONSE.encode())
            socs = [self.client, target]
            error = False
            while not error:
                (recv, _, erro) = select.select(socs, [], socs, 3)
                for s in recv:
                    try:
                        d = s.recv(BUFLEN)
                        if not d:
                            error = True
                            break
                        (target if s is self.client else self.client).send(d)
                    except:
                        error = True
                for _ in erro:
                    error = True
        except:
            pass
        finally:
            try: self.client.close()
            except: pass

soc = socket.socket(socket.AF_INET)
soc.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
soc.bind((IP, PORT))
soc.listen(50)
print("\033[1;31m[KRATOS-SSH]\033[1;33m OpenVPN Proxy Ativo na porta\033[1;37m", PORT)
while True:
    try:
        c, addr = soc.accept()
        ProxyThread(c, addr).start()
    except:
        break
OPENPY_EOF

    chmod +x $KRATOS_DIR/wsproxy.py
    chmod +x $KRATOS_DIR/proxy.py
    chmod +x $KRATOS_DIR/open.py
}

# ============================================================
# CONFIGURAR CRON (verificacoes automaticas)
# ============================================================
kratos_setup_cron() {
    # Verificar expirados a cada hora
    (crontab -l 2>/dev/null | grep -v 'kratos\|kratos-ssh'; echo "0 * * * * $0 expcleaner_auto") | crontab -
}

# ============================================================
# MENU PRINCIPAL - KRATOS-SSH
# ============================================================
menu() {
    local x="ok"

    # Sub-menu de ferramentas
    menu2() {
        local stsf stsbot autm var01
        [[ -e /etc/Plus-torrent ]] && stsf=$(echo -e "${GREEN}◉ ") || stsf=$(echo -e "${RED}○ ")
        stsbot=$(ps x | grep "bot_plus" | grep -v grep > /dev/null && echo -e "${GREEN}◉ " || echo -e "${RED}○ ")
        autm=$(grep "menu;" /etc/profile > /dev/null && echo -e "${GREEN}◉ " || echo -e "${RED}○ ")

        local system _ons _expuser _onop _ondrp _onli _ram _usor _usop _core _system _hora _onlin _userexp _tuser

        system=$(kratos_get_system)
        _ons=$(ps -x | grep sshd | grep -v root | grep priv | wc -l)
        [[ "$(cat $KRATOS_DIR/Exp 2>/dev/null)" != "" ]] && _expuser=$(cat $KRATOS_DIR/Exp) || _expuser="0"
        [[ -e /etc/openvpn/openvpn-status.log ]] && _onop=$(grep -c "10.8.0" /etc/openvpn/openvpn-status.log) || _onop="0"
        [[ -e /etc/default/dropbear ]] && { _drp=$(ps aux | grep dropbear | grep -v grep | wc -l); _ondrp=$(($_drp - 1)); } || _ondrp="0"
        _onli=$(($_ons + _onop + _ondrp))
        _ram=$(printf ' %-9s' "$(free -h | grep -i mem | awk {'print $2'})")
        _usor=$(printf '%-8s' "$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')")
        _usop=$(printf '%-1s' "$(top -bn1 | awk '/Cpu/ { cpu = "" 100 - $8 "%" }; END { print cpu }')")
        _core=$(printf '%-1s' "$(grep -c cpu[0-9] /proc/stat)")
        _system=$(printf '%-14s' "$system")
        _hora=$(printf '%(%H:%M:%S)T')
        _onlin=$(printf '%-5s' "$_onli")
        _userexp=$(printf '%-5s' "$_expuser")
        _tuser=$(awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody | wc -l)

        clear
        echo -e "${LINE}"
        echo -e "${BG_RED}         ⚡  KRATOS-SSH - FERRAMENTAS  ⚡          ${RESET}"
        echo -e "${LINE}"
        echo -e "${GREEN}SISTEMA            MEMÓRIA RAM      PROCESSADOR "
        echo -e "${RED}OS: ${WHITE}$_system ${RED}Total:${WHITE}$_ram ${RED}Nucl: ${WHITE}$_core${RESET}"
        echo -e "${RED}Hora: ${WHITE}$_hora     ${RED}Em uso: ${WHITE}$_usor ${RED}Uso: ${WHITE}$_usop${RESET}"
        echo -e "${LINE}"
        [[ ! -e /tmp/att ]] && {
            echo -e "${GREEN}Onlines:${WHITE} $_onlin     ${RED}Expirados: ${WHITE}$_userexp ${YELLOW}Total: ${WHITE}$_tuser${RESET}"
            var01="${WHITE}•"
        } || {
            echo -e "  ${YELLOW}[${RED}!${YELLOW}]  ${GREEN}EXISTE UMA ATUALIZACAO DISPONIVEL  ${YELLOW}[${RED}!${YELLOW}]${RESET}"
            var01="${GREEN}!"
        }
        echo -e "${LINE}"
        echo ""
        echo -e "${RED}[${CYAN}20${RED}] ${WHITE}• ${YELLOW}ADICIONAR HOST     ${RED}[${CYAN}26${RED}] ${WHITE}• ${YELLOW}MUDAR SENHA ROOT
${RED}[${CYAN}21${RED}] ${WHITE}• ${YELLOW}REMOVER HOST       ${RED}[${CYAN}27${RED}] ${WHITE}• ${YELLOW}AUTO EXECUCAO $autm
${RED}[${CYAN}22${RED}] ${WHITE}• ${YELLOW}REINICIAR SISTEMA  ${RED}[${CYAN}28${RED}] ${var01} ${YELLOW}ATUALIZAR SCRIPT
${RED}[${CYAN}23${RED}] ${WHITE}• ${YELLOW}REINICIAR SERVICOS ${RED}[${CYAN}29${RED}] ${WHITE}• ${YELLOW}REMOVER SCRIPT
${RED}[${CYAN}24${RED}] ${WHITE}• ${YELLOW}BLOCK TORRENT $stsf   ${RED}[${CYAN}30${RED}] ${WHITE}• ${YELLOW}VOLTAR ${GREEN}<<<
${RED}[${CYAN}25${RED}] ${WHITE}• ${YELLOW}BOT TELEGRAM $stsbot      ${RED}[${CYAN}00${RED}] ${WHITE}• ${YELLOW}SAIR ${GREEN}<<<${RESET}"
        echo ""
        echo -e "${LINE}"
        echo ""
        echo -ne "${GREEN}OQUE DESEJA FAZER ${YELLOW}?${RED}?${WHITE} : "; read x
        case "$x" in
            20) clear; addhost; echo -ne "\n${RED}ENTER ${YELLOW}para retornar ao ${GREEN}MENU!${RESET}"; read; menu2 ;;
            21) clear; delhost; echo -ne "\n${RED}ENTER ${YELLOW}para retornar ao ${GREEN}MENU!${RESET}"; read; menu2 ;;
            22) clear; reiniciarsistema ;;
            23) clear; reiniciarservicos; sleep 3 ;;
            24) blockt ;;
            25) botssh ;;
            26) clear; senharoot; sleep 3 ;;
            27) autoexec ;;
            28) attscript ;;
            29) clear; delscript ;;
            30) menu ;;
            0|00) echo -e "${RED}Saindo...${RESET}"; sleep 2; clear; exit ;;
            *) echo -e "\n${RED}Opcao invalida !${RESET}"; sleep 2; menu2 ;;
        esac
    }

    # Funcao de auto execucao
    autoexec() {
        if grep "menu;" /etc/profile > /dev/null; then
            clear
            echo -e "${RED}DESATIVANDO AUTO EXECUÇÃO${RESET}"
            offautmenu() { sed -i '/menu;/d' /etc/profile; }
            echo ""; fun_bar 'offautmenu'
            echo -e "\n${RED}AUTO EXECUÇÃO DESATIVADO!${RESET}"
            sleep 1.5; menu2
        else
            clear
            echo -e "${GREEN}ATIVANDO AUTO EXECUÇÃO${RESET}"
            autmenu() {
                grep -v "^menu;" /etc/profile > /tmp/tmpass && mv /tmp/tmpass /etc/profile
                echo "menu;" >> /etc/profile
            }
            echo ""; fun_bar 'autmenu'
            echo -e "\n${GREEN}AUTO EXECUÇÃO ATIVADO!${RESET}"
            sleep 1.5; menu2
        fi
    }

    # Limiter SSH
    function limit1() {
        clear
        echo -e "\n${GREEN}INICIANDO O LIMITER... ${RESET}\n"
        fun_bar 'screen -dmS limiter limiter' 'sleep 3'
        [[ $(grep -wc "limiter" $KRATOS_AUTOSTART) = '0' ]] && {
            echo -e "ps x | grep 'limiter' | grep -v 'grep' && echo 'ON' || screen -dmS limiter limiter" >> $KRATOS_AUTOSTART
        } || {
            sed -i '/limiter/d' $KRATOS_AUTOSTART
            echo -e "ps x | grep 'limiter' | grep -v 'grep' && echo 'ON' || screen -dmS limiter limiter" >> $KRATOS_AUTOSTART
        }
        echo -e "\n${GREEN}  LIMITER ATIVO !${RESET}"
        sleep 3; menu
    }
    function limit2() {
        clear
        echo -e "${RED}PARANDO O LIMITER... ${RESET}\n"
        fun_stplimiter() {
            sleep 1
            screen -r -S "limiter" -X quit
            screen -wipe 1>/dev/null 2>/dev/null
            [[ $(grep -wc "limiter" $KRATOS_AUTOSTART) != '0' ]] && sed -i '/limiter/d' $KRATOS_AUTOSTART
            sleep 1
        }
        fun_bar 'fun_stplimiter' 'sleep 3'
        echo -e "\n${RED} LIMITER PARADO !${RESET}"
        sleep 3; menu
    }
    function limit_ssh() {
        [[ $(ps x | grep "limiter" | grep -v grep | wc -l) = '0' ]] && limit1 || limit2
    }

    # velocidade
    velocity() {
        aguarde() {
            local cmd="$1"
            (
                [[ -e $HOME/fim ]] && rm $HOME/fim
                $cmd > /dev/null 2>&1
                touch $HOME/fim
            ) > /dev/null 2>&1 &
            tput civis
            echo -ne "  ${YELLOW}AGUARDE ${WHITE}- ${YELLOW}["
            while true; do
                for ((i=0; i<18; i++)); do echo -ne "${RED}#"; sleep 0.1s; done
                [[ -e $HOME/fim ]] && rm $HOME/fim && break
                echo -e "${YELLOW}]"; sleep 1s; tput cuu1; tput dl1
                echo -ne "  ${YELLOW}AGUARDE ${WHITE}- ${YELLOW}["
            done
            echo -e "${YELLOW}]${WHITE} -${GREEN} OK !${WHITE}"
            tput cnorm
        }
        fun_tst() { speedtest --share > speed; }
        echo ""
        echo -e "   ${GREEN}TESTANDO A VELOCIDADE DO SERVIDOR !${RESET}"
        echo ""
        aguarde 'fun_tst'
        echo ""
        png=$(cat speed | sed -n '5 p' | awk -F : {'print $NF'})
        down=$(cat speed | sed -n '7 p' | awk -F : {'print $NF'})
        upl=$(cat speed | sed -n '9 p' | awk -F : {'print $NF'})
        lnk=$(cat speed | sed -n '10 p' | awk {'print $NF'})
        echo -e "${LINE}"
        echo -e "${GREEN}PING (LATENCIA):${WHITE}$png"
        echo -e "${GREEN}DOWNLOAD:${WHITE}$down"
        echo -e "${GREEN}UPLOAD:${WHITE}$upl"
        echo -e "${GREEN}LINK: ${CYAN}$lnk${RESET}"
        echo -e "${LINE}"
        rm -rf $HOME/speed
    }

    # ==================================================================
    # LOOP PRINCIPAL DO MENU
    # ==================================================================
    while true; do
        local stsl stsu system _ons _expuser _onop _ondrp _onli _ram _usor _usop _core _system _hora _onlin _userexp _tuser

        stsl=$(ps x | grep "limiter" | grep -v grep > /dev/null && echo -e "${GREEN}◉ " || echo -e "${RED}○ ")
        stsu=$(ps x | grep "udpvpn" | grep -v grep > /dev/null && echo -e "${GREEN}◉ " || echo -e "${RED}○ ")
        system=$(kratos_get_system)
        _ons=$(ps -x | grep sshd | grep -v root | grep priv | wc -l)
        [[ "$(cat $KRATOS_DIR/Exp 2>/dev/null)" != "" ]] && _expuser=$(cat $KRATOS_DIR/Exp) || _expuser="0"
        [[ -e /etc/openvpn/openvpn-status.log ]] && _onop=$(grep -c "10.8.0" /etc/openvpn/openvpn-status.log) || _onop="0"
        [[ -e /etc/default/dropbear ]] && { _drp=$(ps aux | grep dropbear | grep -v grep | wc -l); _ondrp=$(($_drp - 1)); } || _ondrp="0"
        _onli=$(($_ons + _onop + _ondrp))
        _ram=$(printf ' %-9s' "$(free -h | grep -i mem | awk {'print $2'})")
        _usor=$(printf '%-8s' "$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')")
        _usop=$(printf '%-1s' "$(top -bn1 | awk '/Cpu/ { cpu = "" 100 - $8 "%" }; END { print cpu }')")
        _core=$(printf '%-1s' "$(grep -c cpu[0-9] /proc/stat)")
        _system=$(printf '%-14s' "$system")
        _hora=$(printf '%(%H:%M:%S)T')
        _onlin=$(printf '%-5s' "$_onli")
        _userexp=$(printf '%-5s' "$_expuser")
        _tuser=$(awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody | wc -l)
        local IP
        IP=$(cat /etc/IP 2>/dev/null || echo "N/A")

        clear
        echo -e "${LINE}"
        echo -e "${BG_RED}              ⚡  KRATOS-SSH  ⚡               ${RESET}"
        echo -e "${BLUE}         Sistema Profissional SSH Manager        ${RESET}"
        echo -e "${LINE}"
        echo -e "${GREEN}SISTEMA            MEMÓRIA RAM      PROCESSADOR "
        echo -e "${RED}OS: ${WHITE}$_system ${RED}Total:${WHITE}$_ram ${RED}Nucl: ${WHITE}$_core${RESET}"
        echo -e "${RED}Hora: ${WHITE}$_hora     ${RED}Em uso: ${WHITE}$_usor ${RED}Uso: ${WHITE}$_usop${RESET}"
        echo -e "${LINE}"
        echo -e "${GREEN}Onlines:${WHITE} $_onlin     ${RED}Expirados: ${WHITE}$_userexp ${YELLOW}Total: ${WHITE}$_tuser${RESET}"
        echo -e "${RED}IP: ${WHITE}$IP${RESET}"
        echo -e "${LINE}"
        echo ""
        echo -e "${RED}[${CYAN}01${RED}] ${WHITE}• ${YELLOW}CRIAR USUARIO             ${RED}[${CYAN}11${RED}] ${WHITE}• ${YELLOW}SPEEDTEST
${RED}[${CYAN}02${RED}] ${WHITE}• ${YELLOW}CRIAR USUARIO TESTE       ${RED}[${CYAN}12${RED}] ${WHITE}• ${YELLOW}BANNER SSH
${RED}[${CYAN}03${RED}] ${WHITE}• ${YELLOW}REMOVER USUARIO           ${RED}[${CYAN}13${RED}] ${WHITE}• ${YELLOW}TRAFEGO
${RED}[${CYAN}04${RED}] ${WHITE}• ${YELLOW}MONITOR ONLINE            ${RED}[${CYAN}14${RED}] ${WHITE}• ${YELLOW}OTIMIZAR
${RED}[${CYAN}05${RED}] ${WHITE}• ${YELLOW}MUDAR DATA EXPIRACAO      ${RED}[${CYAN}15${RED}] ${WHITE}• ${YELLOW}BACKUP
${RED}[${CYAN}06${RED}] ${WHITE}• ${YELLOW}ALTERAR LIMITE            ${RED}[${CYAN}16${RED}] ${WHITE}• ${YELLOW}LIMITER $stsl
${RED}[${CYAN}07${RED}] ${WHITE}• ${YELLOW}MUDAR SENHA               ${RED}[${CYAN}17${RED}] ${WHITE}• ${YELLOW}BAD VPN $stsu
${RED}[${CYAN}08${RED}] ${WHITE}• ${YELLOW}REMOVER EXPIRADOS         ${RED}[${CYAN}18${RED}] ${WHITE}• ${YELLOW}INFO VPS
${RED}[${CYAN}09${RED}] ${WHITE}• ${YELLOW}RELATORIO DE USUARIOS     ${RED}[${CYAN}19${RED}] ${WHITE}• ${YELLOW}MAIS ${RED}>${YELLOW}>${GREEN}>
${RED}[${CYAN}10${RED}] ${WHITE}• ${YELLOW}MODO DE CONEXAO           ${RED}[${CYAN}00${RED}] ${WHITE}• ${YELLOW}SAIR ${GREEN}<<<${RESET}"
        echo ""
        echo -e "${LINE}"
        echo ""
        echo -ne "${GREEN}OQUE DESEJA FAZER ${YELLOW}?${RED}?${WHITE} : "; read x

        case "$x" in
            1|01) clear; criarusuario; echo -ne "\n${RED}ENTER ${YELLOW}para retornar ao ${GREEN}MENU!${RESET}"; read ;;
            2|02) clear; criarteste; echo -ne "\n${RED}ENTER ${YELLOW}para retornar ao ${GREEN}MENU!${RESET}"; read ;;
            3|03) clear; remover; sleep 3 ;;
            4|04) clear; sshmonitor; echo -ne "\n${RED}ENTER ${YELLOW}para retornar ao ${GREEN}MENU!${RESET}"; read ;;
            5|05) clear; mudardata; sleep 3 ;;
            6|06) clear; alterarlimite; sleep 3 ;;
            7|07) clear; alterarsenha; sleep 3 ;;
            8|08) clear; expcleaner; echo ""; sleep 3 ;;
            9|09) clear; infousers; echo -ne "\n${RED}ENTER ${YELLOW}para retornar ao ${GREEN}MENU!${RESET}"; read ;;
            10) conexao; exit ;;
            11) clear; velocity; echo -ne "\n${RED}ENTER ${YELLOW}para retornar ao ${GREEN}MENU!${RESET}"; read ;;
            12) clear; banner ;;
            13) clear; echo -e "${GREEN}PARA SAIR CLICK CTRL + C${CYAN}"; sleep 4; nload ;;
            14) clear; otimizar; echo -ne "\n${RED}ENTER ${YELLOW}para retornar ao ${GREEN}MENU!${RESET}"; read ;;
            15) userbackup; echo -ne "\n${RED}ENTER ${YELLOW}para retornar ao ${GREEN}MENU!${RESET}"; read ;;
            16) limit_ssh ;;
            17) clear; badvpn; exit ;;
            18) clear; detalhes; echo -ne "\n${RED}ENTER ${YELLOW}para retornar ao ${GREEN}MENU!${RESET}"; read ;;
            19) menu2 ;;
            0|00) echo -e "${RED}Saindo...${RESET}"; sleep 2; clear; exit ;;
            *) echo -e "\n${RED}Opcao invalida !${RESET}"; sleep 2 ;;
        esac
    done
}

# ============================================================
# CRIAR USUARIO
# ============================================================
criarusuario() {
    local IP cor1 cor2 scor username password dias sshlimiter final gui pass
    IP=$(cat /etc/IP 2>/dev/null)
    cor1="${BG_RED}"
    cor2="${BG_BLUE}"
    scor="${RESET}"

    clear
    echo -e "${BG_BLUE}               CRIAR USUÁRIO SSH               ${RESET}"
    echo ""
    echo -ne "${GREEN}Nome do usuário:${WHITE} "; read username
    [[ -z $username ]] && { echo -e "\n${BG_RED}Nome de usuário vazio ou invalido!${RESET}\n"; return 1; }
    [[ "$(grep -wc $username /etc/passwd)" != '0' ]] && { echo -e "\n${BG_RED}Este usuário já existe. Tente outro nome!${RESET}\n"; return 1; }
    [[ ${username} != ?(+|-)+([a-zA-Z0-9]) ]] && { echo -e "\n${BG_RED}Nome inválido! Sem espaços ou caracteres especiais!${RESET}\n"; return 1; }
    [[ ${#username} -lt 2 ]] && { echo -e "\n${BG_RED}Nome muito curto! Use no mínimo 2 caracteres!${RESET}\n"; return 1; }
    [[ ${#username} -gt 10 ]] && { echo -e "\n${BG_RED}Nome muito grande! Use no máximo 10 caracteres!${RESET}\n"; return 1; }

    echo -ne "${GREEN}Senha:${WHITE} "; read password
    [[ -z $password ]] && { echo -e "\n${BG_RED}Senha vazia ou invalida!${RESET}\n"; return 1; }
    [[ ${#password} -lt 4 ]] && { echo -e "\n${BG_RED}Senha curta! Use no mínimo 4 caracteres!${RESET}\n"; return 1; }

    echo -ne "${GREEN}Dias para expirar:${WHITE} "; read dias
    [[ -z $dias ]] || [[ ${dias} != ?(+|-)+([0-9]) ]] || [[ $dias -lt 1 ]] && { echo -e "\n${BG_RED}Número de dias inválido!${RESET}\n"; return 1; }

    echo -ne "${GREEN}Limite de conexões:${WHITE} "; read sshlimiter
    [[ -z $sshlimiter ]] || [[ ${sshlimiter} != ?(+|-)+([0-9]) ]] || [[ $sshlimiter -lt 1 ]] && { echo -e "\n${BG_RED}Limite de conexões inválido!${RESET}\n"; return 1; }

    final=$(date "+%Y-%m-%d" -d "+$dias days")
    gui=$(date "+%d/%m/%Y" -d "+$dias days")
    pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
    useradd -e $final -M -s /bin/false -p $pass $username > /dev/null 2>&1
    echo "$password" > $KRATOS_SENHA_DIR/$username
    echo "$username $sshlimiter" >> $KRATOS_DB

    clear
    echo -e "${BG_BLUE}          CONTA SSH CRIADA - KRATOS-SSH        ${RESET}"
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${RED}║${GREEN} IP          : ${WHITE}$IP${RED}"
    echo -e "${RED}║${GREEN} Usuário     : ${WHITE}$username${RED}"
    echo -e "${RED}║${GREEN} Senha       : ${WHITE}$password${RED}"
    echo -e "${RED}║${GREEN} Expira em   : ${WHITE}$gui${RED}"
    echo -e "${RED}║${GREEN} Limite Conex: ${WHITE}$sshlimiter${RED}"
    echo -e "${RED}╚══════════════════════════════════════════════╝${RESET}"

    # Gerar OVPN se disponível
    if [[ -e /etc/openvpn/server.conf ]]; then
        echo -ne "\n${GREEN}Gerar Arquivo Ovpn ${RED}? ${YELLOW}[s/n]:${WHITE} "; read resp
        [[ "$resp" = @(s|S) ]] && {
            cd /etc/openvpn/easy-rsa/ 2>/dev/null && {
                ./easyrsa build-client-full $username nopass > /dev/null 2>&1
                cp /etc/openvpn/client-common.txt ~/$username.ovpn
                echo "<ca>" >> ~/$username.ovpn
                cat /etc/openvpn/easy-rsa/pki/ca.crt >> ~/$username.ovpn
                echo "</ca>" >> ~/$username.ovpn
                echo "<cert>" >> ~/$username.ovpn
                cat /etc/openvpn/easy-rsa/pki/issued/$username.crt >> ~/$username.ovpn
                echo "</cert>" >> ~/$username.ovpn
                echo "<key>" >> ~/$username.ovpn
                cat /etc/openvpn/easy-rsa/pki/private/$username.key >> ~/$username.ovpn
                echo "</key>" >> ~/$username.ovpn
                echo "<tls-auth>" >> ~/$username.ovpn
                cat /etc/openvpn/ta.key >> ~/$username.ovpn
                echo "</tls-auth>" >> ~/$username.ovpn
                zip /root/$username.zip /root/$username.ovpn > /dev/null 2>&1
                echo -e "\n${GREEN}OVPN disponível em: ${WHITE}~/\"$username.zip\"${RESET}"
                cd $HOME
            }
        }
    fi
}

# ============================================================
# CRIAR USUARIO TESTE
# ============================================================
criarteste() {
    local IP nome pass limit u_temp
    IP=$(cat /etc/IP 2>/dev/null)
    [[ ! -d $KRATOS_DIR/userteste ]] && mkdir -p $KRATOS_DIR/userteste

    clear
    echo -e "${BG_BLUE}          CRIAR USUÁRIO TESTE - KRATOS-SSH      ${RESET}"
    echo ""
    [[ "$(ls -A $KRATOS_DIR/userteste 2>/dev/null)" ]] && \
        echo -e "${GREEN}Testes Ativos:${WHITE}" && ls $KRATOS_DIR/userteste | sed 's/.sh//g' || \
        echo -e "${RED}Nenhum teste ativo!${RESET}"
    echo ""

    echo -ne "${GREEN}Nome do usuário:${WHITE} "; read nome
    [[ -z $nome ]] && { echo -e "\n${BG_RED}Nome vazio ou invalido.${RESET}"; return 1; }
    grep -Fxq "$nome" <(awk -F : '{print $1}' /etc/passwd) && { echo -e "\n${BG_RED}Este usuário já existe.${RESET}"; return 1; }

    echo -ne "${GREEN}Senha:${WHITE} "; read pass
    [[ -z $pass ]] && { echo -e "\n${BG_RED}Senha vazia ou invalida.${RESET}"; return 1; }

    echo -ne "${GREEN}Limite de conexões:${WHITE} "; read limit
    [[ -z $limit ]] && { echo -e "\n${BG_RED}Limite vazio ou invalido.${RESET}"; return 1; }

    echo -ne "${GREEN}Minutos de validade (Ex: 60):${WHITE} "; read u_temp
    [[ -z $u_temp ]] && { echo -e "\n${BG_RED}Tempo vazio ou invalido.${RESET}"; return 1; }

    useradd -M -s /bin/false $nome
    (echo $pass; echo $pass) | passwd $nome > /dev/null 2>&1
    echo "$pass" > $KRATOS_SENHA_DIR/$nome
    echo "$nome $limit" >> $KRATOS_DB

    cat > $KRATOS_DIR/userteste/$nome.sh << TESTSH
#!/bin/bash
pkill -f "$nome"
userdel --force $nome
grep -v ^$nome[[:space:]] $KRATOS_DB > /tmp/ph ; cat /tmp/ph > $KRATOS_DB
rm $KRATOS_SENHA_DIR/$nome > /dev/null 2>&1
rm -rf $KRATOS_DIR/userteste/$nome.sh
exit
TESTSH
    chmod +x $KRATOS_DIR/userteste/$nome.sh
    at -f $KRATOS_DIR/userteste/$nome.sh now + $u_temp min > /dev/null 2>&1

    clear
    echo -e "${BG_BLUE}      Usuário Teste Criado - KRATOS-SSH     ${RESET}"
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${RED}║${GREEN} IP       : ${WHITE}$IP${RED}"
    echo -e "${RED}║${GREEN} Usuário  : ${WHITE}$nome${RED}"
    echo -e "${RED}║${GREEN} Senha    : ${WHITE}$pass${RED}"
    echo -e "${RED}║${GREEN} Limite   : ${WHITE}$limit${RED}"
    echo -e "${RED}║${GREEN} Validade : ${WHITE}$u_temp Minutos${RED}"
    echo -e "${RED}╚══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${YELLOW}Após o tempo definido o usuário ${WHITE}$nome${YELLOW} será removido.${RESET}"
}

# ============================================================
# REMOVER USUARIO
# ============================================================
remover() {
    remove_ovp() {
        [[ -e /etc/debian_version ]] && GROUPNAME=nogroup
        local user="$1"
        cd /etc/openvpn/easy-rsa/ 2>/dev/null && {
            ./easyrsa --batch revoke $user
            ./easyrsa gen-crl
            rm -rf pki/reqs/$user.req pki/private/$user.key pki/issued/$user.crt /etc/openvpn/crl.pem
            cp /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/crl.pem
            chown nobody:$GROUPNAME /etc/openvpn/crl.pem
            [[ -e $HOME/$user.ovpn ]] && rm $HOME/$user.ovpn
            [[ -e /var/www/html/openvpn/$user.zip ]] && rm /var/www/html/openvpn/$user.zip
        } > /dev/null 2>&1
    }

    clear
    echo -e "${BG_BLUE}            REMOVER USUÁRIO - KRATOS-SSH        ${RESET}"
    echo ""
    echo -e "${RED}[${CYAN}1${RED}]${YELLOW} REMOVER UM USUARIO"
    echo -e "${RED}[${CYAN}2${RED}]${YELLOW} REMOVER TODOS USUARIOS"
    echo -e "${RED}[${CYAN}3${RED}]${YELLOW} VOLTAR"
    echo ""
    read -p "$(echo -e "${GREEN}OQUE DESEJA FAZER${RED} ?${WHITE} : ")" -e -i 1 resp

    if [[ "$resp" = "1" ]]; then
        clear
        echo -e "${BG_BLUE}            REMOVER USUÁRIO - KRATOS-SSH        ${RESET}"
        echo ""
        echo -e "${YELLOW}LISTA DE USUARIOS: ${RESET}"
        echo ""
        local _userT i _userPass
        _userT=$(awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody)
        i=0; unset _userPass
        while read _user; do
            i=$(expr $i + 1); _oP=$i
            [[ $i == [1-9] ]] && i=0$i
            echo -e "${RED}[${CYAN}$i${RED}] ${WHITE}- ${GREEN}$_user${RESET}"
            _userPass+="\n${_oP}:${_user}"
        done <<< "${_userT}"
        echo ""
        local num_user option user
        num_user=$(awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody | wc -l)
        echo -ne "${GREEN}Selecione o usuário ${YELLOW}[${CYAN}1${RED}-${CYAN}$num_user${YELLOW}]${WHITE}: "; read option
        user=$(echo -e "${_userPass}" | grep -E "\b$option\b" | cut -d: -f2)
        [[ -z $user ]] && { echo -e "\n${BG_RED}Usuário inválido!${RESET}"; return 1; }
        if grep -w "$user" /etc/passwd > /dev/null 2>&1; then
            pkill -f "$user" > /dev/null 2>&1
            deluser --force $user > /dev/null 2>&1
            echo -e "\n${BG_RED} Usuário $user removido com sucesso! ${RESET}"
            grep -v ^$user[[:space:]] $KRATOS_DB > /tmp/ph; cat /tmp/ph > $KRATOS_DB
            rm $KRATOS_SENHA_DIR/$user 2>/dev/null
            [[ -e /etc/openvpn/server.conf ]] && remove_ovp $user
        else
            echo -e "\n${BG_RED}O usuário $user não existe!${RESET}"
        fi

    elif [[ "$resp" = "2" ]]; then
        clear
        echo -e "${BG_BLUE}            REMOVER USUÁRIO - KRATOS-SSH        ${RESET}"
        echo ""
        echo -ne "${RED}REALMENTE DESEJA REMOVER TODOS USUARIOS ${WHITE}[s/n]: "; read opc
        if [[ "$opc" = "s" ]]; then
            echo -e "\n${YELLOW}Aguarde...${RESET}"
            for user in $(awk -F: '$3 > 900 {print $1}' /etc/passwd | grep -vi "nobody"); do
                pkill -f $user > /dev/null 2>&1
                deluser --force $user > /dev/null 2>&1
                [[ -e /etc/openvpn/server.conf ]] && remove_ovp $user
            done
            rm $KRATOS_DB && touch $KRATOS_DB
            rm *.zip > /dev/null 2>&1
            echo -e "\n${GREEN}USUARIOS REMOVIDOS COM SUCESSO!${RESET}"
            sleep 2; menu
        else
            echo -e "\n${RED}Retornando ao menu...${RESET}"; sleep 2; menu
        fi
    elif [[ "$resp" = "3" ]]; then
        menu
    else
        echo -e "\n${RED}Opcao invalida !${RESET}"; sleep 1.5; menu
    fi
}

# ============================================================
# MONITOR SSH ONLINE
# ============================================================
sshmonitor() {
    clear
    [[ ! -f $KRATOS_DB ]] && { echo -e "${RED}[ERRO]${WHITE} Arquivo de usuários não encontrado!${RESET}"; return 1; }

    local tmp_now
    tmp_now=$(printf '%(%H%M%S)T\n')

    fun_drop_mon() {
        local port_dropbear log loginsukses pids
        port_dropbear=$(ps aux | grep dropbear | awk NR==1 | awk '{print $17;}')
        log=/var/log/auth.log
        loginsukses='Password auth succeeded'
        pids=$(ps ax | grep dropbear | grep " $port_dropbear" | awk -F" " '{print $1}')
        for pid in $pids; do
            local pidlogs i pidend
            pidlogs=$(grep $pid $log | grep "$loginsukses" | awk -F" " '{print $3}')
            i=0
            for pidend in $pidlogs; do let i=i+1; done
            if [ $pidend ]; then
                local login PID user waktu
                login=$(grep $pid $log | grep "$pidend" | grep "$loginsukses")
                PID=$pid
                user=$(echo $login | awk -F" " '{print $10}' | sed -r "s/'/ /g")
                waktu=$(echo $login | awk -F" " '{print $2"-"$1,$3}')
                while [ ${#waktu} -lt 13 ]; do waktu=$waktu" "; done
                while [ ${#user} -lt 16 ]; do user=$user" "; done
                while [ ${#PID} -lt 8 ]; do PID=$PID" "; done
                echo "$user $PID $waktu"
            fi
        done
    }

    echo -e "${BG_BLUE} Usuario         Status       Conexão     Tempo   ${RESET}"
    echo ""

    while read usline; do
        local user s2ssh sqd ovp drop cnx conex tst timerr status
        user="$(echo $usline | cut -d' ' -f1)"
        s2ssh="$(echo $usline | cut -d' ' -f2)"
        [[ "$(cat /etc/passwd | grep -w $user | wc -l)" = "1" ]] && sqd="$(ps -u $user | grep sshd | wc -l)" || sqd=0
        [[ -z "$sqd" ]] && sqd=0
        [[ -e /etc/openvpn/openvpn-status.log ]] && ovp="$(cat /etc/openvpn/openvpn-status.log | grep -E ,"$user", | wc -l)" || ovp=0
        netstat -nltp 2>/dev/null | grep 'dropbear' > /dev/null && drop="$(fun_drop_mon | grep "$user" | wc -l)" || drop=0
        cnx=$(($sqd + $drop))
        conex=$(($cnx + $ovp))
        if [[ $cnx -gt 0 ]]; then
            tst="$(ps -o etime $(ps -u $user | grep sshd | awk 'NR==1 {print $1}') | awk 'NR==2 {print $1}')"
            [[ ${#tst} == "8" ]] && timerr="$tst" || timerr="00:$tst"
        else
            timerr="00:00:00"
        fi
        if [[ $conex -eq 0 ]]; then
            status=$(echo -e "${RED}Offline ${YELLOW}       ")
        else
            status=$(echo -e "${GREEN}Online${YELLOW}         ")
        fi
        echo -ne "${YELLOW}"
        printf '%-17s%-14s%-10s%s\n' " $user" "$status" "$conex/$s2ssh" "$timerr"
        echo -e "${LINE}"
    done < "$KRATOS_DB"

    local _tuser _ons _onop _ondrp _onli _expuser
    _tuser=$(awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody | wc -l)
    _ons=$(ps -x | grep sshd | grep -v root | grep priv | wc -l)
    [[ "$(cat $KRATOS_DIR/Exp 2>/dev/null)" != "" ]] && _expuser=$(cat $KRATOS_DIR/Exp) || _expuser="0"
    [[ -e /etc/openvpn/openvpn-status.log ]] && _onop=$(grep -c "10.8.0" /etc/openvpn/openvpn-status.log) || _onop="0"
    [[ -e /etc/default/dropbear ]] && { _drp=$(ps aux | grep dropbear | grep -v grep | wc -l); _ondrp=$(($_drp - 1)); } || _ondrp="0"
    _onli=$(($_ons + _onop + _ondrp))
    echo ""
    echo -e "${YELLOW}• ${CYAN}TOTAL${WHITE} $_tuser ${YELLOW}• ${GREEN}ONLINE${WHITE}: $_onli ${YELLOW}• ${RED}VENCIDOS${WHITE}: $_expuser ${YELLOW}•${RESET}"
}

# ============================================================
# INFORMACOES DE USUARIOS
# ============================================================
infousers() {
    clear
    echo -e "${BG_BLUE} Usuario         Senha       Limite      Validade ${RESET}"
    echo ""
    for users in $(awk -F: '$3 > 900 {print $1}' /etc/passwd | sort | grep -v "nobody" | grep -vi polkitd | grep -vi "system-"); do
        local lim senha datauser data
        [[ $(grep -cw $users $KRATOS_DB) == "1" ]] && lim=$(grep -w $users $KRATOS_DB | cut -d' ' -f2) || lim="1"
        [[ -e "$KRATOS_SENHA_DIR/$users" ]] && senha=$(cat $KRATOS_SENHA_DIR/$users) || senha="Null"
        datauser=$(chage -l $users | grep -i co | awk -F: '{print $2}')
        if [ "$datauser" = " never" ] 2>/dev/null; then
            data="${YELLOW}Nunca${RESET}"
        else
            databr="$(date -d "$datauser" +"%Y%m%d" 2>/dev/null)"
            hoje="$(date -d today +"%Y%m%d")"
            if [ "$hoje" -ge "$databr" ] 2>/dev/null; then
                data="${RED}Venceu${RESET}"
            else
                dat="$(date -d "$datauser" '+%Y-%m-%d' 2>/dev/null)"
                data=$(echo -e "$((($(date -ud $dat +%s)-$(date -ud $(date +%Y-%m-%d) +%s))/86400)) ${WHITE}Dias${RESET}")
            fi
        fi
        local Usuario Senha Limite Data
        Usuario=$(printf ' %-15s' "$users")
        Senha=$(printf '%-13s' "$senha")
        Limite=$(printf '%-10s' "$lim")
        Data=$(printf '%-1s' "$data")
        echo -e "${YELLOW}$Usuario ${WHITE}$Senha ${WHITE}$Limite ${GREEN}$Data${RESET}"
        echo -e "${LINE}"
    done
    echo ""
    local _tuser _ons _onop _ondrp _onli _expuser
    _tuser=$(awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody | wc -l)
    _ons=$(ps -x | grep sshd | grep -v root | grep priv | wc -l)
    [[ "$(cat $KRATOS_DIR/Exp 2>/dev/null)" != "" ]] && _expuser=$(cat $KRATOS_DIR/Exp) || _expuser="0"
    [[ -e /etc/openvpn/openvpn-status.log ]] && _onop=$(grep -c "10.8.0" /etc/openvpn/openvpn-status.log) || _onop="0"
    [[ -e /etc/default/dropbear ]] && { _drp=$(ps aux | grep dropbear | grep -v grep | wc -l); _ondrp=$(($_drp - 1)); } || _ondrp="0"
    _onli=$(($_ons + _onop + _ondrp))
    echo -e "${YELLOW}• ${CYAN}TOTAL USUARIOS${WHITE} $_tuser ${YELLOW}• ${GREEN}ONLINES${WHITE}: $_onli ${YELLOW}• ${RED}VENCIDOS${WHITE}: $_expuser ${YELLOW}•${RESET}"
}

# ============================================================
# MUDAR DATA DE EXPIRACAO
# ============================================================
mudardata() {
    clear
    echo -e "${BG_BLUE}         MUDAR DATA DE EXPIRAÇÃO - KRATOS-SSH   ${RESET}"
    echo ""
    echo -e "${YELLOW} LISTA DE USUARIOS E DATA DE EXPIRACAO:${RESET}"
    echo ""
    local list_user i _userPass
    list_user=$(awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody)
    i=0; unset _userPass
    while read user; do
        i=$(expr $i + 1); _oP=$i
        [[ $i == [1-9] ]] && i=0$i
        local expire databr hoje _user datanormal
        expire="$(chage -l $user | grep -E "Account expires" | cut -d ' ' -f3-)"
        if [[ $expire == "never" ]]; then
            echo -e "${RED}[${CYAN}$i${RED}] ${WHITE}- ${GREEN}$user     ${YELLOW}00/00/0000   S/DATA${RESET}"
        else
            databr="$(date -d "$expire" +"%Y%m%d" 2>/dev/null)"
            hoje="$(date -d today +"%Y%m%d")"
            _user=$(echo -e "${RED}[${CYAN}$i${RED}] ${WHITE}- ${GREEN}$user${WHITE}")
            if [ "$hoje" -ge "$databr" ] 2>/dev/null; then
                datanormal="$(echo -e "${RED}$(date -d "$expire" '+%d/%m/%Y' 2>/dev/null)")"
                printf '%-62s%-20s%s\n' "$_user" "$datanormal" "$(echo -e "${RED}VENCEU${RESET}")"
            else
                datanormal="$(echo -e "${YELLOW}$(date -d "$expire" '+%d/%m/%Y' 2>/dev/null)")"
                printf '%-62s%-20s%s\n' "$_user" "$datanormal" "$(echo -e "${GREEN}VALIDO${RESET}")"
            fi
        fi
        _userPass+="\n${_oP}:${user}"
    done <<< "${list_user}"
    echo ""
    local num_user option usuario inputdate udata sysdate
    num_user=$(awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody | wc -l)
    echo -ne "${GREEN}Selecione um usuário ${YELLOW}[${CYAN}1${RED}-${CYAN}$num_user${YELLOW}]${WHITE}: "; read option
    [[ -z $option ]] && { echo -e "\n${BG_RED}Usuário vazio ou inválido!${RESET}"; return 1; }
    usuario=$(echo -e "${_userPass}" | grep -E "\b$option\b" | cut -d: -f2)
    [[ -z $usuario ]] && { echo -e "\n${BG_RED}Usuário vazio ou inválido!${RESET}"; return 1; }
    echo ""
    echo -e "${RED}EX:${YELLOW}(${GREEN}DATA: ${WHITE}DIA/MÊS/ANO ${YELLOW}OU ${GREEN}DIAS: ${WHITE}30${YELLOW})"
    echo ""
    echo -ne "${GREEN}Nova data ou dias para ${YELLOW}$usuario${WHITE}: "; read inputdate
    [[ -z $inputdate ]] && { echo -e "\n${BG_RED}Data inválida!${RESET}"; return 1; }
    if [[ "$(echo -e "$inputdate" | grep -c "/")" = "0" ]]; then
        udata=$(date "+%d/%m/%Y" -d "+$inputdate days")
        sysdate="$(echo "$udata" | awk -v FS=/ -v OFS=- '{print $3,$2,$1}')"
    else
        udata=$(echo -e "$inputdate")
        sysdate="$(echo "$inputdate" | awk -v FS=/ -v OFS=- '{print $3,$2,$1}')"
    fi
    if date "+%Y-%m-%d" -d "$sysdate" > /dev/null 2>&1; then
        local today timemachine
        today="$(date -d today +"%Y%m%d")"
        timemachine="$(date -d "$sysdate" +"%Y%m%d")"
        if [ "$today" -ge "$timemachine" ]; then
            echo -e "\n${BG_RED}Data passada ou dia atual! Use uma data futura.${RESET}"
        else
            chage -E $sysdate $usuario
            echo -e "\n${BG_BLUE}Sucesso! Usuário $usuario nova data: $udata ${RESET}"
        fi
    else
        echo -e "\n${BG_RED}Data inválida! Formato: DIA/MÊS/ANO (Ex: 21/04/2025)${RESET}"
    fi
}

# ============================================================
# ALTERAR LIMITE DE CONEXOES
# ============================================================
alterarlimite() {
    clear
    echo -e "${BG_BLUE}      ALTERAR LIMITE DE CONEXÕES - KRATOS-SSH    ${RESET}"
    echo ""
    [[ ! -f $KRATOS_DB ]] && { echo -e "${BG_RED}Arquivo $KRATOS_DB não encontrado${RESET}"; return 1; }
    echo -e "${YELLOW}LISTA DE USUARIOS E SEUS LIMITES:${RESET}"
    echo ""
    local _userT i _userPass
    _userT=$(awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody)
    i=0; unset _userPass
    while read _user; do
        i=$(expr $i + 1); _oP=$i
        [[ $i == [1-9] ]] && i=0$i
        local limit l_user lim
        [[ "$(grep -wc "$_user" $KRATOS_DB)" != "0" ]] && limit=$(grep -w "$_user" $KRATOS_DB | cut -d' ' -f2) || limit='1'
        l_user=$(echo -e "${RED}[${CYAN}$i${RED}] ${WHITE}- ${GREEN}$_user${RESET}")
        lim=$(echo -e "${YELLOW}Limite${WHITE}: $limit")
        printf '%-65s%s\n' "$l_user" "$lim"
        _userPass+="\n${_oP}:${_user}"
    done <<< "${_userT}"
    echo ""
    local num_user option usuario sshnum
    num_user=$(awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody | wc -l)
    echo -ne "${GREEN}Selecione um usuário ${YELLOW}[${CYAN}1${RED}-${CYAN}$num_user${YELLOW}]${WHITE}: "; read option
    usuario=$(echo -e "${_userPass}" | grep -E "\b$option\b" | cut -d: -f2)
    [[ -z $option ]] || [[ -z $usuario ]] && { echo -e "\n${BG_RED}Usuário inválido!${RESET}"; return 1; }
    grep -w $usuario /etc/passwd > /dev/null || { echo -e "\n${BG_RED}O usuário $usuario não foi encontrado${RESET}"; return 1; }
    echo -ne "\n${GREEN}Novo limite para ${YELLOW}$usuario${WHITE}: "; read sshnum
    [[ -z $sshnum ]] || (echo $sshnum | egrep [^0-9] &>/dev/null) || [[ $sshnum -lt 1 ]] && { echo -e "\n${BG_RED}Número inválido!${RESET}"; return 1; }
    grep -v ^$usuario[[:space:]] $KRATOS_DB > /tmp/a; sleep 1; mv /tmp/a $KRATOS_DB
    echo "$usuario $sshnum" >> $KRATOS_DB
    echo -e "\n${BG_BLUE}Limite aplicado para $usuario: $sshnum ${RESET}"
    sleep 2
}

# ============================================================
# ALTERAR SENHA
# ============================================================
alterarsenha() {
    clear
    echo -e "${BG_BLUE}       ALTERAR SENHA DE USUÁRIO - KRATOS-SSH     ${RESET}"
    echo ""
    echo -e "${YELLOW}LISTA DE USUARIOS E SUAS SENHAS: ${RESET}"
    echo ""
    local _userT i _userPass
    _userT=$(awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody)
    i=0; unset _userPass
    while read _user; do
        i=$(expr $i + 1); _oP=$i
        [[ $i == [1-9] ]] && i=0$i
        local _senha suser ssenha
        [[ -e "$KRATOS_SENHA_DIR/$_user" ]] && _senha="$(cat $KRATOS_SENHA_DIR/$_user)" || _senha='Null'
        suser=$(echo -e "${RED}[${CYAN}$i${RED}] ${WHITE}- ${GREEN}$_user${RESET}")
        ssenha=$(echo -e "${YELLOW}Senha${WHITE}: $_senha")
        printf '%-60s%s\n' "$suser" "$ssenha"
        _userPass+="\n${_oP}:${_user}"
    done <<< "${_userT}"
    echo ""
    local num_user option user password
    num_user=$(awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody | wc -l)
    echo -ne "${GREEN}Selecione um usuário ${YELLOW}[${CYAN}1${RED}-${CYAN}$num_user${YELLOW}]${WHITE}: "; read option
    user=$(echo -e "${_userPass}" | grep -E "\b$option\b" | cut -d: -f2)
    [[ -z $option ]] || [[ -z $user ]] && { echo -e "\n${BG_RED}Usuário inválido!${RESET}"; return 1; }
    [[ $(grep -c "/$user:" /etc/passwd) -eq 0 ]] && { echo -e "\n${BG_RED}O usuário $user não existe!${RESET}"; return 1; }
    echo -ne "\n${GREEN}Nova senha para ${YELLOW}$user${WHITE}: "; read password
    [[ ${#password} -lt 4 ]] && { echo -e "\n${BG_RED}Senha inválida! use no mínimo 4 caracteres${RESET}"; return 1; }
    pkill -f $user > /dev/null 2>&1
    echo "$user:$password" | chpasswd
    echo -e "\n${BG_BLUE}Senha do usuário $user alterada para: $password ${RESET}"
    echo "$password" > $KRATOS_SENHA_DIR/$user
}

# ============================================================
# REMOVER EXPIRADOS
# ============================================================
expcleaner() {
    local datenow
    datenow=$(date +%s)
    remove_ovp_exp() {
        [[ -e /etc/debian_version ]] && GROUPNAME=nogroup
        local user="$1"
        cd /etc/openvpn/easy-rsa/ 2>/dev/null && {
            ./easyrsa --batch revoke $user
            ./easyrsa gen-crl
            rm -rf pki/reqs/$user.req pki/private/$user.key pki/issued/$user.crt /etc/openvpn/crl.pem
            cp /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/crl.pem
            chown nobody:$GROUPNAME /etc/openvpn/crl.pem
        } > /dev/null 2>&1
    }
    echo -e "${BG_BLUE} Usuario          Data         Estado         Ação   ${RESET}"
    echo ""
    local exp_count=0
    for user in $(awk -F: '{print $1}' /etc/passwd); do
        local expdate datanormal expsec diff
        expdate=$(chage -l $user 2>/dev/null | awk -F: '/Account expires/{print $2}')
        echo $expdate | grep -q never && continue
        datanormal=$(date -d"$expdate" '+%d/%m/%Y' 2>/dev/null) || continue
        tput setaf 3; tput bold; printf '%-15s%-17s%s' $user $datanormal; tput sgr0
        expsec=$(date +%s --date="$expdate" 2>/dev/null) || { echo " VALIDO   NAO REMOVIDO"; continue; }
        diff=$(echo $datenow - $expsec | bc -l)
        if echo $diff | grep -q ^\\-; then
            tput setaf 2; tput bold; echo " VALIDO   NAO REMOVIDO"; tput sgr0
        else
            tput setaf 1; tput bold; echo " VENCEU   FOI REMOVIDO"; tput sgr0
            pkill -f $user 2>/dev/null
            userdel --force $user 2>/dev/null
            grep -v ^$user[[:space:]] $KRATOS_DB > /tmp/ph; cat /tmp/ph > $KRATOS_DB
            rm $KRATOS_SENHA_DIR/$user 2>/dev/null
            [[ -e /etc/openvpn/server.conf ]] && remove_ovp_exp $user
            exp_count=$((exp_count + 1))
        fi
    done
    echo '0' > $KRATOS_DIR/Exp
    tput sgr0
    echo ""
    echo -e "${GREEN}[KRATOS-SSH]${WHITE} Limpeza concluída. ${RED}$exp_count${WHITE} usuário(s) removido(s).${RESET}"
}

expcleaner_auto() {
    # Versão silenciosa para cron
    local datenow=$(date +%s)
    local exp_count=0
    for user in $(awk -F: '{print $1}' /etc/passwd); do
        local expdate expsec diff
        expdate=$(chage -l $user 2>/dev/null | awk -F: '/Account expires/{print $2}')
        echo $expdate | grep -q never && continue
        expsec=$(date +%s --date="$expdate" 2>/dev/null) || continue
        diff=$(echo $datenow - $expsec | bc -l)
        if ! echo $diff | grep -q ^\\-; then
            pkill -f $user 2>/dev/null
            userdel --force $user 2>/dev/null
            grep -v ^$user[[:space:]] $KRATOS_DB > /tmp/ph; cat /tmp/ph > $KRATOS_DB
            rm $KRATOS_SENHA_DIR/$user 2>/dev/null
            exp_count=$((exp_count + 1))
        fi
    done
    echo $exp_count > $KRATOS_DIR/Exp
}

# ============================================================
# BANNER SSH
# ============================================================
banner() {
    local local chk
    chk=$(cat /etc/ssh/sshd_config | grep Banner)
    [[ $(netstat -nltp 2>/dev/null | grep 'dropbear' | wc -l) != '0' ]] && {
        local="/etc/bannerssh"
        [[ $(grep -wc $local /etc/default/dropbear 2>/dev/null) = '0' ]] && \
            echo 'DROPBEAR_BANNER="/etc/bannerssh"' >> /etc/default/dropbear
    }
    [[ "$(echo "$chk" | grep -v '#Banner' | grep Banner)" != "" ]] && {
        local=$(echo "$chk" | grep -v "#Banner" | grep Banner | awk '{print $2}')
    } || {
        local="/etc/bannerssh"
        [[ $(grep -wc $local /etc/ssh/sshd_config) = '0' ]] && echo "Banner /etc/bannerssh" >> /etc/ssh/sshd_config
    }

    clear
    echo -e "${BG_BLUE}              BANNER SSH - KRATOS-SSH           ${RESET}"
    echo ""
    echo -e "${RED}[${CYAN}1${RED}]${WHITE} • ${YELLOW}ADICIONAR/EDITAR BANNER"
    echo -e "${RED}[${CYAN}2${RED}]${WHITE} • ${YELLOW}APLICAR BANNER PADRAO KRATOS-SSH"
    echo -e "${RED}[${CYAN}3${RED}]${WHITE} • ${YELLOW}REMOVER BANNER"
    echo -e "${RED}[${CYAN}4${RED}]${WHITE} • ${YELLOW}VOLTAR"
    echo ""
    echo -ne "${GREEN}OQUE DESEJA FAZER${RED} ?${WHITE} : "; read resp

    if [[ "$resp" = "1" ]]; then
        echo ""
        echo -ne "${GREEN}QUAL MENSAGEM DESEJA EXIBIR${RED} ?${WHITE} : "; read msg1
        [[ -z "$msg1" ]] && { echo -e "\n${RED}Campo vazio!${RESET}"; sleep 2; banner; return; }
        echo -e "\n${RED}[${CYAN}01${RED}]${YELLOW} FONTE PEQUENA"
        echo -e "${RED}[${CYAN}02${RED}]${YELLOW} FONTE MEDIA"
        echo -e "${RED}[${CYAN}03${RED}]${YELLOW} FONTE GRANDE"
        echo -e "${RED}[${CYAN}04${RED}]${YELLOW} FONTE GIGANTE"
        echo ""
        echo -ne "${GREEN}TAMANHO DA FONTE${RED} ?${WHITE} : "; read opc
        case $opc in
            1|01) _size='6' ;; 2|02) _size='4' ;; 3|03) _size='3' ;; 4|04) _size='1' ;;
        esac
        echo -e "\n${RED}[${CYAN}01${RED}]${YELLOW} VERMELHO  ${RED}[${CYAN}02${RED}]${YELLOW} VERDE     ${RED}[${CYAN}03${RED}]${YELLOW} AZUL"
        echo -e "${RED}[${CYAN}04${RED}]${YELLOW} AMARELO   ${RED}[${CYAN}05${RED}]${YELLOW} ROSA      ${RED}[${CYAN}06${RED}]${YELLOW} CYANO"
        echo -e "${RED}[${CYAN}07${RED}]${YELLOW} LARANJA   ${RED}[${CYAN}08${RED}]${YELLOW} ROXO      ${RED}[${CYAN}09${RED}]${YELLOW} PRETO     ${RED}[${CYAN}10${RED}]${YELLOW} SEM COR"
        echo ""
        echo -ne "${GREEN}QUAL A COR${RED} ?${WHITE} : "; read ban_cor
        case $ban_cor in
            1|01) echo "<h$_size><font color='red'>$msg1</font></h$_size>" >> $local ;;
            2|02) echo "<h$_size><font color='green'>$msg1</font></h$_size>" >> $local ;;
            3|03) echo "<h$_size><font color='blue'>$msg1</font></h$_size>" >> $local ;;
            4|04) echo "<h$_size><font color='yellow'>$msg1</font></h$_size>" >> $local ;;
            5|05) echo "<h$_size><font color='#F535AA'>$msg1</font></h$_size>" >> $local ;;
            6|06) echo "<h$_size><font color='cyan'>$msg1</font></h$_size>" >> $local ;;
            7|07) echo "<h$_size><font color='#FF7F00'>$msg1</font></h$_size>" >> $local ;;
            8|08) echo "<h$_size><font color='#9932CD'>$msg1</font></h$_size>" >> $local ;;
            9|09) echo "<h$_size><font color='black'>$msg1</font></h$_size>" >> $local ;;
            10)   echo "<h$_size>$msg1</h$_size>" >> $local ;;
        esac
        service ssh restart > /dev/null 2>&1 && service dropbear restart > /dev/null 2>&1
        echo -e "\n${GREEN}BANNER DEFINIDO !${RESET}"

    elif [[ "$resp" = "2" ]]; then
        kratos_banner_ssh
        service ssh restart > /dev/null 2>&1 && service dropbear restart > /dev/null 2>&1
        echo -e "\n${GREEN}BANNER PADRÃO KRATOS-SSH APLICADO !${RESET}"
        sleep 2; banner

    elif [[ "$resp" = "3" ]]; then
        echo " " > $local
        echo -e "\n${GREEN}BANNER EXCLUIDO !${RESET}"
        service ssh restart > /dev/null 2>&1 && service dropbear restart > /dev/null 2>&1
        sleep 2; menu

    elif [[ "$resp" = "4" ]]; then
        menu
    else
        echo -e "\n${RED}Opcao invalida !${RESET}"; sleep 2; banner
    fi
}

# ============================================================
# BADVPN
# ============================================================
badvpn() {
    clear
    fun_udp1() {
        [[ -e "/bin/badvpn-udpgw" ]] && {
            clear
            echo -e "${GREEN}INICIANDO O BADVPN... ${RESET}\n"
            fun_udpon() {
                screen -dmS udpvpn /bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 10
                [[ $(grep -wc "udpvpn" $KRATOS_AUTOSTART) = '0' ]] && {
                    echo "ps x | grep 'udpvpn' | grep -v 'grep' || screen -dmS udpvpn /bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 10000 --max-connections-for-client 10 --client-socket-sndbuf 10000" >> $KRATOS_AUTOSTART
                } || {
                    sed -i '/udpvpn/d' $KRATOS_AUTOSTART
                    echo "ps x | grep 'udpvpn' | grep -v 'grep' || screen -dmS udpvpn /bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 10000 --max-connections-for-client 10 --client-socket-sndbuf 10000" >> $KRATOS_AUTOSTART
                }
                sleep 1
            }
            fun_bar 'fun_udpon'
            echo -e "\n  ${GREEN}BADVPN ATIVO !${RESET}"
            sleep 3; menu
        } || {
            clear
            echo -e "${GREEN}INSTALANDO O BADVPN !${RESET}\n"
            inst_udp() {
                cd $HOME
                # Tentar do diretório local primeiro
                [[ -e /etc/kratos-ssh/badvpn-udpgw ]] && \
                    cp /etc/kratos-ssh/badvpn-udpgw /bin/badvpn-udpgw || \
                    wget -q https://www.dropbox.com/s/tgkxdwb03r7w59r/badvpn-udpgw -O /bin/badvpn-udpgw
                chmod 777 /bin/badvpn-udpgw
            }
            fun_bar 'inst_udp'
            echo -e "\n${GREEN}INICIANDO O BADVPN... ${RESET}\n"
            fun_udpon2() {
                screen -dmS udpvpn /bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 10
                [[ $(grep -wc "udpvpn" $KRATOS_AUTOSTART) = '0' ]] && {
                    echo "ps x | grep 'udpvpn' | grep -v 'grep' || screen -dmS udpvpn /bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 10000 --max-connections-for-client 10 --client-socket-sndbuf 10000" >> $KRATOS_AUTOSTART
                } || {
                    sed -i '/udpvpn/d' $KRATOS_AUTOSTART
                    echo "ps x | grep 'udpvpn' | grep -v 'grep' || screen -dmS udpvpn /bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 10000 --max-connections-for-client 10 --client-socket-sndbuf 10000" >> $KRATOS_AUTOSTART
                }
                sleep 1
            }
            fun_bar 'fun_udpon2'
            echo -e "\n${GREEN}BADVPN ATIVO !${RESET}"
            sleep 3; menu
        }
    }
    fun_udp2() {
        clear
        echo -e "\n${RED}PARANDO O BADVPN...${RESET}\n"
        fun_stopbad() {
            sleep 1
            screen -r -S "udpvpn" -X quit
            screen -wipe 1>/dev/null 2>/dev/null
            [[ $(grep -wc "udpvpn" $KRATOS_AUTOSTART) != '0' ]] && sed -i '/udpvpn/d' $KRATOS_AUTOSTART
            sleep 1
        }
        fun_bar 'fun_stopbad'
        echo -e "\n  ${RED}BADVPN PARADO !${RESET}"
        sleep 3; menu
    }
    [[ $(ps x | grep "udpvpn" | grep -v grep | wc -l) = '0' ]] && fun_udp1 || fun_udp2
}

# ============================================================
# BOT SSH TELEGRAM
# ============================================================
botssh() {
    clear
    fun_botOnOff() {
        [[ $(ps x | grep "bot_plus" | grep -v grep | wc -l) = '0' ]] && {
            clear
            echo -e "${BG_BLUE}          INSTALADOR BOT - KRATOS-SSH           ${RESET}\n"
            echo -e "  ${YELLOW}[${RED}!${YELLOW}] ${RED}ATENCAO ${YELLOW}[${RED}!${YELLOW}]${RESET}"
            echo -e "\n${GREEN}1°${WHITE} - Acesse ${YELLOW}@BotFather${WHITE} no Telegram e crie seu bot com ${YELLOW}/newbot${RESET}"
            echo -e "${GREEN}2°${WHITE} - Pegue o TOKEN gerado pelo BotFather${RESET}"
            echo -e "${GREEN}3°${WHITE} - Acesse ${YELLOW}@userinfobot${WHITE} para obter seu ID${RESET}"
            echo -e "${LINE}"
            echo ""
            read -p "$(echo -e "${GREEN}DESEJA CONTINUAR? ${YELLOW}[s/n]: ${RESET}")" -e -i s resposta
            [[ "$resposta" != 's' ]] && { echo -e "\n${RED}Retornando...${RESET}"; sleep 2; menu; return; }
            echo ""
            echo -ne "${GREEN}INFORME SEU TOKEN:${WHITE} "; read tokenbot
            echo ""
            echo -ne "${GREEN}INFORME SEU ID:${WHITE} "; read iduser
            clear
            echo -e "${GREEN}INICIANDO BOT KRATOS-SSH ${RESET}\n"
            fun_bot1() {
                [[ ! -e "$KRATOS_DIR/ShellBot.sh" ]] && \
                    wget -qO $KRATOS_DIR/ShellBot.sh https://raw.githubusercontent.com/shellscriptx/shellbot/master/ShellBot.sh
                cd $KRATOS_DIR
                screen -dmS bot_plus ./bot $tokenbot $iduser > /dev/null 2>&1
                [[ $(grep -wc "bot_plus" $KRATOS_AUTOSTART) = '0' ]] && {
                    echo "ps x | grep 'bot_plus' | grep -v 'grep' || cd $KRATOS_DIR && screen -dmS bot_plus ./bot $tokenbot $iduser && cd $HOME" >> $KRATOS_AUTOSTART
                } || {
                    sed -i '/bot_plus/d' $KRATOS_AUTOSTART
                    echo "ps x | grep 'bot_plus' | grep -v 'grep' || cd $KRATOS_DIR && screen -dmS bot_plus ./bot $tokenbot $iduser && cd $HOME" >> $KRATOS_AUTOSTART
                }
                cd $HOME
            }
            fun_bar 'fun_bot1'
            [[ $(ps x | grep "bot_plus" | grep -v grep | wc -l) != '0' ]] && \
                echo -e "\n${GREEN} BOT KRATOS-SSH ATIVADO !${RESET}" || \
                echo -e "\n${RED} ERRO! VERIFIQUE SEU TOKEN E ID${RESET}"
            sleep 2; menu
        } || {
            clear
            echo -e "${RED}PARANDO BOT KRATOS-SSH... ${RESET}\n"
            fun_bot2() {
                screen -r -S "bot_plus" -X quit
                screen -wipe 1>/dev/null 2>/dev/null
                [[ $(grep -wc "bot_plus" $KRATOS_AUTOSTART) != '0' ]] && sed -i '/bot_plus/d' $KRATOS_AUTOSTART
                sleep 1
            }
            fun_bar 'fun_bot2'
            echo -e "\n${RED} BOT KRATOS-SSH PARADO! ${RESET}"
            sleep 2; menu
        }
    }
    fun_botOnOff
}

# ============================================================
# SLOW DNS
# ============================================================
slow_dns() {
    local DIR="$KRATOS_DNS_DIR"

    configdns() {
        local interface
        interface=$(ip a | awk '/state UP/{print $2}' | cut -d: -f1 | head -1)
        iptables -I INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null
        iptables -t nat -I PREROUTING -i $interface -p udp --dport 53 -j REDIRECT --to-ports 5300 2>/dev/null
        ip6tables -I INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null
        ip6tables -t nat -I PREROUTING -i $interface -p udp --dport 53 -j REDIRECT --to-ports 5300 2>/dev/null
    }

    installslowdns() {
        clear
        echo -e "${BG_RED}           KRATOS-SSH SLOWDNS (Beta)           ${RESET}"
        echo -e "\n${YELLOW}ESTE METODO ESTA NA FASE BETA.\nPODE SER LENTO OU NAO FUNCIONAR PERFEITAMENTE.${RESET}\n"
        echo -ne "${GREEN}DESEJA CONTINUAR A INSTALACAO? ${YELLOW}[s/n]:${RESET} "; read resp
        [[ "$resp" != @(s|sim|S|SIM) ]] && { echo -e "\n${RED}Retornando...${RESET}"; sleep 2; conexao; return; }
        mkdir -p $DIR
        wget -qP $DIR https://github.com/kratos-ssh/dns-tools/releases/latest/download/dns-server 2>/dev/null || \
            wget -qP $DIR http://kratos-ssh.net/scripts/slow-dns/dns-server 2>/dev/null
        chmod 777 $DIR/dns-server 2>/dev/null
        $DIR/dns-server -gen-key -privkey-file $DIR/server.key -pubkey-file $DIR/server.pub 2>/dev/null
        configdns > /dev/null 2>&1
    }

    initslow() {
        [[ $(ss -lu 2>/dev/null | grep -wc '5300') != '0' ]] && {
            clear
            echo -e "${BG_RED}           KRATOS-SSH SLOWDNS (Beta)           ${RESET}"
            echo ""
            echo -e "${RED}[${CYAN}1${RED}] ${YELLOW}PARAR O SLOWDNS"
            echo -e "${RED}[${CYAN}2${RED}] ${YELLOW}REMOVER O SLOWDNS"
            echo -e "${RED}[${CYAN}3${RED}] ${YELLOW}EXIBIR INFORMACOES"
            echo -e "${RED}[${CYAN}0${RED}] ${YELLOW}VOLTAR${RESET}"
            echo -ne "\n${GREEN}INFORME UMA OPCAO${RESET}: "; read op
            case "$op" in
                1)
                    screen -r -S "slow_dns" -X quit >/dev/null 2>&1
                    screen -wipe >/dev/null 2>&1
                    sed -i '/5300/d' $KRATOS_AUTOSTART >/dev/null 2>&1
                    echo -e "\n${RED}SLOWDNS DESATIVADO !${RESET}"; sleep 2; conexao ;;
                2)
                    screen -r -S "slow_dns" -X quit >/dev/null 2>&1
                    screen -wipe >/dev/null 2>&1
                    sed -i '/5300/d' $KRATOS_AUTOSTART >/dev/null 2>&1
                    rm -rf $DIR >/dev/null 2>&1
                    echo -e "\n${RED}SLOWDNS REMOVIDO !${RESET}"; sleep 2; conexao ;;
                3)
                    local keypub nameserver tmx
                    [[ -e $DIR/server.pub ]] && keypub=$(cat $DIR/server.pub) || keypub='Null'
                    [[ -e $DIR/autodns ]] && nameserver=$(grep -w 'server.key' $KRATOS_DIR/dns/autodns | awk -F' ' '{print $9}') || nameserver='Null'
                    tmx="curl -sO https://raw.githubusercontent.com/kratos-ssh/slowdns/main/slowdns && chmod +x slowdns && ./slowdns"
                    clear
                    echo -e "${BG_RED}           KRATOS-SSH SLOWDNS (Beta)           ${RESET}"
                    echo -e "\n${YELLOW}NAMESERVER(NS)${RESET}: $nameserver"
                    echo -e "${YELLOW}CHAVE PUBLICA${RESET}: $keypub"
                    echo -e "\n${GREEN}COMANDO TERMUX${RESET}: ${tmx} ${nameserver} ${keypub}"
                    echo -ne "\n${RED}ENTER${YELLOW} para retornar ao${GREEN} MENU!${RESET}"; read; conexao ;;
                0) sleep 1; conexao ;;
                *) echo -e "\n${RED}OPCAO INVALIDA${RESET}"; sleep 1.5; conexao ;;
            esac
        } || {
            clear
            echo -e "${BG_RED}           KRATOS-SSH SLOWDNS (Beta)           ${RESET}"
            echo -ne "\n${GREEN}INFORME O DOMINIO NS${RESET}: "; read ns
            [[ -z "$ns" ]] && { echo -e "\n${RED}DOMINIO INVALIDO${RESET}"; sleep 1.5; initslow; return; }
            echo ""
            echo -e "${RED}[${CYAN}1${RED}] ${YELLOW}SLOWDNS SSH"
            echo -e "${RED}[${CYAN}2${RED}] ${YELLOW}SLOWDNS SSL"
            echo -e "${RED}[${CYAN}3${RED}] ${YELLOW}SLOWDNS SSLH"
            echo -e "${RED}[${CYAN}4${RED}] ${YELLOW}SLOWDNS OPENVPN"
            echo -e "${RED}[${CYAN}0${RED}] ${YELLOW}VOLTAR${RESET}"
            echo -ne "\n${GREEN}INFORME UMA OPCAO${RESET}: "; read opcc
            local ptdns
            case "$opcc" in
                1) ptdns='22' ;;
                2)
                    ptdns=$(netstat -nplt 2>/dev/null | grep 'stunnel' | awk {'print $4'} | cut -d: -f2)
                    [[ -z $ptdns ]] && { echo -e "\n${RED}PRIMEIRO INSTALE O SSL TUNNEL !${RESET}"; sleep 1.5; initslow; return; } ;;
                3)
                    ptdns=$(netstat -nplt 2>/dev/null | grep 'sslh' | awk {'print $4'} | cut -d: -f2)
                    [[ -z $ptdns ]] && { echo -e "\n${RED}PRIMEIRO INSTALE O SSLH !${RESET}"; sleep 1.5; initslow; return; } ;;
                4)
                    [[ ! -e /etc/openvpn/server.conf ]] && { echo -e "\n${RED}PRIMEIRO INSTALE O OPENVPN !${RESET}"; sleep 1.5; initslow; return; }
                    ptdns=$(sed -n 1p /etc/openvpn/server.conf | cut -d' ' -f2) ;;
                0) sleep 1.5; conexao; return ;;
                *) echo -e "\n${RED}OPCAO INVALIDA${RESET}"; sleep 1.5; initslow; return ;;
            esac
            screen -dmS slow_dns $DIR/dns-server -udp :5300 -privkey-file $DIR/server.key ${ns} 0.0.0.0:${ptdns} >/dev/null 2>&1
            local keypub tmx
            keypub=$(cat $DIR/server.pub)
            configdns > /dev/null 2>&1
            echo "screen -dmS slow_dns $DIR/dns-server -udp :5300 -privkey-file $DIR/server.key ${ns} 0.0.0.0:${ptdns}" > $DIR/autodns
            chmod 777 $DIR/autodns >/dev/null 2>&1
            echo "ss -lu 2>/dev/null|grep -w '5300' || $DIR/autodns" >> $KRATOS_AUTOSTART
            tmx="curl -sO https://raw.githubusercontent.com/kratos-ssh/slowdns/main/slowdns && chmod +x slowdns && ./slowdns"
            echo -e "\n${GREEN}SLOWDNS ATIVADO !${RESET}"
            echo -e "\n${YELLOW}COMANDO TERMUX${RESET}: ${tmx} ${ns} ${keypub}"
            echo -ne "\n${RED}ENTER${YELLOW} para retornar ao${GREEN} MENU!${RESET}"; read; conexao
        }
    }

    [[ -d $DIR ]] && initslow || { installslowdns; sleep 0.5; initslow; }
}

# ============================================================
# OTIMIZAR SERVIDOR
# ============================================================
otimizar() {
    [[ $(grep -wc mlocate /var/lib/dpkg/statoverride 2>/dev/null) != '0' ]] && sed -i '/mlocate/d' /var/lib/dpkg/statoverride
    clear
    echo -e "${BG_BLUE}           OTIMIZAR SERVIDOR - KRATOS-SSH        ${RESET}"
    echo ""
    echo -e "${GREEN}               Atualizando pacotes${RESET}"; echo ""
    fun_bar 'apt-get update -y' 'apt-get upgrade -y'
    echo ""; echo -e "${GREEN}      Corrigindo problemas de dependências${RESET}"; echo ""
    fun_bar 'apt-get -f install'
    echo ""; echo -e "${GREEN}            Removendo pacotes inúteis${RESET}"; echo ""
    fun_bar 'apt-get autoremove -y' 'apt-get autoclean -y'
    echo ""; echo -e "${GREEN}        Removendo pacotes com problemas${RESET}"; echo ""
    fun_bar 'apt-get -f remove -y' 'apt-get clean -y'

    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    local MEM1=$(free | awk '/Mem:/ {print int(100*$3/$2)}')
    local ram1=$(free -h | grep -i mem | awk {'print $2'})
    local ram2=$(free -h | grep -i mem | awk {'print $4'})
    local ram3=$(free -h | grep -i mem | awk {'print $3'})
    local swap1=$(free -h | grep -i swap | awk {'print $2'})
    local swap2=$(free -h | grep -i swap | awk {'print $4'})
    local swap3=$(free -h | grep -i swap | awk {'print $3'})
    echo -e "${RED}•${GREEN}Memoria RAM${RED}•${RESET}                    ${RED}•${GREEN}Swap${RED}•${RESET}"
    echo -e " ${YELLOW}Total: ${WHITE}$ram1                   ${YELLOW}Total: ${WHITE}$swap1"
    echo -e " ${YELLOW}Em Uso: ${WHITE}$ram3                  ${YELLOW}Em Uso: ${WHITE}$swap3"
    echo -e " ${YELLOW}Livre: ${WHITE}$ram2                   ${YELLOW}Livre: ${WHITE}$swap2${RESET}"
    echo -e "\n${WHITE}Memória ${GREEN}RAM ${WHITE}Antes da Otimização:${CYAN}" $MEM1%
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    sleep 2; echo ""

    fun_limpram() {
        sync; echo 3 > /proc/sys/vm/drop_caches; sync && sysctl -w vm.drop_caches=3 > /dev/null 2>&1
        sysctl -w vm.drop_caches=0 > /dev/null 2>&1; swapoff -a; swapon -a; sleep 4
    }
    echo -ne "${WHITE}LIMPANDO MEMORIA ${GREEN}RAM ${WHITE}e ${GREEN}SWAP${GREEN}.${YELLOW}.${RED}. ${YELLOW}"
    fun_limpram &
    while [ -d /proc/$! ]; do for i in / - \\ \|; do sleep .1; echo -ne "\e[1D$i"; done; done
    echo -e "\e[1DOk"

    sleep 1; clear
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    local MEM2=$(free | awk '/Mem:/ {print int(100*$3/$2)}')
    ram2=$(free -h | grep -i mem | awk {'print $4'})
    ram3=$(free -h | grep -i mem | awk {'print $3'})
    swap2=$(free -h | grep -i swap | awk {'print $4'})
    swap3=$(free -h | grep -i swap | awk {'print $3'})
    echo -e "${RED}•${GREEN}Memoria RAM${RED}•${RESET}                    ${RED}•${GREEN}Swap${RED}•${RESET}"
    echo -e " ${YELLOW}Em Uso: ${WHITE}$ram3                  ${YELLOW}Em Uso: ${WHITE}$swap3"
    echo -e " ${YELLOW}Livre: ${WHITE}$ram2                   ${YELLOW}Livre: ${WHITE}$swap2${RESET}"
    echo ""
    echo -e "${WHITE}Memória ${GREEN}RAM ${WHITE}após a Otimização:${CYAN}" $MEM2%
    echo -e "${WHITE}Economia de: ${RED}$(expr $MEM1 - $MEM2)%${RESET}"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

# ============================================================
# BACKUP DE USUARIOS
# ============================================================
userbackup() {
    local backbot="$1"
    clear

    [[ -z $backbot ]] && {
        local IP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || curl -s ipv4.icanhazip.com)

        echo -e "${BG_BLUE}         GERENCIADOR DE BACKUPS - KRATOS-SSH     ${RESET}"
        echo ""
        echo -e "${RED}[${CYAN}1${RED}] ${WHITE}• ${YELLOW}CRIAR BACKUP"
        echo -e "${RED}[${CYAN}2${RED}] ${WHITE}• ${YELLOW}RESTAURAR BACKUP"
        echo -e "${RED}[${CYAN}3${RED}] ${WHITE}• ${YELLOW}VOLTAR${WHITE}"
        echo ""
        echo -ne "${GREEN}OQUE DESEJA FAZER${RED} ?${WHITE} : "; read opcao

        if [[ "$opcao" = '1' ]]; then
            rm -rf $HOME/backup.vps > /dev/null 2>&1
            sleep 1
            tar cvf /root/backup.vps /root/usuarios.db /etc/shadow /etc/passwd /etc/group /etc/gshadow $KRATOS_SENHA_DIR > /dev/null 2>&1
            echo ""
            echo -e "${GREEN}BACKUP CRIADO COM SUCESSO !${RESET}"
            echo ""
            echo -ne "${GREEN}GERAR LINK PARA DOWNLOAD ${RED}? ${YELLOW}[s/n]:${WHITE} "; read resp
            if [[ "$resp" = "s" ]]; then
                # Tentar ativar apache para link de download
                if ! netstat -nltp 2>/dev/null | grep 'apache2' > /dev/null; then
                    apt-get install apache2 -y > /dev/null 2>&1
                    sed -i "s/Listen 80/Listen 81/g" /etc/apache2/ports.conf 2>/dev/null
                    service apache2 restart > /dev/null 2>&1
                fi
                [[ ! -d /var/www/html/backup ]] && mkdir -p /var/www/html/backup
                cp $HOME/backup.vps /var/www/html/backup/backup.vps
                chmod -R 755 /var/www
                echo -e "${GREEN}LINK${WHITE}: ${CYAN}$IP:81/backup/backup.vps${RESET}"
            else
                echo -e "\n${GREEN}Disponível em ${RED}~/backup.vps${RESET}"
            fi

        elif [[ "$opcao" = '2' ]]; then
            if [[ -f "/root/backup.vps" ]]; then
                echo ""
                echo -e "${CYAN}Restaurando backup...${RESET}"
                sleep 2
                cp /root/backup.vps /backup.vps
                cd / && tar -xvf backup.vps > /dev/null 2>&1
                rm /backup.vps
                echo -e "\n${GREEN}Usuários e senhas importados com sucesso.${RESET}"
            else
                echo -e "\n${YELLOW}Arquivo backup.vps não encontrado em /root/${RESET}"
            fi

        elif [[ "$opcao" = '3' ]]; then
            menu
        fi
    } || {
        # Chamado pelo bot - backup silencioso
        rm /root/backup.vps 1>/dev/null 2>/dev/null
        tar cvf /root/backup.vps /root/usuarios.db /etc/shadow /etc/passwd /etc/group /etc/gshadow $KRATOS_SENHA_DIR > /dev/null 2>&1
        [[ -d "$KRATOS_DIR/backups" ]] && mv /root/backup.vps $KRATOS_DIR/backups/backup.vps
    }
}

# ============================================================
# BLOCKT - BLOQUEIO DE TORRENT
# ============================================================
blockt() {
    clear
    local IP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null)
    local arq="/etc/Plus-torrent"
    echo -e "${BG_BLUE}       FIREWALL BLOQUEIO TORRENT - KRATOS-SSH    ${RESET}"
    echo ""
    if [[ -e "$arq" ]]; then
        fun_fireoff() {
            iptables -P INPUT ACCEPT; iptables -P OUTPUT ACCEPT; iptables -P FORWARD ACCEPT
            iptables -t mangle -F; iptables -t mangle -X; iptables -t nat -F; iptables -t nat -X
            iptables -t filter -F; iptables -t filter -X; iptables -F; iptables -X
            rm $arq; sleep 3
        }
        echo -ne "${RED}DESATIVANDO BLOQUEIO DE TORRENT${GREEN}.${YELLOW}.${RED}. ${YELLOW}"
        fun_fireoff &
        while [ -d /proc/$! ]; do for i in / - \\ \|; do sleep .1; echo -ne "\e[1D$i"; done; done
        echo -e "\e[1DOk"
        echo -e "\n${GREEN}BLOQUEIO DESATIVADO !${RESET}"
    else
        fun_fireon() {
            touch $arq
            iptables -P INPUT ACCEPT; iptables -P FORWARD ACCEPT; iptables -P OUTPUT ACCEPT
            # Bloquear portas BitTorrent comuns
            for port in 6881 6882 6883 6884 6885 6886 6887 6888 6889 6890; do
                iptables -A OUTPUT -p tcp --dport $port -j DROP
                iptables -A OUTPUT -p udp --dport $port -j DROP
                iptables -A INPUT -p tcp --dport $port -j DROP
            done
            iptables -A OUTPUT -p tcp --dport 6969 -j DROP
            iptables -A OUTPUT -p udp --dport 6969 -j DROP
            sleep 3
        }
        echo -ne "${GREEN}ATIVANDO BLOQUEIO DE TORRENT${GREEN}.${YELLOW}.${RED}. ${YELLOW}"
        fun_fireon &
        while [ -d /proc/$! ]; do for i in / - \\ \|; do sleep .1; echo -ne "\e[1D$i"; done; done
        echo -e "\e[1DOk"
        echo -e "\n${GREEN}BLOQUEIO DE TORRENT ATIVO !${RESET}"
    fi
    sleep 2; menu
}

# ============================================================
# DETALHES / INFO VPS
# ============================================================
detalhes() {
    clear
    echo -e "${BG_BLUE}           INFORMAÇÕES DO VPS - KRATOS-SSH       ${RESET}"
    echo ""
    # Sistema Operacional
    echo -e "${RED}• ${GREEN}SISTEMA OPERACIONAL${RED} •${RESET}"; echo ""
    if [[ -f /etc/lsb-release ]]; then
        local name codename devlike
        name=$(cat /etc/lsb-release | grep DESCRIPTION | awk -F= {'print $2'})
        codename=$(cat /etc/lsb-release | grep CODENAME | awk -F= {'print $2'})
        echo -e "${YELLOW}Nome: ${WHITE}$name"
        echo -e "${YELLOW}CodeName: ${WHITE}$codename"
        echo -e "${YELLOW}Kernel: ${WHITE}$(uname -s)"
        echo -e "${YELLOW}Kernel Release: ${WHITE}$(uname -r)"
        [[ -f /etc/os-release ]] && {
            devlike=$(cat /etc/os-release | grep LIKE | awk -F= {'print $2'})
            echo -e "${YELLOW}Derivado do OS: ${WHITE}$devlike"
        }
    else
        echo -e "${YELLOW}Nome: ${WHITE}$(cat /etc/issue.net)"
    fi
    echo ""
    # Processador
    [[ -f /proc/cpuinfo ]] && {
        echo -e "${RED}• ${GREEN}PROCESSADOR${RED} •${RESET}"; echo ""
        echo -e "${YELLOW}Modelo:${WHITE}$(cat /proc/cpuinfo | grep "model name" | uniq | awk -F: {'print $2'})"
        echo -e "${YELLOW}Núcleos:${WHITE} $(grep -c cpu[0-9] /proc/stat)"
        echo -e "${YELLOW}Cache:${WHITE}$(cat /proc/cpuinfo | grep "cache size" | uniq | awk -F: {'print $2'})"
        echo -e "${YELLOW}Arquitetura: ${WHITE}$(uname -p)"
        echo -e "${YELLOW}Utilização: ${WHITE}$(top -bn1 | awk '/Cpu/ { cpu = "" 100 - $8 "%" }; END { print cpu }')"
        echo ""
    }
    # Memória RAM
    free 1>/dev/null 2>/dev/null && {
        echo -e "${RED}• ${GREEN}MEMORIA RAM${RED} •${RESET}"; echo ""
        echo -e "${YELLOW}Total: ${WHITE}$(free -h | grep -i mem | awk {'print $2'})"
        echo -e "${YELLOW}Em Uso: ${WHITE}$(free -h | grep -i mem | awk {'print $3'})"
        echo -e "${YELLOW}Livre: ${WHITE}$(free -h | grep -i mem | awk {'print $4'})"
        echo -e "${YELLOW}Utilização: ${WHITE}$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')"
        echo ""
    }
    # Serviços
    echo -e "${RED}• ${GREEN}SERVIÇOS EM EXECUÇÃO${RED} •${RESET}"; echo ""
    local PT
    PT=$(lsof -V -i tcp -P -n 2>/dev/null | grep -v "ESTABLISHED" | grep -v "COMMAND" | grep "LISTEN")
    for porta in $(echo -e "$PT" | cut -d: -f2 | cut -d' ' -f1 | uniq); do
        local svcs
        svcs=$(echo -e "$PT" | grep -w "$porta" | awk '{print $1}' | uniq)
        echo -e "${YELLOW}Serviço ${WHITE}$svcs ${YELLOW}Porta ${WHITE}$porta"
    done
    echo ""
    # KRATOS-SSH
    echo -e "${RED}• ${GREEN}KRATOS-SSH${RED} •${RESET}"
    echo -e "${YELLOW}Versão: ${WHITE}$KRATOS_VERSION"
    echo -e "${YELLOW}Diretório: ${WHITE}$KRATOS_DIR"
    echo -e "${YELLOW}IP: ${WHITE}$(cat /etc/IP 2>/dev/null)"
}

# ============================================================
# REINICIAR SERVICOS
# ============================================================
reiniciarservicos() {
    clear
    echo -e "${BG_BLUE}        REINICIAR SERVIÇOS - KRATOS-SSH          ${RESET}"
    echo ""
    echo -ne "${YELLOW}REINICIANDO OPENSSH "; fun_prog 'service ssh restart'; echo ""
    sleep 1
    [[ -e /etc/squid/squid.conf ]] && { echo -ne "${YELLOW}REINICIANDO SQUID PROXY "; fun_prog 'service squid restart'; echo ""; sleep 1; }
    [[ -e /etc/squid3/squid.conf ]] && { echo -ne "${YELLOW}REINICIANDO SQUID3 PROXY "; fun_prog 'service squid3 restart'; echo ""; sleep 1; }
    [[ -e /etc/stunnel/stunnel.conf ]] && { echo -ne "${YELLOW}REINICIANDO SSL TUNNEL "; fun_prog 'service stunnel4 restart'; echo ""; sleep 1; }
    [[ -e /etc/init.d/dropbear ]] && { echo -ne "${YELLOW}REINICIANDO DROPBEAR "; fun_prog 'service dropbear restart'; echo ""; sleep 1; }
    [[ -e /etc/openvpn/server.conf ]] && { echo -ne "${YELLOW}REINICIANDO OPENVPN "; fun_prog 'service openvpn restart'; echo ""; sleep 1; }
    netstat -nltp 2>/dev/null | grep 'apache2' > /dev/null && { echo -ne "${YELLOW}REINICIANDO APACHE2 "; fun_prog '/etc/init.d/apache2 restart'; echo ""; sleep 1; }
    # Reiniciar proxy/websocket se ativos
    ps x | grep -w "proxy.py" | grep -v grep > /dev/null && {
        local porta=$(netstat -nplt 2>/dev/null | grep 'python' | awk {'print $4'} | cut -d: -f2 | head -1)
        echo -ne "${YELLOW}REINICIANDO PROXY SOCKS "; fun_prog "screen -r -S proxy -X quit; sleep 1; screen -dmS proxy python $KRATOS_DIR/proxy.py $porta"; echo ""
    }
    ps x | grep -w "wsproxy.py" | grep -v grep > /dev/null && {
        local porta=$(netstat -nplt 2>/dev/null | grep 'python' | awk {'print $4'} | cut -d: -f2 | head -1)
        echo -ne "${YELLOW}REINICIANDO WEBSOCKET "; fun_prog "screen -r -S ws -X quit; sleep 1; screen -dmS ws python $KRATOS_DIR/wsproxy.py $porta"; echo ""
    }
    echo ""
    echo -e "${GREEN}[KRATOS-SSH]${WHITE} Serviços reiniciados com sucesso!${RESET}"
    sleep 1
}

# ============================================================
# REINICIAR SISTEMA
# ============================================================
reiniciarsistema() {
    clear
    echo -e "${RED}REINICIANDO O SISTEMA...${RESET}"
    sleep 2
    reboot
}

# ============================================================
# SENHAROOT
# ============================================================
senharoot() {
    clear
    echo -e "${BG_RED}              KRATOS-SSH - SENHA ROOT           ${RESET}"
    echo ""
    echo -e "${RED}ATENÇÃO!!${RESET}"
    echo ""
    echo -e "${YELLOW}Essa senha será usada para acessar o servidor via root${RESET}"
    echo ""
    echo -ne "${GREEN}NOVA SENHA ROOT: ${WHITE}"; read -s pass
    echo ""
    (echo $pass; echo $pass) | passwd > /dev/null 2>&1
    sleep 1
    echo -e "${GREEN}SENHA ALTERADA COM SUCESSO!${RESET}"
    sleep 3; clear
}

# ============================================================
# ATTSCRIPT - ATUALIZAR KRATOS-SSH
# ============================================================
attscript() {
    clear
    echo -e "${RED}╔══════════════════════════════════════════════════╗${RESET}"
    echo -e "${RED}║${WHITE}          ATUALIZAR KRATOS-SSH v${KRATOS_VERSION}             ${RED}║${RESET}"
    echo -e "${RED}╚══════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "   ${GREEN}VERIFICANDO ATUALIZAÇÕES DISPONÍVEIS${RESET}\n"

    fun_atts() {
        [[ -e /tmp/att ]] && rm /tmp/att
        # Verificar versão no repositório
        wget -qO /tmp/att_check https://raw.githubusercontent.com/kratosssh/kratos-ssh/main/versao 2>/dev/null || \
            curl -so /tmp/att_check https://raw.githubusercontent.com/kratosssh/kratos-ssh/main/versao 2>/dev/null
        [[ -f "/tmp/att_check" ]] && mv /tmp/att_check /tmp/att
    }
    fun_bar 'fun_atts'

    [[ ! -f "/tmp/att" ]] && {
        echo -e "\n${RED} SERVIDOR DE ATUALIZAÇÃO INDISPONÍVEL${RESET}\n"
        echo -ne "${RED}ENTER ${YELLOW}para retornar ao ${GREEN}MENU!${RESET}"; read; menu; return
    }

    echo ""
    local vrs1 vrs2
    vrs1=$(echo "$KRATOS_VERSION" | sed -e 's/[^0-9]//ig')
    vrs2=$(sed -n '1 p' /tmp/att | sed -e 's/[^0-9]//ig')

    [[ "$vrs1" == "$vrs2" ]] && {
        echo -e " ${CYAN}     KRATOS-SSH JÁ ESTÁ NA VERSÃO MAIS RECENTE!${GREEN}\n"
        rm /tmp/att > /dev/null 2>&1
        echo -ne " ${RED}ENTER ${YELLOW}para retornar ao ${GREEN}MENU!${RESET}"; read; menu
    } || {
        echo -e "  ${CYAN}EXISTE UMA NOVA ATUALIZAÇÃO DISPONÍVEL!${YELLOW}\n"
        echo -e "  ${GREEN}DETALHES DA ATUALIZAÇÃO:${RESET}\n"
        while read linha; do echo -e "  ${WHITE}- ${YELLOW}$linha"; done < "/tmp/att"
        echo " "
        echo -ne "  ${GREEN}DESEJA ATUALIZAR ${RED}? ${YELLOW}[s/n]:${WHITE} "; read res
        if [[ "$res" = s || "$res" = S ]]; then
            echo -e "\n${GREEN}  INICIANDO ATUALIZAÇÃO KRATOS-SSH..."
            sleep 2
            wget -qO /tmp/kratosKRATOS-SSH.sh https://raw.githubusercontent.com/kratosssh/kratos-ssh/main/kratosKRATOS-SSH.sh 2>/dev/null && {
                chmod +x /tmp/kratosKRATOS-SSH.sh
                cp /tmp/kratosKRATOS-SSH.sh /bin/menu
                bash /tmp/kratosKRATOS-SSH.sh instalar
            } || echo -e "${RED}ERRO: Não foi possível baixar a atualização.${RESET}"
            rm /tmp/att > /dev/null 2>&1
        else
            menu
        fi
    }
}

# ============================================================
# DELSCRIPT - REMOVER KRATOS-SSH
# ============================================================
delscript() {
    clear
    echo -e "${BG_RED}          REMOVER KRATOS-SSH DO SISTEMA         ${RESET}"
    echo ""
    echo -ne "${RED}REALMENTE DESEJA DESINSTALAR O KRATOS-SSH? ${YELLOW}[s/n]: ${WHITE}"; read resp
    if [[ "$resp" = s || "$resp" = S ]]; then
        echo -e "\n${RED}Removendo pacotes...${RESET}"
        apt-get purge screen nmap figlet squid squid3 dropbear apache2 -y > /dev/null 2>&1
        rm -f /bin/menu /bin/versao /usr/lib/kratos-ssh /usr/lib/licence
        rm -rf $KRATOS_DIR /etc/kratos-ssh 2>/dev/null
        crontab -l 2>/dev/null | grep -v 'kratos\|kratos-ssh' | crontab -
        sed -i '/autostart/d' /etc/rc.local 2>/dev/null
        clear
        echo -e "${CYAN}Obrigado por utilizar o KRATOS-SSH!${YELLOW}"
        sleep 2
        cat /dev/null > ~/.bash_history && history -c && exit 0
    else
        echo -e "${GREEN}Ok, retornando ao menu.${RESET}"
        sleep 1; menu
    fi
}

# ============================================================
# ADDHOST - ADICIONAR HOST AO SQUID
# ============================================================
addhost() {
    local payload
    [[ -d "/etc/squid/" ]] && payload="/etc/squid/payload.txt"
    [[ -d "/etc/squid3/" ]] && payload="/etc/squid3/payload.txt"

    clear
    echo -e "${BG_BLUE}      ADICIONAR HOST AO SQUID - KRATOS-SSH       ${RESET}"
    [[ ! -f "$payload" ]] && { echo -e "\n${BG_RED}Arquivo $payload não encontrado${RESET}"; return 1; }
    echo -e "\n${GREEN}Domínios atuais:${RESET}"; echo ""
    cat $payload
    echo ""
    read -p "Digite o domínio a adicionar (Ex: .operadora.com.br): " host
    [[ -z $host ]] && { echo -e "\n${BG_RED}Domínio vazio!${RESET}"; return 1; }
    [[ $(grep -c "^$host" $payload) -eq 1 ]] && { echo -e "\n${BG_RED}O domínio $host já existe!${RESET}"; return 1; }
    [[ $host != .* ]] && { echo -e "\n${BG_RED}Inicie o domínio com ponto! Ex: .dominio.com${RESET}"; return 1; }
    echo "$host" >> $payload && grep -v "^$" $payload > /tmp/a && mv /tmp/a $payload
    echo -e "\n${GREEN}Domínio adicionado com sucesso!${RESET}"
    [[ -f /etc/squid/squid.conf ]] && service squid reload > /dev/null 2>&1
    [[ -f /etc/squid3/squid.conf ]] && service squid3 reload > /dev/null 2>&1
    echo -e "${GREEN}Squid recarregado!${RESET}"
}

# ============================================================
# DELHOST - REMOVER HOST DO SQUID
# ============================================================
delhost() {
    local payload
    [[ -d "/etc/squid/" ]] && payload="/etc/squid/payload.txt"
    [[ -d "/etc/squid3/" ]] && payload="/etc/squid3/payload.txt"

    clear
    echo -e "${BG_BLUE}      REMOVER HOST DO SQUID - KRATOS-SSH         ${RESET}"
    [[ ! -f "$payload" ]] && { echo -e "\n${BG_RED}Arquivo $payload não encontrado${RESET}"; return 1; }
    echo -e "\n${GREEN}Domínios atuais:${RESET}"; echo ""
    cat $payload
    echo ""
    read -p "Digite o domínio a remover: " host
    [[ -z $host ]] && { echo -e "\n${BG_RED}Domínio vazio!${RESET}"; return 1; }
    [[ $(grep -c "^$host" $payload) -ne 1 ]] && { echo -e "\n${BG_RED}O domínio $host não foi encontrado!${RESET}"; return 1; }
    grep -v "^$host" $payload > /tmp/a && mv /tmp/a $payload
    echo -e "\n${GREEN}Domínio removido com sucesso!${RESET}"
    [[ -f /etc/squid/squid.conf ]] && service squid reload > /dev/null 2>&1
    [[ -f /etc/squid3/squid.conf ]] && service squid3 reload > /dev/null 2>&1
}

# ============================================================
# MODO DE CONEXAO (MENU COMPLETO DE SERVICOS)
# ============================================================
conexao() {
    local IP
    IP=$(cat /etc/IP 2>/dev/null)

    verif_ptrs() {
        local porta="$1"
        local PT
        PT=$(lsof -V -i tcp -P -n 2>/dev/null | grep -v "ESTABLISHED" | grep -v "COMMAND" | grep "LISTEN")
        for pton in $(echo -e "$PT" | cut -d: -f2 | cut -d' ' -f1 | uniq); do
            local svcs
            svcs=$(echo -e "$PT" | grep -w "$pton" | awk '{print $1}' | uniq)
            [[ "$porta" = "$pton" ]] && {
                echo -e "\n${RED}PORTA ${YELLOW}$porta ${RED}EM USO PELO ${WHITE}$svcs${RESET}"
                sleep 3; fun_conexao; return
            }
        done
    }

    # ─── SQUID PROXY ───
    fun_squid() {
        local sqdp VarSqdOn
        [[ "$(netstat -nplt 2>/dev/null | grep -c 'squid')" = "0" ]] && inst_sqd && return
        clear
        echo -e "${BG_BLUE}          GERENCIAR SQUID PROXY - KRATOS-SSH    ${RESET}"
        sqdp=$(netstat -nplt 2>/dev/null | grep 'squid' | awk -F ":" {'print $4'} | xargs)
        [[ -n "$sqdp" ]] && { echo -e "\n${YELLOW}PORTAS${WHITE}: ${GREEN}$sqdp"; VarSqdOn="REMOVER SQUID PROXY"; } || VarSqdOn="INSTALAR SQUID PROXY"
        echo -e "\n${RED}[${CYAN}1${RED}] ${WHITE}• ${YELLOW}$VarSqdOn
${RED}[${CYAN}2${RED}] ${WHITE}• ${YELLOW}ADICIONAR PORTA
${RED}[${CYAN}3${RED}] ${WHITE}• ${YELLOW}REMOVER PORTA
${RED}[${CYAN}0${RED}] ${WHITE}• ${YELLOW}VOLTAR${RESET}"
        echo ""
        echo -ne "${GREEN}OQUE DESEJA FAZER ${YELLOW}?${WHITE} "; read x
        clear
        case $x in
            1|01) inst_sqd ;;
            2|02) addpt_sqd ;;
            3|03) rempt_sqd ;;
            0|00) echo -e "${RED}Retornando...${RESET}"; sleep 1; fun_conexao ;;
            *) echo -e "${RED}Opcao Invalida...${RESET}"; sleep 2; fun_conexao ;;
        esac
    }

    inst_sqd() {
        if netstat -nltp 2>/dev/null | grep 'squid' 1>/dev/null 2>/dev/null; then
            clear
            echo -e "${BG_RED}            REMOVER SQUID PROXY - KRATOS-SSH   ${RESET}"
            echo ""
            echo -ne "${GREEN}REALMENTE DESEJA REMOVER O SQUID ${RED}? ${YELLOW}[s/n]:${WHITE} "; read resp
            [[ "$resp" = 's' ]] && {
                echo -e "\n${GREEN}REMOVENDO O SQUID PROXY !${RESET}"; echo ""
                rem_sqd() {
                    [[ -d "/etc/squid" ]] && { apt-get remove squid -y; apt-get purge squid -y; rm -rf /etc/squid; } >/dev/null 2>&1
                    [[ -d "/etc/squid3" ]] && { apt-get remove squid3 -y; apt-get purge squid3 -y; rm -rf /etc/squid3; apt autoremove -y; } >/dev/null 2>&1
                }
                fun_bar 'rem_sqd'
                echo -e "\n${GREEN}SQUID REMOVIDO COM SUCESSO !${RESET}"; sleep 2; clear; fun_conexao
            } || { echo -e "\n${RED}Retornando...${RESET}"; sleep 2; clear; fun_conexao; }
        else
            clear
            echo -e "${BG_BLUE}              INSTALADOR SQUID - KRATOS-SSH     ${RESET}"
            echo ""
            local ipdovps portass
            ipdovps=$(wget -qO- ipv4.icanhazip.com 2>/dev/null)
            echo -ne "${GREEN}CONFIRME SEU IP: ${WHITE}"; read -e -i $ipdovps ipdovps
            echo -e "\n${YELLOW}QUAIS PORTAS DESEJA UTILIZAR? ${RED}(Ex: 80 8080)${RESET}"
            echo ""
            echo -ne "${GREEN}INFORME AS PORTAS${WHITE}: "; read portass
            [[ -z "$portass" ]] && { echo -e "\n${RED}Porta invalida!${RESET}"; sleep 3; fun_conexao; return; }
            for porta in $(echo -e $portass); do verif_ptrs $porta; done

            echo -e "\n${GREEN}INSTALANDO SQUID PROXY${RESET}\n"
            fun_bar 'apt update -y' 'apt install squid -y || apt install squid3 -y'

            local var_sqd var_pay
            [[ -d "/etc/squid/" ]] && { var_sqd="/etc/squid/squid.conf"; var_pay="/etc/squid/payload.txt"; }
            [[ -d "/etc/squid3/" ]] && { var_sqd="/etc/squid3/squid.conf"; var_pay="/etc/squid3/payload.txt"; }
            [[ -z "$var_sqd" ]] && { echo -e "\n${RED}SQUID NAO INSTALADO CORRETAMENTE!${RESET}"; sleep 2; fun_conexao; return; }

            cat <<EOF > $var_pay
.whatsapp.net/
.facebook.net/
.twitter.com/
.speedtest.net/
EOF
            cat <<EOF > $var_sqd
acl url1 dstdomain -i 127.0.0.1
acl url2 dstdomain -i localhost
acl url3 dstdomain -i $ipdovps
acl url4 dstdomain -i /KRATOS-SSH?
acl payload url_regex -i "$var_pay"
acl all src 0.0.0.0/0

http_access allow url1
http_access allow url2
http_access allow url3
http_access allow url4
http_access allow payload
http_access deny all

#Portas
EOF
            for Pts in $(echo -e $portass); do
                echo "http_port $Pts" >> $var_sqd
                [[ -f "/usr/sbin/ufw" ]] && ufw allow $Pts/tcp > /dev/null 2>&1
            done
            cat <<EOF >> $var_sqd
#Nome squid
visible_hostname KRATOS-SSH
via off
forwarded_for off
pipeline_prefetch off
EOF
            echo -e "\n${GREEN}CONFIGURANDO SQUID PROXY${RESET}\n"
            fun_bar 'service squid restart || service squid3 restart'
            echo -e "\n${GREEN}SQUID INSTALADO COM SUCESSO!${RESET}"; sleep 2.5; fun_conexao
        fi
    }

    addpt_sqd() {
        local var_sqd sqdp pt
        [[ -f "/etc/squid/squid.conf" ]] && var_sqd="/etc/squid/squid.conf"
        [[ -f "/etc/squid3/squid.conf" ]] && var_sqd="/etc/squid3/squid.conf"
        sqdp=$(netstat -nplt 2>/dev/null | grep 'squid' | awk -F ":" {'print $4'} | xargs)
        echo -e "${BG_BLUE}         ADICIONAR PORTA AO SQUID - KRATOS-SSH   ${RESET}"
        echo -e "\n${YELLOW}PORTAS EM USO: ${GREEN}$sqdp\n"
        echo -ne "${GREEN}QUAL PORTA DESEJA ADICIONAR ${YELLOW}?${WHITE} "; read pt
        [[ -z "$pt" ]] && { echo -e "\n${RED}Porta invalida!${RESET}"; sleep 2; clear; fun_conexao; return; }
        verif_ptrs $pt
        echo -e "\n${GREEN}ADICIONANDO PORTA AO SQUID!"
        sed -i "s/#Portas/#Portas\nhttp_port $pt/g" $var_sqd
        echo ""; fun_bar 'service squid restart || service squid3 restart'
        echo -e "\n${GREEN}PORTA ADICIONADA COM SUCESSO!"; sleep 3; clear; fun_squid
    }

    rempt_sqd() {
        local var_sqd sqdp pt
        [[ -f "/etc/squid/squid.conf" ]] && var_sqd="/etc/squid/squid.conf"
        [[ -f "/etc/squid3/squid.conf" ]] && var_sqd="/etc/squid3/squid.conf"
        sqdp=$(netstat -nplt 2>/dev/null | grep 'squid' | awk -F ":" {'print $4'} | xargs)
        echo -e "${BG_RED}         REMOVER PORTA DO SQUID - KRATOS-SSH     ${RESET}"
        echo -e "\n${YELLOW}PORTAS EM USO: ${GREEN}$sqdp\n"
        echo -ne "${GREEN}QUAL PORTA DESEJA REMOVER ${YELLOW}?${WHITE} "; read pt
        [[ -z "$pt" ]] && { echo -e "\n${RED}Porta invalida!${RESET}"; sleep 2; clear; fun_conexao; return; }
        if grep -E "$pt" $var_sqd > /dev/null 2>&1; then
            sed -i "/http_port $pt/d" $var_sqd
            echo ""; fun_bar 'service squid restart || service squid3 restart'
            echo -e "\n${GREEN}PORTA REMOVIDA COM SUCESSO!"; sleep 3.5; clear; fun_squid
        else
            echo -e "\n${RED}PORTA ${GREEN}$pt ${RED}NAO ENCONTRADA!"; sleep 3.5; clear; fun_squid
        fi
    }

    # ─── DROPBEAR ───
    fun_drop() {
        if netstat -nltp 2>/dev/null | grep 'dropbear' 1>/dev/null 2>/dev/null; then
            clear
            local dpbr stats
            dpbr=$(netstat -nplt 2>/dev/null | grep 'dropbear' | awk -F ":" {'print $4'} | xargs)
            ps x | grep "limiter" | grep -v grep 1>/dev/null 2>/dev/null && stats="${GREEN}◉ " || stats="${RED}○ "
            echo -e "${BG_BLUE}           GERENCIAR DROPBEAR - KRATOS-SSH       ${RESET}"
            echo -e "\n${YELLOW}PORTAS${WHITE}: ${GREEN}$dpbr\n"
            echo -e "${RED}[${CYAN}1${RED}] ${WHITE}• ${YELLOW}LIMITER DROPBEAR $stats${RESET}"
            echo -e "${RED}[${CYAN}2${RED}] ${WHITE}• ${YELLOW}ALTERAR PORTA DROPBEAR${RESET}"
            echo -e "${RED}[${CYAN}3${RED}] ${WHITE}• ${YELLOW}REMOVER DROPBEAR${RESET}"
            echo -e "${RED}[${CYAN}0${RED}] ${WHITE}• ${YELLOW}VOLTAR${RESET}"
            echo ""
            echo -ne "${GREEN}OQUE DESEJA FAZER ${YELLOW}?${WHITE} "; read resposta
            if [[ "$resposta" = '1' ]]; then
                clear
                if ps x | grep "limiter" | grep -v grep 1>/dev/null 2>/dev/null; then
                    echo -e "${RED}Parando o limiter... ${RESET}\n"
                    fun_stplimiter2() {
                        pidlimiter=$(ps x | grep "limiter" | awk -F "pts" {'print $1'})
                        kill -9 $pidlimiter; screen -wipe
                    }
                    fun_bar 'fun_stplimiter2' 'sleep 2'
                    echo -e "\n${RED} LIMITER DESATIVADO ${RESET}"; sleep 3; fun_drop
                else
                    echo -e "\n${GREEN}Iniciando o limiter... ${RESET}\n"
                    fun_bar 'screen -d -m -t limiter droplimiter' 'sleep 3'
                    echo -e "\n${GREEN}  LIMITER ATIVADO ${RESET}"; sleep 3; fun_drop
                fi
            elif [[ "$resposta" = '2' ]]; then
                echo ""
                echo -ne "${GREEN}QUAL PORTA DESEJA UTILIZAR ${YELLOW}?${WHITE} "; read pt
                verif_ptrs $pt
                local var1
                var1=$(grep 'DROPBEAR_PORT=' /etc/default/dropbear | cut -d'=' -f2)
                echo -e "${GREEN}ALTERANDO PORTA DROPBEAR!"
                sed -i "s/\b$var1\b/$pt/g" /etc/default/dropbear > /dev/null 2>&1
                echo ""; fun_bar 'service dropbear restart' '/etc/init.d/dropbear restart'
                echo -e "\n${GREEN}PORTA ALTERADA COM SUCESSO!"; sleep 3; clear; fun_conexao
            elif [[ "$resposta" = '3' ]]; then
                echo -e "\n${RED}REMOVENDO O DROPBEAR !${RESET}\n"
                fun_dropunistall() {
                    service dropbear stop && /etc/init.d/dropbear stop
                    apt remove dropbear-run -y; apt remove dropbear -y; apt purge dropbear -y
                    rm -rf /etc/default/dropbear; apt autoremove -y
                }
                fun_bar 'fun_dropunistall'
                echo -e "\n${GREEN}DROPBEAR REMOVIDO COM SUCESSO !${RESET}"; sleep 3; clear; fun_conexao
            elif [[ "$resposta" = '0' ]]; then
                echo -e "\n${RED}Retornando...${RESET}"; sleep 2; fun_conexao
            else
                echo -e "\n${RED}Opcao invalida...${RESET}"; sleep 2; fun_conexao
            fi
        else
            clear
            echo -e "${BG_BLUE}           INSTALADOR DROPBEAR - KRATOS-SSH      ${RESET}"
            echo -e "\n${YELLOW}VC ESTA PRESTES A INSTALAR O DROPBEAR !${RESET}\n"
            echo -ne "${GREEN}DESEJA CONTINUAR ${RED}? ${YELLOW}[s/n]:${WHITE} "; read resposta
            [[ "$resposta" = 's' ]] && {
                echo -e "\n${YELLOW}DEFINA UMA PORTA PARA O DROPBEAR !${RESET}\n"
                echo -ne "${GREEN}QUAL A PORTA ${YELLOW}?${WHITE} "; read porta
                [[ -z "$porta" ]] && { echo -e "\n${RED}Porta invalida!${RESET}"; sleep 3; clear; fun_conexao; return; }
                verif_ptrs $porta
                echo -e "\n${GREEN}INSTALANDO O DROPBEAR ! ${RESET}\n"
                fun_instdrop() { apt-get update -y; apt-get install dropbear -y; }
                fun_bar 'fun_instdrop'
                fun_ports() {
                    sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear > /dev/null 2>&1
                    sed -i "s/DROPBEAR_PORT=22/DROPBEAR_PORT=$porta/g" /etc/default/dropbear > /dev/null 2>&1
                    sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 110"/g' /etc/default/dropbear > /dev/null 2>&1
                }
                echo ""; echo -e "${GREEN}CONFIGURANDO PORTA DROPBEAR !${RESET}"; echo ""
                fun_bar 'fun_ports'
                grep -v "^PasswordAuthentication yes" /etc/ssh/sshd_config > /tmp/passlogin && mv /tmp/passlogin /etc/ssh/sshd_config
                echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
                grep -v "^PermitTunnel yes" /etc/ssh/sshd_config > /tmp/ssh && mv /tmp/ssh /etc/ssh/sshd_config
                echo "PermitTunnel yes" >> /etc/ssh/sshd_config
                echo ""; echo -e "${GREEN}FINALIZANDO INSTALAÇÃO !${RESET}"; echo ""
                fun_ondrop() { service ssh restart; service dropbear start; /etc/init.d/dropbear restart; }
                fun_bar 'fun_ondrop' 'sleep 1'
                [[ $(grep -c "/bin/false" /etc/shells) = '0' ]] && echo "/bin/false" >> /etc/shells
                echo -e "\n${GREEN}INSTALAÇÃO CONCLUÍDA ${YELLOW}PORTA: ${WHITE}$porta${RESET}"; sleep 2; clear; fun_conexao
            } || { echo ""; echo -e "${RED}Retornando...${RESET}"; sleep 3; clear; fun_conexao; }
        fi
    }

    # ─── OPENSSH ───
    fun_openssh() {
        clear
        echo -e "${BG_BLUE}              OPENSSH - KRATOS-SSH              ${RESET}\n"
        echo -e "${RED}[${CYAN}1${RED}] ${WHITE}• ${YELLOW}ADICIONAR PORTA
${RED}[${CYAN}2${RED}] ${WHITE}• ${YELLOW}REMOVER PORTA
${RED}[${CYAN}3${RED}] ${WHITE}• ${YELLOW}VOLTAR${RESET}"
        echo ""
        echo -ne "${GREEN}OQUE DESEJA FAZER ${YELLOW}?${WHITE} "; read resp
        if [[ "$resp" = '1' ]]; then
            clear
            echo -e "${BG_BLUE}         ADICIONAR PORTA AO SSH - KRATOS-SSH    ${RESET}\n"
            echo -ne "${GREEN}QUAL PORTA DESEJA ADICIONAR ${YELLOW}?${WHITE} "; read pt
            [[ -z "$pt" ]] && { echo -e "\n${RED}Porta invalida!${RESET}"; sleep 3; fun_conexao; return; }
            verif_ptrs $pt
            echo -e "\n${GREEN}ADICIONANDO PORTA AO SSH${RESET}\n"
            fun_addpssh() { echo "Port $pt" >> /etc/ssh/sshd_config; service ssh restart; }
            fun_bar 'fun_addpssh'
            echo -e "\n${GREEN}PORTA ADICIONADA COM SUCESSO${RESET}"; sleep 3; fun_conexao
        elif [[ "$resp" = '2' ]]; then
            clear
            echo -e "${BG_RED}         REMOVER PORTA DO SSH - KRATOS-SSH       ${RESET}"
            echo -e "\n${YELLOW}[${RED}!${YELLOW}] ${GREEN}PORTA PADRÃO ${WHITE}22 ${YELLOW}CUIDADO !${RESET}"
            echo -e "\n${YELLOW}PORTAS EM USO: ${WHITE}$(grep 'Port' /etc/ssh/sshd_config | cut -d' ' -f2 | grep -v 'no' | xargs)\n"
            echo -ne "${GREEN}QUAL PORTA DESEJA REMOVER ${YELLOW}?${WHITE} "; read pt
            [[ -z "$pt" ]] && { echo -e "\n${RED}Porta invalida!${RESET}"; sleep 2; fun_conexao; return; }
            [[ $(grep -wc "$pt" '/etc/ssh/sshd_config') != '0' ]] && {
                echo -e "\n${GREEN}REMOVENDO PORTA DO SSH${RESET}\n"
                fun_delpssh() { sed -i "/Port $pt/d" /etc/ssh/sshd_config; service ssh restart; }
                fun_bar 'fun_delpssh'
                echo -e "\n${GREEN}PORTA REMOVIDA COM SUCESSO${RESET}"; sleep 2; fun_conexao
            } || { echo -e "\n${RED}Porta não encontrada!${RESET}"; sleep 2; fun_conexao; }
        elif [[ "$resp" = '3' ]]; then
            echo -e "\n${RED}Retornando..${RESET}"; sleep 2; fun_conexao
        else
            echo -e "\n${RED}Opcao invalida!${RESET}"; sleep 2; fun_conexao
        fi
    }

    # ─── PROXY SOCKS / WEBSOCKET ───
    fun_socks() {
        clear
        echo -e "${BG_BLUE}         GERENCIAR PROXY/WEBSOCKET - KRATOS-SSH  ${RESET}"
        echo ""
        [[ $(netstat -nplt 2>/dev/null | grep -wc 'python') != '0' ]] && {
            echo -e "${YELLOW}PORTAS${WHITE}: ${GREEN}$(netstat -nplt 2>/dev/null | grep 'python' | awk {'print $4'} | cut -d: -f2 | xargs)"
        }
        local var_sks1 var_sks2 sksop
        [[ $(screen -list 2>/dev/null | grep -wc 'proxy') != '0' ]] && var_sks1="${GREEN}◉" || var_sks1="${RED}○"
        [[ $(screen -list 2>/dev/null | grep -wc 'ws') != '0' ]] && var_sks2="${GREEN}◉" || var_sks2="${RED}○"
        [[ $(screen -list 2>/dev/null | grep -wc 'openpy') != '0' ]] && sksop="${GREEN}◉" || sksop="${RED}○"
        echo ""
        echo -e "${RED}[${CYAN}1${RED}] ${WHITE}• ${YELLOW}SOCKS SSH $var_sks1 ${RESET}"
        echo -e "${RED}[${CYAN}2${RED}] ${WHITE}• ${YELLOW}WEBSOCKET SECURITY $var_sks2 ${RESET}"
        echo -e "${RED}[${CYAN}3${RED}] ${WHITE}• ${YELLOW}SOCKS OPENVPN $sksop ${RESET}"
        echo -e "${RED}[${CYAN}4${RED}] ${WHITE}• ${YELLOW}ABRIR PORTA EXTRA${RESET}"
        echo -e "${RED}[${CYAN}5${RED}] ${WHITE}• ${YELLOW}ALTERAR STATUS SOCKS SSH${RESET}"
        echo -e "${RED}[${CYAN}6${RED}] ${WHITE}• ${YELLOW}ALTERAR STATUS WEBSOCKET${RESET}"
        echo -e "${RED}[${CYAN}0${RED}] ${WHITE}• ${YELLOW}VOLTAR${RESET}"
        echo ""
        echo -ne "${GREEN}OQUE DESEJA FAZER ${YELLOW}?${WHITE} "; read resposta

        if [[ "$resposta" = '1' ]]; then
            if ps x | grep -w proxy.py | grep -v grep 1>/dev/null 2>/dev/null; then
                clear
                echo -e "${BG_RED}             PROXY SOCKS - KRATOS-SSH           ${RESET}\n"
                fun_socksoff() {
                    for pidproxy in $(screen -ls 2>/dev/null | grep ".proxy" | awk {'print $1'}); do screen -r -S "$pidproxy" -X quit; done
                    [[ $(grep -wc "proxy.py" $KRATOS_AUTOSTART) != '0' ]] && sed -i '/proxy.py/d' $KRATOS_AUTOSTART
                    sleep 1; screen -wipe > /dev/null 2>/dev/null
                }
                echo -e "${GREEN}DESATIVANDO O PROXY SOCKS${YELLOW}\n"
                fun_bar 'fun_socksoff'
                echo -e "\n${GREEN}PROXY SOCKS DESATIVADO COM SUCESSO!${YELLOW}"; sleep 3; fun_socks
            else
                clear
                echo -e "${BG_BLUE}             PROXY SOCKS - KRATOS-SSH           ${RESET}\n"
                echo -ne "${GREEN}QUAL PORTA DESEJA UTILIZAR ${YELLOW}?${WHITE}: "; read porta
                [[ -z "$porta" ]] && { echo -e "\n${RED}Porta invalida!${RESET}"; sleep 3; clear; fun_conexao; return; }
                verif_ptrs $porta
                fun_inisocks() {
                    sleep 1
                    screen -dmS proxy python $KRATOS_DIR/proxy.py $porta
                    [[ $(grep -wc "proxy.py" $KRATOS_AUTOSTART) = '0' ]] && {
                        echo "netstat -tlpn | grep -w $porta > /dev/null || { screen -r -S 'proxy' -X quit; screen -dmS proxy python $KRATOS_DIR/proxy.py $porta; }" >> $KRATOS_AUTOSTART
                    } || {
                        sed -i '/proxy.py/d' $KRATOS_AUTOSTART
                        echo "netstat -tlpn | grep -w $porta > /dev/null || { screen -r -S 'proxy' -X quit; screen -dmS proxy python $KRATOS_DIR/proxy.py $porta; }" >> $KRATOS_AUTOSTART
                    }
                }
                echo ""; echo -e "${GREEN}INICIANDO O PROXY SOCKS${YELLOW}\n"
                fun_bar 'fun_inisocks'
                echo ""; echo -e "${GREEN}SOCKS ATIVADO COM SUCESSO${YELLOW}"; sleep 3; fun_socks
            fi

        elif [[ "$resposta" = '2' ]]; then
            if ps x | grep -w wsproxy.py | grep -v grep 1>/dev/null 2>/dev/null; then
                clear
                echo -e "${BG_RED}       WEBSOCKET SECURITY - KRATOS-SSH           ${RESET}\n"
                fun_wssocksoff() {
                    for pidproxy in $(screen -ls 2>/dev/null | grep ".ws" | awk {'print $1'}); do screen -r -S "$pidproxy" -X quit; done
                    [[ $(grep -wc "wsproxy.py" $KRATOS_AUTOSTART) != '0' ]] && sed -i '/wsproxy.py/d' $KRATOS_AUTOSTART
                    sleep 1; screen -wipe > /dev/null 2>/dev/null
                }
                echo -e "${GREEN}DESATIVANDO O WEBSOCKET${YELLOW}\n"
                fun_bar 'fun_wssocksoff'
                echo ""; echo -e "${GREEN}WEBSOCKET DESATIVADO COM SUCESSO!${YELLOW}"; sleep 3; fun_socks
            else
                clear
                echo -e "${BG_BLUE}       WEBSOCKET SECURITY - KRATOS-SSH           ${RESET}\n"
                echo -ne "${GREEN}QUAL PORTA DESEJA UTILIZAR ${YELLOW}?${WHITE}: "; read porta
                [[ -z "$porta" ]] && { echo -e "\n${RED}Porta invalida!${RESET}"; sleep 3; clear; fun_conexao; return; }
                verif_ptrs $porta
                fun_iniwssocks() {
                    sleep 1
                    screen -dmS ws python $KRATOS_DIR/wsproxy.py $porta
                    [[ $(grep -wc "wsproxy.py" $KRATOS_AUTOSTART) = '0' ]] && {
                        echo "netstat -tlpn | grep -w $porta > /dev/null || { screen -r -S 'ws' -X quit; screen -dmS ws python $KRATOS_DIR/wsproxy.py $porta; }" >> $KRATOS_AUTOSTART
                    } || {
                        sed -i '/wsproxy.py/d' $KRATOS_AUTOSTART
                        echo "netstat -tlpn | grep -w $porta > /dev/null || { screen -r -S 'ws' -X quit; screen -dmS ws python $KRATOS_DIR/wsproxy.py $porta; }" >> $KRATOS_AUTOSTART
                    }
                }
                echo ""; echo -e "${GREEN}INICIANDO O WEBSOCKET SECURITY${YELLOW}\n"
                fun_bar 'fun_iniwssocks'
                echo ""; echo -e "${GREEN}WEBSOCKET ATIVADO COM SUCESSO${YELLOW}"; sleep 3; fun_socks
            fi

        elif [[ "$resposta" = '3' ]]; then
            if ps x | grep -w open.py | grep -v grep 1>/dev/null 2>/dev/null; then
                clear
                echo -e "${BG_RED}            SOCKS OPENVPN - KRATOS-SSH          ${RESET}\n"
                fun_socksopenoff() {
                    for pidproxy in $(screen -list 2>/dev/null | grep -w "openpy" | awk {'print $1'}); do screen -r -S "$pidproxy" -X quit; done
                    [[ $(grep -wc "open.py" $KRATOS_AUTOSTART) != '0' ]] && sed -i '/open.py/d' $KRATOS_AUTOSTART
                    sleep 1; screen -wipe > /dev/null 2>/dev/null
                }
                echo -e "${GREEN}DESATIVANDO O SOCKS OPEN${YELLOW}\n"
                fun_bar 'fun_socksopenoff'
                echo ""; echo -e "${GREEN}SOCKS DESATIVADO COM SUCESSO!${YELLOW}"; sleep 2; fun_socks
            else
                clear
                echo -e "${BG_RED}            SOCKS OPENVPN - KRATOS-SSH          ${RESET}\n"
                echo -ne "${GREEN}QUAL PORTA DESEJA UTILIZAR ${YELLOW}?${WHITE}: "; read porta
                [[ -z "$porta" ]] && { echo -e "\n${RED}Porta invalida!${RESET}"; sleep 2; clear; fun_conexao; return; }
                verif_ptrs $porta
                fun_inisocksop() {
                    [[ "$(netstat -tlpn 2>/dev/null | grep 'openvpn' | wc -l)" != '0' ]] && {
                        local listopen=$(netstat -tlpn 2>/dev/null | grep -w openvpn | grep -v 127.0.0.1 | awk {'print $4'} | cut -d: -f2)
                        sed -i "s/0.0.0.0:1194/0.0.0.0:$listopen/" $KRATOS_DIR/open.py 2>/dev/null
                    }
                    sleep 1
                    screen -dmS openpy python $KRATOS_DIR/open.py $porta
                    [[ $(grep -wc "open.py" $KRATOS_AUTOSTART) = '0' ]] && {
                        echo "netstat -tlpn | grep -w $porta > /dev/null || { screen -r -S 'openpy' -X quit; screen -dmS openpy python $KRATOS_DIR/open.py $porta; }" >> $KRATOS_AUTOSTART
                    } || {
                        sed -i '/open.py/d' $KRATOS_AUTOSTART
                        echo "netstat -tlpn | grep -w $porta > /dev/null || { screen -r -S 'openpy' -X quit; screen -dmS openpy python $KRATOS_DIR/open.py $porta; }" >> $KRATOS_AUTOSTART
                    }
                }
                echo ""; echo -e "${GREEN}INICIANDO O SOCKS OPENVPN${YELLOW}\n"
                fun_bar 'fun_inisocksop'
                echo ""; echo -e "${GREEN}SOCKS OPENVPN ATIVADO COM SUCESSO${YELLOW}"; sleep 3; fun_socks
            fi

        elif [[ "$resposta" = '4' ]]; then
            ps x | grep proxy.py | grep -v grep 1>/dev/null 2>/dev/null && {
                local sockspt=$(netstat -nplt 2>/dev/null | grep 'python' | awk {'print $4'} | cut -d: -f2 | xargs)
                clear; echo -e "${BG_BLUE}            PROXY SOCKS - KRATOS-SSH           ${RESET}\n"
                echo -e "${YELLOW}PORTAS EM USO: ${GREEN}$sockspt\n"
                echo -ne "${GREEN}QUAL PORTA EXTRA ${YELLOW}?${WHITE}: "; read porta
                [[ -z "$porta" ]] && { echo -e "\n${RED}Porta invalida!${RESET}"; sleep 2; clear; fun_conexao; return; }
                verif_ptrs $porta
                abrirptsks() { sleep 1; screen -dmS proxy python $KRATOS_DIR/proxy.py $porta; sleep 1; }
                echo ""; fun_bar 'abrirptsks'
                echo ""; echo -e "${GREEN}PROXY SOCKS NA PORTA $porta ATIVADO!${YELLOW}"; sleep 2; fun_socks
            } || { echo -e "${RED}ATIVE O SOCKS PRIMEIRO !${YELLOW}"; sleep 2; fun_socks; }

        elif [[ "$resposta" = '5' ]] || [[ "$resposta" = '6' ]]; then
            local script_py msg_label
            [[ "$resposta" = '5' ]] && { script_py="proxy.py"; msg_label="PROXY SOCKS"; } || { script_py="wsproxy.py"; msg_label="WEBSOCKET"; }
            ps x | grep -w $script_py | grep -v grep 1>/dev/null 2>/dev/null && {
                clear
                local msgsocks=$(cat $KRATOS_DIR/$script_py | grep -E "MSG =" | awk -F= '{print $2}' | cut -d "'" -f2)
                echo -e "${BG_BLUE}             $msg_label - KRATOS-SSH           ${RESET}\n"
                echo -e "${YELLOW}STATUS ATUAL: ${GREEN}$msgsocks\n"
                echo -ne "${GREEN}NOVO STATUS${RED}:${WHITE} "; read msgg
                [[ -z "$msgg" ]] && { echo -e "\n${RED}Status invalido!${RESET}"; sleep 2; fun_conexao; return; }
                fun_msgsocks() {
                    local msgsocks2=$(cat $KRATOS_DIR/$script_py | grep "MSG =" | awk -F= '{print $2}')
                    sed -i "s/$msgsocks2/ '$msgg'/g" $KRATOS_DIR/$script_py
                }
                echo ""; echo -e "${GREEN}ALTERANDO STATUS!"; echo ""; fun_bar 'fun_msgsocks'
                # Reiniciar o processo
                local _pts=$(netstat -nplt 2>/dev/null | grep 'python' | awk {'print $4'} | cut -d: -f2 | head -1)
                local _sname=$([[ "$resposta" = '5' ]] && echo "proxy" || echo "ws")
                for pidp in $(screen -ls 2>/dev/null | grep ".$_sname" | awk {'print $1'}); do screen -r -S "$pidp" -X quit; done
                screen -wipe > /dev/null 2>/dev/null; sleep 1
                screen -dmS $_sname python $KRATOS_DIR/$script_py $_pts
                echo ""; echo -e "${GREEN}STATUS ALTERADO COM SUCESSO!"; sleep 2; fun_socks
            } || { echo -e "${RED}ATIVE O $msg_label PRIMEIRO !${YELLOW}"; sleep 2; fun_socks; }

        elif [[ "$resposta" = '0' ]]; then
            echo ""; echo -e "${RED}Retornando...${RESET}"; sleep 1; fun_conexao
        else
            echo ""; echo -e "${RED}Opcao invalida !${RESET}"; sleep 1; fun_socks
        fi
    }

    # ─── SSL TUNNEL ───
    inst_ssl() {
        if netstat -nltp 2>/dev/null | grep 'stunnel4' 1>/dev/null 2>/dev/null; then
            local sslt=$(netstat -nplt 2>/dev/null | grep stunnel4 | awk {'print $4'} | awk -F ":" {'print $2'} | xargs)
            clear; echo -e "${BG_BLUE}           GERENCIAR SSL TUNNEL - KRATOS-SSH     ${RESET}"
            echo -e "\n${YELLOW}PORTAS${WHITE}: ${GREEN}$sslt\n"
            echo -e "${RED}[${CYAN}1${RED}] ${WHITE}• ${YELLOW}ALTERAR PORTA SSL TUNNEL${RESET}"
            echo -e "${RED}[${CYAN}2${RED}] ${WHITE}• ${YELLOW}REMOVER SSL TUNNEL${RESET}"
            echo -e "${RED}[${CYAN}0${RED}] ${WHITE}• ${YELLOW}VOLTAR${RESET}"
            echo ""; echo -ne "${GREEN}OQUE DESEJA FAZER ${YELLOW}?${WHITE} "; read resposta; echo ""
            [[ "$resposta" = '1' ]] && {
                echo -ne "${GREEN}QUAL PORTA DESEJA UTILIZAR ${YELLOW}?${WHITE} "; read porta; echo ""
                [[ -z "$porta" ]] && { echo -e "${RED}Porta invalida!${RESET}"; sleep 2; clear; fun_conexao; return; }
                verif_ptrs $porta
                echo -e "${GREEN}ALTERANDO PORTA SSL TUNNEL!"
                local var2=$(grep 'accept' /etc/stunnel/stunnel.conf | awk '{print $NF}')
                sed -i "s/\b$var2\b/$porta/g" /etc/stunnel/stunnel.conf > /dev/null 2>&1
                echo ""; fun_bar 'service stunnel4 restart' '/etc/init.d/stunnel4 restart'
                echo ""; netstat -nltp 2>/dev/null | grep 'stunnel4' > /dev/null && \
                    echo -e "${GREEN}PORTA ALTERADA COM SUCESSO !" || echo -e "${RED}ERRO INESPERADO!"
                sleep 3.5; clear; fun_conexao
            }
            [[ "$resposta" = '2' ]] && {
                echo -e "${GREEN}REMOVENDO O SSL TUNNEL !${RESET}"
                del_ssl() {
                    service stunnel4 stop; apt-get remove stunnel4 -y; apt-get autoremove stunnel4 -y
                    apt-get purge stunnel4 -y; rm -rf /etc/stunnel/stunnel.conf /etc/default/stunnel4 /etc/stunnel/stunnel.pem
                }
                echo ""; fun_bar 'del_ssl'
                echo ""; echo -e "${GREEN}SSL TUNNEL REMOVIDO COM SUCESSO!${RESET}"; sleep 3; fun_conexao
            } || { echo -e "${RED}Retornando...${RESET}"; sleep 3; fun_conexao; }
        else
            clear; echo -e "${BG_BLUE}           INSTALADOR SSL TUNNEL - KRATOS-SSH    ${RESET}"
            echo -e "\n${YELLOW}VC ESTA PRESTES A INSTALAR O SSL TUNNEL !${RESET}\n"
            echo -ne "${GREEN}DESEJA CONTINUAR ${RED}? ${YELLOW}[s/n]:${WHITE} "; read resposta
            [[ "$resposta" = 's' ]] && {
                echo -e "\n${YELLOW}DEFINA UMA PORTA PARA O SSL TUNNEL !${RESET}\n"
                read -p "$(echo -e "${GREEN}QUAL PORTA DESEJA UTILIZAR? ${WHITE}")" -e -i 443 porta
                [[ -z "$porta" ]] && { echo -e "\n${RED}Porta invalida!${RESET}"; sleep 3; clear; fun_conexao; return; }
                verif_ptrs $porta
                echo -e "\n${GREEN}INSTALANDO O SSL TUNNEL !${YELLOW}\n"
                fun_bar 'apt-get update -y' 'apt-get install stunnel4 -y'
                echo -e "\n${GREEN}CONFIGURANDO O SSL TUNNEL !${RESET}\n"
                ssl_conf() {
                    echo -e "cert = /etc/stunnel/stunnel.pem\nclient = no\nsocket = a:SO_REUSEADDR=1\nsocket = l:TCP_NODELAY=1\nsocket = r:TCP_NODELAY=1\n\n[stunnel]\nconnect = 0.0.0.0:22\naccept = ${porta}\nsslVersion = all" > /etc/stunnel/stunnel.conf
                }
                fun_bar 'ssl_conf'
                echo -e "\n${GREEN}CRIANDO CERTIFICADO !${RESET}\n"
                ssl_certif() {
                    sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
                    # Usar certificado do pacote Herramientas ou baixar
                    [[ -f /etc/kratos-ssh/stunnel.pem ]] && cp /etc/kratos-ssh/stunnel.pem /etc/stunnel/stunnel.pem || {
                        openssl req -new -x509 -days 3650 -nodes -subj "/CN=KRATOS-SSH" \
                            -keyout /etc/stunnel/stunnel.pem -out /etc/stunnel/stunnel.pem > /dev/null 2>&1
                    }
                }
                fun_bar 'ssl_certif'
                echo -e "\n${GREEN}INICIANDO O SSL TUNNEL !${RESET}\n"
                fun_finssl() { service stunnel4 restart; service ssh restart; /etc/init.d/stunnel4 restart; }
                fun_bar 'fun_finssl' 'service stunnel4 restart'
                echo -e "\n${GREEN}SSL TUNNEL INSTALADO COM SUCESSO !${RED} PORTA: ${YELLOW}$porta${RESET}"
                sleep 3; clear; fun_conexao
            } || { echo -e "\n${RED}Retornando...${RESET}"; sleep 2; clear; fun_conexao; }
        fi
    }

    # ─── SSLH MULTIPLEX ───
    fun_sslh() {
        [[ "$(netstat -nltp 2>/dev/null | grep 'sslh' | wc -l)" = '0' ]] && {
            clear; echo -e "${BG_BLUE}             INSTALADOR SSLH - KRATOS-SSH        ${RESET}\n"
            echo -e "\n${YELLOW}[${RED}!${YELLOW}] ${GREEN}A PORTA ${WHITE}3128 ${GREEN}SERA USADA POR PADRAO${RESET}\n"
            echo -ne "${GREEN}REALMENTE DESEJA INSTALAR O SSLH ${RED}? ${YELLOW}[s/n]:${WHITE} "; read resp
            [[ "$resp" = 's' ]] && {
                verif_ptrs 3128
                fun_instsslh() {
                    local ptssl ptvpn
                    [[ -e "/etc/stunnel/stunnel.conf" ]] && ptssl="$(netstat -nplt 2>/dev/null | grep 'stunnel' | awk {'print $4'} | cut -d: -f2 | xargs)" || ptssl='3128'
                    [[ -e "/etc/openvpn/server.conf" ]] && ptvpn="$(netstat -nplt 2>/dev/null | grep 'openvpn' | awk {'print $4'} | cut -d: -f2 | xargs)" || ptvpn='1194'
                    DEBIAN_FRONTEND=noninteractive apt-get -y install sslh
                    echo -e "#Modo autónomo\n\nRUN=yes\n\nDAEMON=/usr/sbin/sslh\n\nDAEMON_OPTS='--user sslh --listen 0.0.0.0:3128 --ssh 0.0.0.0:22 --ssl 0.0.0.0:$ptssl --http 0.0.0.0:80 --openvpn 127.0.0.1:$ptvpn --pidfile /var/run/sslh/sslh.pid'" > /etc/default/sslh
                    /etc/init.d/sslh start && service sslh start
                }
                echo -e "\n${GREEN}INSTALANDO O SSLH !${RESET}\n"; fun_bar 'fun_instsslh'
                echo -e "\n${GREEN}INICIANDO O SSLH !${RESET}\n"; fun_bar '/etc/init.d/sslh restart && service sslh restart'
                [[ $(netstat -nplt 2>/dev/null | grep -w 'sslh' | wc -l) != '0' ]] && \
                    echo -e "\n${GREEN}INSTALADO COM SUCESSO !${RESET}" || echo -e "\n${RED}ERRO INESPERADO !${RESET}"
                sleep 3; fun_conexao
            } || { echo -e "\n${RED}Retornando..${RESET}"; sleep 2; fun_conexao; }
        } || {
            clear; echo -e "${BG_RED}             REMOVER O SSLH - KRATOS-SSH          ${RESET}\n"
            echo -ne "${GREEN}REALMENTE DESEJA REMOVER O SSLH ${RED}? ${YELLOW}[s/n]:${WHITE} "; read respo
            [[ "$respo" = "s" ]] && {
                fun_delsslh() {
                    /etc/init.d/sslh stop && service sslh stop
                    apt-get remove sslh -y; apt-get purge sslh -y
                }
                echo -e "\n${GREEN}REMOVENDO O SSLH !${RESET}\n"; fun_bar 'fun_delsslh'
                echo -e "\n${GREEN}REMOVIDO COM SUCESSO !${RESET}\n"; sleep 2; fun_conexao
            } || { echo -e "\n${RED}Retornando..${RESET}"; sleep 2; fun_conexao; }
        }
    }

    # ─── MENU PRINCIPAL DE CONEXAO ───
    local x="ok"
    fun_conexao() {
        while true; do
            clear
            echo -e "${BG_BLUE}          MODO DE CONEXÃO - KRATOS-SSH           ${RESET}\n"
            echo -e "${GREEN}SERVICO: ${YELLOW}OPENSSH ${GREEN}PORTA: ${WHITE}$(grep 'Port' /etc/ssh/sshd_config | cut -d' ' -f2 | grep -v 'no' | xargs)"

            local sts1 sts2 sts3 sts4 sts5 sts6 sts7 sts8
            sts6="${GREEN}◉ "
            [[ "$(netstat -tlpn 2>/dev/null | grep 'sslh' | wc -l)" != '0' ]] && { echo -e "${GREEN}SERVICO: ${YELLOW}SSLH: ${GREEN}PORTA: ${WHITE}$(netstat -nplt 2>/dev/null | grep 'sslh' | awk {'print $4'} | cut -d: -f2 | xargs)"; sts7="${GREEN}◉ "; } || sts7="${RED}○ "
            [[ "$(netstat -tlpn 2>/dev/null | grep 'openvpn' | wc -l)" != '0' ]] && { echo -e "${GREEN}SERVICO: ${YELLOW}OPENVPN: ${GREEN}PORTA: ${WHITE}$(netstat -nplt 2>/dev/null | grep 'openvpn' | awk {'print $4'} | cut -d: -f2 | xargs)"; sts5="${GREEN}◉ "; } || sts5="${RED}○ "
            [[ "$(netstat -tlpn 2>/dev/null | grep 'python' | wc -l)" != '0' ]] && { echo -e "${GREEN}SERVICO: ${YELLOW}PROXY SOCKS ${GREEN}PORTA: ${WHITE}$(netstat -nplt 2>/dev/null | grep 'python' | awk {'print $4'} | cut -d: -f2 | xargs)"; sts4="${GREEN}◉ "; } || sts4="${RED}○ "
            [[ -e "/etc/stunnel/stunnel.conf" ]] && { echo -e "${GREEN}SERVICO: ${YELLOW}SSL TUNNEL ${GREEN}PORTA: ${WHITE}$(netstat -nplt 2>/dev/null | grep 'stunnel' | awk {'print $4'} | cut -d: -f2 | xargs)"; sts3="${GREEN}◉ "; } || sts3="${RED}○ "
            [[ "$(netstat -tlpn 2>/dev/null | grep 'dropbear' | wc -l)" != '0' ]] && { echo -e "${GREEN}SERVICO: ${YELLOW}DROPBEAR ${GREEN}PORTA: ${WHITE}$(netstat -nplt 2>/dev/null | grep 'dropbear' | awk -F ":" {'print $4'} | xargs)"; sts2="${GREEN}◉ "; } || sts2="${RED}○ "
            [[ "$(netstat -tlpn 2>/dev/null | grep 'squid' | wc -l)" != '0' ]] && { echo -e "${GREEN}SERVICO: ${YELLOW}SQUID ${GREEN}PORTA: ${WHITE}$(netstat -nplt 2>/dev/null | grep 'squid' | awk -F ":" {'print $4'} | xargs)"; sts1="${GREEN}◉ "; } || sts1="${RED}○ "
            [[ "$(ps x | grep 'slow_dns' | grep -v 'grep' | wc -l)" != '0' ]] && { echo -e "${GREEN}SERVICO: ${YELLOW}SLOWDNS ${GREEN}PORTA: ${WHITE}$(sed -n 1p $KRATOS_DIR/dns/autodns 2>/dev/null | awk '{print $6}' | cut -d':' -f2)"; sts8="${GREEN}◉ "; } || sts8="${RED}○ "

            echo -e "${LINE}"
            echo ""
            echo -e "${RED}[${CYAN}01${RED}] ${WHITE}• ${YELLOW}OPENSSH $sts6${RED}
[${CYAN}02${RED}] ${WHITE}• ${YELLOW}SQUID PROXY $sts1${RED}
[${CYAN}03${RED}] ${WHITE}• ${YELLOW}DROPBEAR $sts2${RED}
[${CYAN}04${RED}] ${WHITE}• ${YELLOW}OPENVPN $sts5${RED}
[${CYAN}05${RED}] ${WHITE}• ${YELLOW}PROXY SOCKS/WEBSOCKET $sts4${RED}
[${CYAN}06${RED}] ${WHITE}• ${YELLOW}SSL TUNNEL $sts3${RED}
[${CYAN}07${RED}] ${WHITE}• ${YELLOW}SSLH MULTIPLEX $sts7${RED}
[${CYAN}08${RED}] ${WHITE}• ${YELLOW}SLOWDNS $sts8${RED}
[${CYAN}09${RED}] ${WHITE}• ${YELLOW}VOLTAR ${GREEN}<${YELLOW}< ${RED}
[${CYAN}00${RED}] ${WHITE}• ${YELLOW}SAIR ${GREEN}<<< ${RESET}"
            echo ""
            echo -e "${LINE}"; echo ""
            tput civis
            echo -ne "${GREEN}OQUE DESEJA FAZER ${YELLOW}?${RED}?${WHITE} "; read x
            tput cnorm; clear
            case $x in
                1|01) fun_openssh ;;
                2|02) fun_squid ;;
                3|03) fun_drop ;;
                4|04) echo -e "${YELLOW}[KRATOS-SSH]${WHITE} OpenVPN disponível no menu principal (opção 19>${RESET}"; sleep 2 ;;
                5|05) fun_socks ;;
                6|06) inst_ssl ;;
                7|07) fun_sslh ;;
                8|08) slow_dns ;;
                9|09) menu ;;
                0|00) echo -e "${RED}Saindo...${RESET}"; sleep 2; clear; exit ;;
                *) echo -e "${RED}Opcao invalida !${RESET}"; sleep 2 ;;
            esac
        done
    }
    fun_conexao
}

# ============================================================
# LIMITER SSH (script separado)
# ============================================================
limiter() {
    local database="$KRATOS_DB"
    fun_multilogin() {
        (
            while read user; do
                [[ $(grep -wc "$user" $database) != '0' ]] && limit="$(grep -w $user $database | cut -d' ' -f2)" || limit='1'
                local conssh="$(ps -u $user | grep sshd | wc -l)"
                [[ "$conssh" -gt "$limit" ]] && pkill -u $user
                [[ -e /etc/openvpn/openvpn-status.log ]] && {
                    local ovp="$(grep -E ,"$user", /etc/openvpn/openvpn-status.log | wc -l)"
                    [[ "$ovp" -gt "$limit" ]] && {
                        local listpid=$(grep -E ,"$user", /etc/openvpn/openvpn-status.log | cut -d "," -f3 | head -n $(($limit - $ovp)))
                        while read ovpids; do
                            (telnet localhost 7505 <<< "kill $ovpids") &>/dev/null &
                        done <<< "$listpid"
                    }
                }
            done <<< "$(awk -F: '$3 >= 1000 {print $1}' /etc/passwd)"
        ) &
    }
    while true; do
        fun_multilogin > /dev/null 2>&1
        sleep 15s
    done
}

# ============================================================
# PONTO DE ENTRADA PRINCIPAL
# ============================================================
main() {
    local cmd="${1:-menu}"

    # Verificar se é root para operações de sistema
    case "$cmd" in
        instalar|install)
            kratos_instalar
            ;;
        menu|"")
            # Verificar se o sistema está instalado
            [[ ! -d $KRATOS_DIR ]] && {
                # Primeira execução - criar estrutura básica
                kratos_setup_dirs
                IP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || curl -s ipv4.icanhazip.com 2>/dev/null || echo "0.0.0.0")
                echo "$IP" > /etc/IP
                [[ ! -f $KRATOS_DB ]] && touch $KRATOS_DB
                echo "$KRATOS_VERSION" > /usr/lib/kratos-ssh
                echo "KRATOS @KRATOS" > /usr/lib/licence
                kratos_install_python_scripts
            }
            menu
            ;;
        expcleaner_auto)
            expcleaner_auto
            ;;
        limiter)
            limiter
            ;;
        banner_padrao)
            kratos_setup_banner
            echo -e "${GREEN}[KRATOS-SSH] Banner padrão aplicado!${RESET}"
            ;;
        *)
            menu
            ;;
    esac
}

# Executar
main "$@"
