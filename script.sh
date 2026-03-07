#!/bin/bash

set -e

# ==============================
# CORES
# ==============================

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m'

# ==============================
# FUNÇÃO ESPERAR APT
# ==============================

wait_for_apt() {
    while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
        echo -e "${YELLOW}⏳ Esperando apt liberar...${NC}"
        sleep 3
    done
}

# ==============================
# INÍCIO
# ==============================

echo -e "${CYAN}"
echo "================================"
echo "SETUP JAVA + VSCODE"
echo "================================"
echo -e "${NC}"

AVAILABLE=$(df --output=avail -BG / | tail -1 | tr -dc '0-9')

echo -e "${BLUE}Espaço disponível em disco: ${AVAILABLE}GB${NC}"

if [ "$AVAILABLE" -lt 10 ]; then
    echo -e "${RED}ERRO: Espaço insuficiente para instalação.${NC}"
    exit 1
fi

# ==============================
# UPDATE
# ==============================

echo -e "${CYAN}Atualizando repositórios...${NC}"
wait_for_apt
sudo apt update

# ==============================
# JAVA
# ==============================

echo
echo -e "${CYAN}==== JAVA ====${NC}"

if apt-cache search openjdk-21-jdk | grep openjdk-21-jdk > /dev/null; then
    echo -e "${GREEN}Instalando JDK 21${NC}"
    wait_for_apt
    sudo apt install -y openjdk-21-jdk
else
    echo -e "${YELLOW}JDK 21 não encontrado, instalando JDK 17${NC}"
    wait_for_apt
    sudo apt install -y openjdk-17-jdk
fi

# ==============================
# MAVEN / GRADLE / GIT
# ==============================

echo
echo -e "${CYAN}==== MAVEN / GRADLE / GIT ====${NC}"
echo -e "${BLUE}Instalando ferramentas de build...${NC}"

wait_for_apt
sudo apt install -y maven gradle git

# ==============================
# REPOSITÓRIO VSCODE
# ==============================

echo
echo -e "${CYAN}==== REPOSITÓRIO VSCODE ====${NC}"

if [ ! -f /etc/apt/sources.list.d/vscode.list ]; then

    echo -e "${GREEN}Adicionando repositório do VS Code...${NC}"

    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/microsoft.gpg > /dev/null

    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
    sudo tee /etc/apt/sources.list.d/vscode.list

    wait_for_apt
    sudo apt update
fi

# ==============================
# INSTALAR VSCODE
# ==============================

echo
echo -e "${CYAN}==== VSCODE ====${NC}"

if command -v code >/dev/null 2>&1; then
    echo -e "${BLUE}VS Code já instalado — atualizando...${NC}"
else
    echo -e "${GREEN}Instalando VS Code...${NC}"
fi

wait_for_apt
sudo apt install -y code

# ==============================
# EXTENSÕES JAVA
# ==============================

echo
echo -e "${CYAN}==== EXTENSÕES JAVA ====${NC}"

code --install-extension vscjava.vscode-java-pack || true
code --install-extension redhat.java || true
code --install-extension vscjava.vscode-maven || true
code --install-extension vscjava.vscode-java-debug || true

# ==============================
# CRIAR PROJETO TESTE
# ==============================

echo
echo -e "${CYAN}==== CRIANDO PROJETOS/TEST ====${NC}"

BASE_DIR="$HOME/Desktop/PROJETOS/TEST"

mkdir -p "$BASE_DIR"

cat > "$BASE_DIR/TestSetup.java" <<EOL
public class TestSetup {
    public static void main(String[] args) {

        int number1 = 10;
        int number2 = 20;
        int sum = number1 + number2;

        System.out.println("The sum of " + number1 + " and " + number2 + " is: " + sum);

        for (int i = 0; i < 5; i++) {
            System.out.println("Loop iteration " + (i + 1));
        }

        System.out.println("Test completed!");
    }
}
EOL

echo -e "${GREEN}Arquivo criado em:${NC} $BASE_DIR/TestSetup.java"

# ==============================
# VERIFICAÇÕES
# ==============================

echo
echo -e "${CYAN}==== VERSÕES INSTALADAS ====${NC}"

java -version
mvn -version
gradle -version
code --version

echo
echo -e "${GREEN}✔ Setup concluído com sucesso.${NC}"
