#!/bin/bash
#====================================================
#   KRATOS SSH
#   Bootstrap de instalação em 1 arquivo
#
#   USO (na VPS, como root):
#     wget https://raw.githubusercontent.com/Thgamer79/Kratos-vps/refs/heads/main/setup.sh
#     chmod +x setup.sh
#     ./setup.sh
#====================================================

# ====== CONFIGURE AQUI ======
REPO_USER="Thgamer79"
REPO_NAME="Kratos-vps"
# =============================

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
SCOLOR='\033[0m'

[[ "$(whoami)" != "root" ]] && {
    echo -e "${RED}Execute como root (sudo -i)${SCOLOR}"
    exit 1
}

command -v wget >/dev/null 2>&1 || command -v curl >/dev/null 2>&1 || {
    echo -e "${YELLOW}Instalando wget...${SCOLOR}"
    apt-get update -y >/dev/null 2>&1 && apt-get install -y wget >/dev/null 2>&1
}
command -v tar >/dev/null 2>&1 || apt-get install -y tar >/dev/null 2>&1

download() {
    # $1 = url, $2 = destino
    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$2" "$1"
    else
        curl -sL -o "$2" "$1"
    fi
}

TMPDIR=$(mktemp -d)
cd "$TMPDIR"

echo -e "${YELLOW}Baixando ${REPO_NAME}...${SCOLOR}"

OK=0
for BRANCH in main master; do
    URL="https://github.com/${REPO_USER}/${REPO_NAME}/archive/refs/heads/${BRANCH}.tar.gz"
    download "$URL" repo.tar.gz
    if [[ -s repo.tar.gz ]] && tar -tzf repo.tar.gz >/dev/null 2>&1; then
        OK=1
        break
    fi
done

if [[ "$OK" != "1" ]]; then
    echo -e "${RED}Falha ao baixar o repositório.${SCOLOR}"
    echo "Verifique se REPO_USER/REPO_NAME estão certos no topo deste script"
    echo "e se o repositório é público (ou se você está autenticado, se for privado)."
    cd / && rm -rf "$TMPDIR"
    exit 1
fi

tar -xzf repo.tar.gz
EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "${REPO_NAME}-*" | head -n1)

if [[ -z "$EXTRACTED_DIR" || ! -f "$EXTRACTED_DIR/install.sh" ]]; then
    echo -e "${RED}install.sh não encontrado no repositório baixado.${SCOLOR}"
    cd / && rm -rf "$TMPDIR"
    exit 1
fi

cd "$EXTRACTED_DIR"
chmod +x install.sh
echo -e "${GREEN}Download ok. Rodando install.sh...${SCOLOR}"
bash install.sh

cd /
rm -rf "$TMPDIR"
