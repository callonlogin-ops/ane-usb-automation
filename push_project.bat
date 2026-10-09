@echo off
setlocal enabledelayedexpansion

REM ============================================
REM Automação Git para Windows 10
REM Clone/Push repositório com cópia de arquivos
REM ============================================

set REPO_URL=https://github.com/katopz/ane-usb-util.git
set WORKDIR=%USERPROFILE%\Desktop\ane-usb-util
set BRANCH=main
set REMOTE_NAME=origin

echo.
echo ========================================
echo Verificando dependências
echo ========================================

where git >nul 2>nul
if errorlevel 1 (
  echo [ERRO] Git nao encontrado.
  echo Baixe e instale Git for Windows em: https://git-scm.com/download/win
  pause
  exit /b 1
)

echo [OK] Git encontrado

REM Verificar se o repositório já existe
if not exist "%WORKDIR%\.git" (
  echo.
  echo ========================================
  echo Clonando repositório
  echo ========================================
  git clone "%REPO_URL%" "%WORKDIR%"
  if errorlevel 1 (
    echo [ERRO] Falha ao clonar repositório
    pause
    exit /b 1
  )
) else (
  echo [OK] Repositório já existe em: %WORKDIR%
)

cd /d "%WORKDIR%"
if errorlevel 1 (
  echo [ERRO] Falha ao acessar diretório: %WORKDIR%
  pause
  exit /b 1
)

REM Garantir que o remote origin existe
echo.
echo ========================================
echo Verificando remote
echo ========================================

git remote get-url %REMOTE_NAME% >nul 2>nul
if errorlevel 1 (
  echo [INFO] Adicionando remote...
  git remote add %REMOTE_NAME% "%REPO_URL%"
)

echo [OK] Remote configurado

REM Ajustar branch
echo.
echo ========================================
echo Verificando branch
echo ========================================

git checkout %BRANCH% 2>nul
if errorlevel 1 (
  echo [INFO] Branch %BRANCH% não existe. Criando...
  git checkout -b %BRANCH%
)

echo [OK] Branch: %BRANCH%

REM Copiar arquivos locais (AJUSTE CONFORME SEU PROJETO)
echo.
echo ========================================
echo Copiando arquivos locais
echo ========================================

REM DESCOMENTE E AJUSTE UMA DESTAS OPÇÕES:

REM Opção 1: Copiar de uma pasta específica do seu computador
REM xcopy "C:\Users\SeuUsuario\Desktop\seu_projeto\*" "%WORKDIR%\" /E /Y /I

REM Opção 2: Copiar de Downloads
REM xcopy "%USERPROFILE%\Downloads\seu_projeto\*" "%WORKDIR%\" /E /Y /I

REM Opção 3: Copiar de Documentos
REM xcopy "%USERPROFILE%\Documents\seu_projeto\*" "%WORKDIR%\" /E /Y /I

REM Opção 4: Descomente se quiser copiar tudo de uma pasta
REM set COPY_FROM=C:\caminho\completo\projeto
REM if exist "%COPY_FROM%" (
REM   xcopy "%COPY_FROM%\*" "%WORKDIR%\" /E /Y /I
REM   echo [OK] Arquivos copiados
REM ) else (
REM   echo [AVISO] Pasta de origem não encontrada: %COPY_FROM%
REM )

echo [INFO] Nenhum arquivo copiado (ajuste os caminhos se necessário)

REM Adicionar arquivos ao Git
echo.
echo ========================================
echo Adicionando arquivos ao Git
echo ========================================

git add .
if errorlevel 1 (
  echo [ERRO] Falha ao adicionar arquivos
  pause
  exit /b 1
)

echo [OK] Arquivos adicionados

REM Verificar se há mudanças
echo.
echo ========================================
echo Verificando mudanças
echo ========================================

git diff --cached --quiet
if errorlevel 0 (
  echo [INFO] Nenhuma alteração detectada
) else (
  echo [INFO] Alterações detectadas. Criando commit...
  
  REM Configurar Git se necessário
  git config user.name "Automated" 2>nul
  git config user.email "automated@local" 2>nul
  
  git commit -m "Automated update from Windows 10 - %date% %time%"
  if errorlevel 1 (
    echo [AVISO] Falha ao fazer commit
  ) else (
    echo [OK] Commit criado
  )
)

REM Fazer push
echo.
echo ========================================
echo Fazendo push para GitHub
echo ========================================

git push %REMOTE_NAME% %BRANCH%
if errorlevel 1 (
  echo [AVISO] Falha ao fazer push
  echo [INFO] Você pode precisar autenticar com seu token GitHub
  echo [INFO] Instruções: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token
) else (
  echo [OK] Push realizado com sucesso
)

REM Finalização
echo.
echo ========================================
echo Processo concluído
echo ========================================
echo Repositório: %REPO_URL%
echo Diretório local: %WORKDIR%
echo Branch: %BRANCH%
echo.

pause
