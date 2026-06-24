#!/bin/bash
#====================================================
#   KRATOS SSH - SETUP
#   Painel de gerenciamento SSH/OpenVPN/Proxy
#
#   USO:
#     git clone https://github.com/SEU_USUARIO/KratosSSH.git
#     cd KratosSSH
#     sudo bash setup.sh
#
#   (Esse script precisa estar dentro da pasta do repo,
#    junto com core/, bot/ e vendor/ - ele não funciona
#    sozinho fora do clone.)
#====================================================
set -e

if [[ ! -d "$(dirname "${BASH_SOURCE[0]}")/core" ]]; then
    echo -e "\033[1;31mErro:\033[0m pasta 'core' não encontrada junto deste script."
    echo "Clone o repositório completo antes de rodar:"
    echo "  git clone https://github.com/SEU_USUARIO/KratosSSH.git"
    echo "  cd KratosSSH && sudo bash setup.sh"
    exit 1
fi

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
SCOLOR='\033[0m'

[[ "$(whoami)" != "root" ]] && {
    echo -e "${RED}Execute como root (sudo -i)${SCOLOR}"
    exit 1
}

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${YELLOW}=== Instalando KRATOS SSH ===${SCOLOR}"

# 1) Diretorios de estado do painel
mkdir -p /etc/KratosSSH/senha
mkdir -p /etc/KratosSSH/userteste
mkdir -p /etc/KratosSSH/backups
mkdir -p /etc/KratosSSH/dns
mkdir -p /etc/bot

# 2) Copia o core (comandos do painel) para /etc/KratosSSH e expõe como comandos globais
mkdir -p /etc/KratosSSH/core
cp -f "$BASE_DIR"/core/* /etc/KratosSSH/core/ 2>/dev/null || true
cp -rf "$BASE_DIR"/core/TCP-Speed /etc/KratosSSH/core/ 2>/dev/null || true
cp -rf "$BASE_DIR"/core/Sources_list /etc/KratosSSH/core/ 2>/dev/null || true

# Lista de comandos que devem virar binarios globais (chamaveis de qualquer lugar)
COMMANDS=(menu ajuda addhost delhost criarusuario criarteste remover alterarsenha
alterarlimite mudardata droplimiter limiter uexpired expcleaner infousers detalhes
userbackup verifatt verifbot attscript delscript blockt banner cabecalho otimizar
speedtest reiniciarservicos reiniciarsistema senharoot badvpn conexao sshmonitor
slow_dns slowdns instsqd squid3 open.py proxy.py wsproxy.py addIP)

for cmd in "${COMMANDS[@]}"; do
    if [[ -f /etc/KratosSSH/core/$cmd ]]; then
        chmod +x /etc/KratosSSH/core/$cmd
        ln -sf /etc/KratosSSH/core/$cmd /usr/local/bin/"$cmd"
    fi
done

# 3) Vendor (bibliotecas/binarios de terceiros, mantidos como estao)
mkdir -p /etc/KratosSSH/vendor
cp -f "$BASE_DIR"/vendor/* /etc/KratosSSH/vendor/
chmod +x /etc/KratosSSH/vendor/badvpn-udpgw 2>/dev/null || true

# ShellBot precisa estar em /etc/KratosSSH/ShellBot.sh (e onde o painel espera)
cp -f "$BASE_DIR"/vendor/ShellBot.sh /etc/KratosSSH/ShellBot.sh

# 4) Bot do Telegram
mkdir -p /etc/KratosSSH/botfiles
cp -f "$BASE_DIR"/bot/bot /etc/KratosSSH/botfiles/bot
cp -f "$BASE_DIR"/bot/botssh /etc/KratosSSH/botfiles/botssh
chmod +x /etc/KratosSSH/botfiles/bot /etc/KratosSSH/botfiles/botssh
ln -sf /etc/KratosSSH/botfiles/botssh /usr/local/bin/botssh

# 5) Marca de instalacao + "licenca" local (gate interno usado por badvpn/conexao/sshmonitor/bot)
#    Isso NAO valida nada externamente - é só uma flag local que o proprio
#    toolkit checa antes de habilitar certas funcoes. Mantida pra nao ter
#    que reescrever a logica de cada script.
mkdir -p /usr/lib
touch /usr/lib/kratosssh
echo "KRATOSSSH @KratosSSH_Team" > /usr/lib/kratosssh_licence

# 6) IP publico do servidor (varios scripts leem /etc/IP)
if [[ ! -f /etc/IP ]]; then
    MYIP=$(curl -s -4 ifconfig.me || curl -s -4 icanhazip.com || echo "127.0.0.1")
    echo "$MYIP" > /etc/IP
fi

# 7) Versao
echo "1" > /etc/KratosSSH/core/versao

echo -e "${GREEN}=== KRATOS SSH instalado! ===${SCOLOR}"
echo -e "${YELLOW}Digite 'menu' para abrir o painel.${SCOLOR}"
echo ""
echo -e "${RED}ATENCAO - revise antes de usar em produção:${SCOLOR}"
echo "  - core/slow_dns e core/slowdns têm placeholders SEU-DOMINIO-AQUI.com / SEU_IP_DO_SERVIDOR"
echo "    (apontavam pra infra do criador original do source, precisam apontar pra sua)"
echo "  - dependências de sistema (openvpn, easy-rsa, squid, stunnel4, badvpn deps,"
echo "    python3, screen, iptables-persistent) NÃO são instaladas por este script -"
echo "    ele só organiza e conecta as peças. Rode o instsqd/easyrsa conforme a sua distro."
echo "  - vendor/GLTunnel_compiled.py e vendor/shadow_final.py são binários de terceiros"
echo "    (compilados, sem código fonte) - mantidos como dependência, não fazem parte"
echo "    do código que você pode editar livremente."
