#!/usr/bin/env bash

set -Eeuo pipefail

#############################################
# CONFIGURAÇÕES
#############################################

LOGFILE="$HOME/setup-java-vscode.log"
SLEEP_TIME=3
MAX_RETRY=5

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
    local LEVEL="$1"
    local MSG="$2"
    local DATE

    DATE=$(date '+%Y-%m-%d %H:%M:%S')

    echo "$DATE [$LEVEL] $MSG" >> "$LOGFILE"

    case "$LEVEL" in
        INFO) echo -e "${BLUE}$DATE [INFO]${NC} $MSG";;
        OK) echo -e "${GREEN}$DATE [OK]${NC} $MSG";;
        WARN) echo -e "${YELLOW}$DATE [WARN]${NC} $MSG";;
        ERROR) echo -e "${RED}$DATE [ERROR]${NC} $MSG";;
    esac
}

trap 'log ERROR "Erro na linha $LINENO"; exit 1' ERR

#############################################
# MOSTRAR SISTEMA
#############################################

show_system(){

    log INFO "Detectando sistema operacional..."

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="$NAME"
        VERSION="$VERSION"
    else
        DISTRO="Desconhecido"
        VERSION=""
    fi

    KERNEL=$(uname -r)
    ARCH=$(uname -m)

    echo
    echo -e "${CYAN}===== SISTEMA DETECTADO =====${NC}"
    echo -e "${BLUE}Distribuição:${NC} $DISTRO"
    echo -e "${BLUE}Versão:${NC} $VERSION"
    echo -e "${BLUE}Kernel:${NC} $KERNEL"
    echo -e "${BLUE}Arquitetura:${NC} $ARCH"
    echo
}

#############################################
# INTERNET
#############################################

check_internet(){

    log INFO "Verificando conexão..."

    if ! ping -c1 8.8.8.8 >/dev/null 2>&1; then
        log ERROR "Sem conexão com internet"
        exit 1
    fi

    log OK "Internet OK"
}

#############################################
# ESPERAR APT
#############################################

wait_for_apt(){

    while \
        fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || \
        fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
        fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1
    do
        log WARN "APT ocupado aguardando..."
        sleep "$SLEEP_TIME"
    done
}

#############################################
# APT COM RETRY
#############################################

apt_retry(){

    local CMD="$1"
    local COUNT=0

    until [ $COUNT -ge $MAX_RETRY ]
    do

        wait_for_apt

        if eval "$CMD"; then
            log OK "Executado: $CMD"
            return
        fi

        COUNT=$((COUNT+1))

        log WARN "Falha ($COUNT/$MAX_RETRY)"
        sleep "$SLEEP_TIME"

    done

    log ERROR "Falha definitiva: $CMD"
    exit 1
}

#############################################
# ESPAÇO EM DISCO
#############################################

check_disk(){

AVAILABLE=$(df --output=avail -BG / | tail -1 | tr -dc '0-9')

log INFO "Espaço disponível: ${AVAILABLE}GB"

if [ "$AVAILABLE" -lt 8 ]; then
    log ERROR "Espaço insuficiente"
    exit 1
fi

}

#############################################
# INÍCIO
#############################################

clear

echo -e "${CYAN}"
echo "================================"
echo "SETUP JAVA + VSCODE"
echo "================================"
echo -e "${NC}"

show_system
check_internet
check_disk

#############################################
# UPDATE
#############################################

log INFO "Atualizando repositórios"
apt_retry "sudo apt update -y"

#############################################
# JAVA
#############################################

echo
echo -e "${CYAN}==== JAVA ====${NC}"

if apt-cache search openjdk-21-jdk | grep -q openjdk-21-jdk; then
    log INFO "Instalando JDK 21"
    apt_retry "sudo apt install -y openjdk-21-jdk"
else
    log WARN "JDK21 não disponível — usando JDK17"
    apt_retry "sudo apt install -y openjdk-17-jdk"
fi

#############################################
# MAVEN / GRADLE / GIT
#############################################

log INFO "Instalando ferramentas de build"

apt_retry "sudo apt install -y maven gradle git"

#############################################
# VSCODE REPOSITÓRIO
#############################################

if [ ! -f /etc/apt/sources.list.d/vscode.list ]; then

    log INFO "Adicionando repositório VSCode"

    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/microsoft.gpg >/dev/null

    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
    sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null

    apt_retry "sudo apt update -y"
fi

#############################################
# VSCODE
#############################################

if command -v code >/dev/null 2>&1; then
    log INFO "VSCode já instalado"
else
    log INFO "Instalando VSCode"
fi

apt_retry "sudo apt install -y code"

#############################################
# EXTENSÕES
#############################################

log INFO "Instalando extensões Java"

code --install-extension vscjava.vscode-java-pack || true
code --install-extension redhat.java || true
code --install-extension vscjava.vscode-maven || true
code --install-extension vscjava.vscode-java-debug || true

#############################################
# PROJETO TESTE
#############################################

BASE_DIR="$HOME/Desktop/PROJETOS/TEST"
mkdir -p "$BASE_DIR"

cat > "$BASE_DIR/TestSetup.java" <<EOF
public class TestSetup {
    public static void main(String[] args) {

        int number1 = 10;
        int number2 = 20;
        int sum = number1 + number2;

        System.out.println("The sum is: " + sum);

        for(int i=0;i<5;i++){
            System.out.println("Loop " + (i+1));
        }

        System.out.println("Setup OK!");
    }
}
EOF

log OK "Projeto teste criado: $BASE_DIR"

#############################################
# VERSÕES
#############################################

echo
echo -e "${CYAN}==== VERSÕES INSTALADAS ====${NC}"

java -version
mvn -version
gradle -version
code --version

echo
log OK "Setup concluído com sucesso"
