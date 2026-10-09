#!/bin/bash
set -eu

#=============================================
# Automação APK → Descompilação → GitHub
# Termux (Android)
#=============================================

REPO_URL="https://github.com/katopz/ane-usb-util.git"
WORKDIR="$HOME/ane-usb-util"
DECODE_DIR="$HOME/apk-decoded"
BRANCH="main"
REMOTE_NAME="origin"
APK_FILE="$HOME/storage/downloads/app.apk"

echo ""
echo "=========================================="
echo "Automação APK para GitHub - Termux"
echo "=========================================="
echo ""

# Verificar dependências
echo "=========================================="
echo "Verificando dependências"
echo "=========================================="

if ! command -v git &> /dev/null; then
    echo "[ERRO] Git não encontrado"
    echo "Instale com: pkg install git"
    exit 1
fi
echo "[OK] Git encontrado"

if ! command -v java &> /dev/null; then
    echo "[ERRO] Java não encontrado"
    echo "Instale com: pkg install openjdk-17"
    exit 1
fi
echo "[OK] Java encontrado"

if ! command -v apktool &> /dev/null; then
    echo "[ERRO] apktool não encontrado"
    echo ""
    echo "Como instalar apktool no Termux:"
    echo "  1. pkg install apktool"
    echo "  2. Ou baixe manualmente em: https://bitbucket.org/iBotPeaches/apktool/downloads/"
    echo "  3. Coloque em: $HOME/bin/apktool.jar"
    echo ""
    exit 1
fi
echo "[OK] apktool encontrado"

# Verificar se o APK existe
if [ ! -f "$APK_FILE" ]; then
    echo "[ERRO] Arquivo APK não encontrado: $APK_FILE"
    echo ""
    echo "Ajuste a variável APK_FILE no script ou coloque o APK em:"
    echo "  $HOME/storage/downloads/app.apk"
    echo ""
    echo "Ou execute com um arquivo específico:"
    echo "  APK_FILE=/caminho/do/arquivo.apk $0"
    exit 1
fi
echo "[OK] APK encontrado: $APK_FILE"

# Criar diretório de descompilação
echo ""
echo "=========================================="
echo "Preparando diretório de descompilação"
echo "=========================================="

if [ -d "$DECODE_DIR" ]; then
    echo "[INFO] Limpando diretório anterior: $DECODE_DIR"
    rm -rf "$DECODE_DIR"
fi

mkdir -p "$DECODE_DIR"
if [ $? -ne 0 ]; then
    echo "[ERRO] Falha ao criar diretório: $DECODE_DIR"
    exit 1
fi
echo "[OK] Diretório criado: $DECODE_DIR"

# Descompilar APK
echo ""
echo "=========================================="
echo "Descompilando APK com apktool"
echo "=========================================="
echo "Este processo pode levar alguns minutos..."
echo ""

apktool d -f "$APK_FILE" -o "$DECODE_DIR"
if [ $? -ne 0 ]; then
    echo "[ERRO] Falha ao descompilar APK"
    echo "[INFO] Verifique se o arquivo APK é válido"
    exit 1
fi
echo "[OK] APK descompilado com sucesso"

# Clonar repositório se necessário
echo ""
echo "=========================================="
echo "Preparando repositório Git"
echo "=========================================="

if [ ! -d "$WORKDIR/.git" ]; then
    echo "[INFO] Clonando repositório..."
    git clone "$REPO_URL" "$WORKDIR"
    if [ $? -ne 0 ]; then
        echo "[ERRO] Falha ao clonar repositório"
        exit 1
    fi
else
    echo "[OK] Repositório já existe"
fi

cd "$WORKDIR"
if [ $? -ne 0 ]; then
    echo "[ERRO] Falha ao acessar diretório: $WORKDIR"
    exit 1
fi

# Configurar remote
echo "[INFO] Configurando remote..."
if ! git remote get-url "$REMOTE_NAME" &> /dev/null; then
    git remote add "$REMOTE_NAME" "$REPO_URL"
fi

# Ajustar branch
git checkout "$BRANCH" 2>/dev/null || git checkout -b "$BRANCH"
echo "[OK] Git configurado"

# Copiar arquivos descompilados para o repositório
echo ""
echo "=========================================="
echo "Copiando arquivos do APK descompilado"
echo "=========================================="

echo "[INFO] Copiando de: $DECODE_DIR"
echo "[INFO] Para: $WORKDIR"

cp -r "$DECODE_DIR"/* "$WORKDIR/" 2>/dev/null || {
    echo "[AVISO] Alguns arquivos podem não ter sido copiados"
}

if [ $? -eq 0 ]; then
    echo "[OK] Arquivos copiados"
fi

# Adicionar ao Git
echo ""
echo "=========================================="
echo "Adicionando arquivos ao Git"
echo "=========================================="

git add .
if [ $? -ne 0 ]; then
    echo "[ERRO] Falha ao adicionar arquivos"
    exit 1
fi
echo "[OK] Arquivos adicionados"

# Commit
echo ""
echo "=========================================="
echo "Criando commit"
echo "=========================================="

if git diff --cached --quiet; then
    echo "[INFO] Nenhuma alteração detectada"
else
    echo "[INFO] Alterações detectadas..."
    
    git config user.name "Automated-APK-Termux" 2>/dev/null || true
    git config user.email "automated@termux.local" 2>/dev/null || true
    
    APK_NAME=$(basename "$APK_FILE")
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    git commit -m "APK decoded: $APK_NAME - $TIMESTAMP"
    if [ $? -ne 0 ]; then
        echo "[AVISO] Falha ao fazer commit"
    else
        echo "[OK] Commit criado"
    fi
fi

# Push
echo ""
echo "=========================================="
echo "Fazendo push para GitHub"
echo "=========================================="

git push "$REMOTE_NAME" "$BRANCH"
if [ $? -ne 0 ]; then
    echo "[AVISO] Falha ao fazer push"
    echo "[INFO] Possíveis motivos:"
    echo "  - Você não autenticou com GitHub"
    echo "  - Token expirou ou foi revogado"
    echo "  - Você não tem permissão no repositório"
    echo ""
    echo "[INFO] Para configurar autenticação:"
    echo "  1. Use Git via SSH ou HTTPS com token"
    echo "  2. Crie um Personal Access Token:"
    echo "     https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token"
    echo "  3. Configure Git Credential Manager no Termux"
else
    echo "[OK] Push realizado com sucesso"
fi

# Resumo final
echo ""
echo "=========================================="
echo "RESUMO DO PROCESSO"
echo "=========================================="
echo ""
echo "[APK Original]"
echo "  Arquivo: $APK_FILE"
echo ""
echo "[Descompilado]"
echo "  Pasta: $DECODE_DIR"
echo ""
echo "[Repositório Git]"
echo "  URL: $REPO_URL"
echo "  Local: $WORKDIR"
echo "  Branch: $BRANCH"
echo ""
echo "[Próximos passos]"
echo "  1. Verifique os arquivos em: $WORKDIR"
echo "  2. Se houver erros, corrija manualmente"
echo "  3. Execute este script novamente"
echo ""
echo "=========================================="
echo ""
