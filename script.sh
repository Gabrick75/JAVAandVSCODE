#!/bin/bash

set -e

echo "=============================="
echo "SETUP JAVA + VSCODE EMPRESA"
echo "=============================="

echo "Atualizando repositórios..."
sudo apt update

# -----------------------------
# JAVA 21
# -----------------------------
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
echo "Instalando ferramentas de build..."

sudo apt install -y maven gradle git

# -----------------------------
# REPOSITORIO VSCODE
# -----------------------------
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
echo "Instalando extensões Java..."

code --install-extension vscjava.vscode-java-pack || true
code --install-extension redhat.java || true
code --install-extension vscjava.vscode-maven || true
code --install-extension vscjava.vscode-java-debug || true

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
