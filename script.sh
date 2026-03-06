#!/bin/bash

set -e

echo "================================"
echo "SETUP JAVA + VSCODE"
echo "================================"

AVAILABLE=$(df --output=avail -BG / | tail -1 | tr -dc '0-9')

echo "Espaço disponível em disco: ${AVAILABLE}GB"

if [ "$AVAILABLE" -lt 10 ]; then
    echo "ERRO: Espaço insuficiente para instalação."
    exit 1
fi

echo "Atualizando repositórios..."
sudo apt update

# -----------------------------
# JAVA 21
# -----------------------------
echo
echo "==== JAVA ===="
echo "Verificando qual java instalar"
if apt-cache search openjdk-21-jdk | grep openjdk-21-jdk > /dev/null; then
    echo "Instalando JDK 21"
    sudo apt install -y openjdk-21-jdk
else
    echo "JDK 21 não encontrado, instalando JDK 17"
    sudo apt install -y openjdk-17-jdk
fi

# -----------------------------
# MAVEN / GRADLE / GIT
# -----------------------------
echo
echo "==== MAVEN / GRADLE / GIT ===="
echo "Instalando ferramentas de build..."

sudo apt install -y maven gradle git

# -----------------------------
# REPOSITORIO VSCODE
# -----------------------------
echo
echo "==== REPOSITÓRIO VSCODE ===="
if [ ! -f /etc/apt/sources.list.d/vscode.list ]; then
    echo "Adicionando repositório do VS Code..."

    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/microsoft.gpg > /dev/null

    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
    sudo tee /etc/apt/sources.list.d/vscode.list

    sudo apt update
fi

# -----------------------------
# INSTALA / ATUALIZA VSCODE
# -----------------------------
echo
echo "==== VSCODE ===="
if command -v code >/dev/null 2>&1; then
    echo "VS Code já instalado — atualizando..."
    sudo apt install -y code
else
    echo "Instalando VS Code..."
    sudo apt install -y code
fi

# -----------------------------
# EXTENSÕES JAVA
# -----------------------------
echo
echo "==== EXTENSÕES JAVA ===="
echo "Instalando extensões Java..."

code --install-extension vscjava.vscode-java-pack || true
code --install-extension redhat.java || true
code --install-extension vscjava.vscode-maven || true
code --install-extension vscjava.vscode-java-debug || true

# -----------------------------
# CRIAR PASTA DE PROJETOS E TESTE NA ÁREA DE TRABALHO
# -----------------------------

echo
echo "==== CRIANDO PROJETOS/TEST ===="
echo "Criando pasta PROJETOS/TEST na Área de Trabalho e arquivo TestSetup.java..."

# Caminho base na Área de Trabalho
BASE_DIR="$HOME/Desktop/PROJETOS/TEST"

# Cria diretórios, se não existirem
mkdir -p "$BASE_DIR"

# Cria o arquivo TestSetup.java
cat > "$BASE_DIR/TestSetup.java" <<EOL
public class TestSetup {
    public static void main(String[] args) {
        // Declare variables
        int number1 = 10;
        int number2 = 20;
        int sum = number1 + number2;

        // Print the sum
        System.out.println("The sum of " + number1 + " and " + number2 + " is: " + sum);

        // A simple for loop
        for (int i = 0; i < 5; i++) {
            System.out.println("Loop iteration " + (i + 1));
        }

        // End of the program
        System.out.println("Test completed!");
    }
}
EOL

echo "Arquivo criado em: $BASE_DIR/TestSetup.java"

# -----------------------------
# VERIFICAÇÕES
# -----------------------------
echo
echo "==== VERSÕES INSTALADAS ===="

java -version
mvn -version
gradle -version
code --version

echo
echo "Setup concluído."
