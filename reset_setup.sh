#!/usr/bin/env bash

set -Eeuo pipefail

#############################################
# CORES
#############################################

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m'

#############################################
# LOG
#############################################

log(){
    echo -e "$1"
}

#############################################
# DETECTAR SISTEMA
#############################################

show_system(){

echo
echo -e "${CYAN}===== SISTEMA =====${NC}"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo -e "${BLUE}Distribuição:${NC} $NAME"
    echo -e "${BLUE}Versão:${NC} $VERSION"
fi

echo -e "${BLUE}Kernel:${NC} $(uname -r)"
echo -e "${BLUE}Arquitetura:${NC} $(uname -m)"
echo
}

#############################################
# ESPERAR APT
#############################################

wait_for_apt(){

while \
    sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || \
    sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
    sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1
do
    log "${YELLOW}APT ocupado... aguardando${NC}"
    sleep 3
done

}

#############################################
# INÍCIO
#############################################

clear

echo -e "${RED}"
echo "================================="
echo "   RESET JAVA + VSCODE SETUP"
echo "================================="
echo -e "${NC}"

show_system

#############################################
# REMOVER VSCODE
#############################################

echo
log "${CYAN}Removendo VSCode...${NC}"

wait_for_apt
sudo apt purge -y code || true

#############################################
# REMOVER REPOSITÓRIO MICROSOFT
#############################################

echo
log "${CYAN}Removendo repositório Microsoft...${NC}"

sudo rm -f /etc/apt/sources.list.d/vscode.list
sudo rm -f /usr/share/keyrings/microsoft.gpg

#############################################
# REMOVER JAVA
#############################################

echo
log "${CYAN}Removendo Java...${NC}"

wait_for_apt
sudo apt purge -y openjdk-21-jdk openjdk-17-jdk || true

#############################################
# REMOVER MAVEN / GRADLE / GIT
#############################################

echo
log "${CYAN}Removendo Maven, Gradle e Git...${NC}"

wait_for_apt
sudo apt purge -y maven gradle git || true

#############################################
# LIMPAR DEPENDÊNCIAS
#############################################

echo
log "${CYAN}Limpando dependências...${NC}"

wait_for_apt
sudo apt autoremove -y

wait_for_apt
sudo apt clean

#############################################
# REMOVER PROJETO TESTE
#############################################

BASE_DIR="$HOME/Desktop/PROJETOS"

echo
log "${CYAN}Removendo projeto teste...${NC}"

rm -rf "$BASE_DIR"

#############################################
# REMOVER EXTENSÕES VSCODE
#############################################

echo
log "${CYAN}Removendo extensões VSCode...${NC}"

rm -rf "$HOME/.vscode"

#############################################
# FINAL
#############################################

echo
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN} RESET CONCLUÍDO ${NC}"
echo -e "${GREEN}=================================${NC}"
