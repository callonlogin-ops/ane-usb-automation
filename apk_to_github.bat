@echo off
setlocal enabledelayedexpansion

REM ============================================
REM Automação APK → Descompilação → GitHub
REM Windows 10 com apktool
REM ============================================

set REPO_URL=https://github.com/katopz/ane-usb-util.git
set WORKDIR=%USERPROFILE%\Desktop\ane-usb-util
set DECODE_DIR=%USERPROFILE%\Desktop\apk-decoded
set BRANCH=main
set REMOTE_NAME=origin
set APK_FILE=%USERPROFILE%\Downloads\app.apk

echo.
echo ========================================
echo Automação APK para GitHub
echo ========================================
echo.

REM Verificar dependências
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

where java >nul 2>nul
if errorlevel 1 (
  echo [ERRO] Java nao encontrado.
  echo Baixe e instale Java em: https://www.oracle.com/java/technologies/downloads/
  pause
  exit /b 1
)
echo [OK] Java encontrado

if not exist "%USERPROFILE%\apktool\apktool.jar" (
  echo [ERRO] apktool nao encontrado em: %USERPROFILE%\apktool\apktool.jar
  echo.
  echo Como instalar apktool no Windows:
  echo 1. Crie a pasta: %USERPROFILE%\apktool
  echo 2. Baixe apktool.jar em: https://bitbucket.org/iBotPeaches/apktool/downloads/
  echo 3. Coloque o arquivo em: %USERPROFILE%\apktool\apktool.jar
  echo 4. Depois rode este script novamente
  echo.
  pause
  exit /b 1
)
echo [OK] apktool encontrado

REM Verificar se o APK existe
if not exist "%APK_FILE%" (
  echo [ERRO] Arquivo APK nao encontrado: %APK_FILE%
  echo.
  echo Ajuste a variavel APK_FILE no script ou coloque o APK em:
  echo %USERPROFILE%\Downloads\app.apk
  echo.
  pause
  exit /b 1
)
echo [OK] APK encontrado: %APK_FILE%

REM Criar diretório de descompilação
echo.
echo ========================================
echo Preparando diretório de descompilação
echo ========================================

if exist "%DECODE_DIR%" (
  echo [INFO] Limpando diretório anterior: %DECODE_DIR%
  rmdir /s /q "%DECODE_DIR%"
)

mkdir "%DECODE_DIR%"
if errorlevel 1 (
  echo [ERRO] Falha ao criar diretório: %DECODE_DIR%
  pause
  exit /b 1
)
echo [OK] Diretório criado: %DECODE_DIR%

REM Descompilar APK
echo.
echo ========================================
echo Descompilando APK com apktool
echo ========================================
echo Este processo pode levar alguns minutos...
echo.

java -jar "%USERPROFILE%\apktool\apktool.jar" d -f "%APK_FILE%" -o "%DECODE_DIR%"
if errorlevel 1 (
  echo [ERRO] Falha ao descompilar APK
  echo [INFO] Verifique se o arquivo APK é válido
  pause
  exit /b 1
)
echo [OK] APK descompilado com sucesso

REM Clonar repositório se necessário
echo.
echo ========================================
echo Preparando repositório Git
echo ========================================

if not exist "%WORKDIR%\.git" (
  echo [INFO] Clonando repositório...
  git clone "%REPO_URL%" "%WORKDIR%"
  if errorlevel 1 (
    echo [ERRO] Falha ao clonar repositório
    pause
    exit /b 1
  )
) else (
  echo [OK] Repositório já existe
)

cd /d "%WORKDIR%"
if errorlevel 1 (
  echo [ERRO] Falha ao acessar diretório: %WORKDIR%
  pause
  exit /b 1
)

REM Configurar remote
echo [INFO] Configurando remote...
git remote get-url %REMOTE_NAME% >nul 2>nul
if errorlevel 1 (
  git remote add %REMOTE_NAME% "%REPO_URL%"
)

REM Ajustar branch
git checkout %BRANCH% 2>nul
if errorlevel 1 (
  git checkout -b %BRANCH%
)
echo [OK] Git configurado

REM Copiar arquivos descompilados para o repositório
echo.
echo ========================================
echo Copiando arquivos do APK descompilado
echo ========================================

echo [INFO] Copiando de: %DECODE_DIR%
echo [INFO] Para: %WORKDIR%

REM Opção 1: Copiar tudo para a raiz (sobrescreve)
xcopy "%DECODE_DIR%\*" "%WORKDIR%\" /E /Y /I

REM Opção 2: Copiar para um subdiretório (descomente se preferir)
REM if not exist "%WORKDIR%\apk-source" mkdir "%WORKDIR%\apk-source"
REM xcopy "%DECODE_DIR%\*" "%WORKDIR%\apk-source\" /E /Y /I

if errorlevel 1 (
  echo [AVISO] Alguns arquivos podem não ter sido copiados
) else (
  echo [OK] Arquivos copiados
)

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

REM Fazer commit
echo.
echo ========================================
echo Criando commit
echo ========================================

git diff --cached --quiet
if errorlevel 0 (
  echo [INFO] Nenhuma alteração detectada
) else (
  echo [INFO] Alterações detectadas...
  
  git config user.name "Automated-APK" 2>nul
  git config user.email "automated@local" 2>nul
  
  REM Extrair nome do APK para o commit
  for %%F in ("%APK_FILE%") do set APK_NAME=%%~nF
  
  git commit -m "APK decoded: !APK_NAME! - %date% %time%"
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
  echo [INFO] Possíveis motivos:
  echo  - Você não autenticou com GitHub
  echo  - Token expirou ou foi revogado
  echo  - Você não tem permissão no repositório
  echo.
  echo [INFO] Para configurar autenticação:
  echo  1. Use Git Credential Manager
  echo  2. Ou crie um Personal Access Token:
  echo     https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token
) else (
  echo [OK] Push realizado com sucesso
)

REM Resumo final
echo.
echo ========================================
echo RESUMO DO PROCESSO
echo ========================================
echo.
echo [APK Original]
echo   Arquivo: %APK_FILE%
echo.
echo [Descompilado]
echo   Pasta: %DECODE_DIR%
echo.
echo [Repositório Git]
echo   URL: %REPO_URL%
echo   Local: %WORKDIR%
echo   Branch: %BRANCH%
echo.
echo [Próximos passos]
echo   1. Verifique os arquivos em: %WORKDIR%
echo   2. Se houver erros, corrija manualmente
echo   3. Execute este script novamente ou faça push manualmente
echo.
echo ========================================
echo.

pause
