@echo off
setlocal EnableDelayedExpansion

:: ============================================================
:: MINTRO — Windows Setup & Run Script
:: setup.bat
::
:: Run from the mintro\ project root:
::   setup.bat
:: ============================================================

title Mintro Setup
chcp 65001 >nul 2>&1

echo.
echo  ============================================================
echo   MINTRO  --  Setup ^& Launch Script for Windows
echo  ============================================================
echo.

:: ── Locate script directory (project root) ────────────────────
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

set "API_DIR=%ROOT%\services\api"
set "FLUTTER_DIR=%ROOT%\apps\flutter_app"

:: ============================================================
:: STEP 1 — Prerequisite checks
:: ============================================================
echo [1/7] Checking prerequisites...
echo.

:: Node.js
where node >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo  [ERROR] Node.js not found.
    echo.
    echo  Install Node.js 20+ from: https://nodejs.org
    echo  Then restart this script.
    pause
    exit /b 1
)
node --version > "%TEMP%\mintro_node_ver.txt" 2>&1
set /p NODE_VER= < "%TEMP%\mintro_node_ver.txt"
del "%TEMP%\mintro_node_ver.txt" >nul 2>&1
echo  [OK] Node.js %NODE_VER%

:: npm
where npm >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo  [ERROR] npm not found. Reinstall Node.js from https://nodejs.org
    pause
    exit /b 1
)
npm --version > "%TEMP%\mintro_npm_ver.txt" 2>&1
set /p NPM_VER= < "%TEMP%\mintro_npm_ver.txt"
del "%TEMP%\mintro_npm_ver.txt" >nul 2>&1
echo  [OK] npm %NPM_VER%

:: Flutter
where flutter >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo  [ERROR] Flutter not found in PATH.
    echo.
    echo  Install Flutter from: https://flutter.dev/docs/get-started/install/windows
    echo  Add flutter\bin to your system PATH, then restart this script.
    pause
    exit /b 1
)
echo  [OK] Flutter found

:: Git (optional warning only)
where git >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo  [WARN] Git not found. Install from https://git-scm.com if you need it.
) else (
    git --version > "%TEMP%\mintro_git_ver.txt" 2>&1
    set /p GIT_VER= < "%TEMP%\mintro_git_ver.txt"
    del "%TEMP%\mintro_git_ver.txt" >nul 2>&1
    echo  [OK] %GIT_VER%
)

echo.

:: ============================================================
:: STEP 2 — Install Node API dependencies
:: ============================================================
echo [2/7] Installing Node API dependencies...
echo       (may take a minute on first run)
echo.

if not exist "%API_DIR%\package.json" (
    echo  [ERROR] Cannot find %API_DIR%\package.json
    echo          Make sure you are running setup.bat from the mintro\ root folder.
    pause
    exit /b 1
)

cd /d "%API_DIR%"
call npm install
if %ERRORLEVEL% neq 0 (
    echo.
    echo  [ERROR] npm install failed. See error above.
    pause
    exit /b 1
)
echo.
echo  [OK] Node API dependencies installed.
echo.

:: ============================================================
:: STEP 3 — Install Flutter dependencies
:: ============================================================
echo [3/7] Installing Flutter dependencies...
echo.

if not exist "%FLUTTER_DIR%\pubspec.yaml" (
    echo  [ERROR] Cannot find %FLUTTER_DIR%\pubspec.yaml
    pause
    exit /b 1
)

cd /d "%FLUTTER_DIR%"
call flutter pub get
if %ERRORLEVEL% neq 0 (
    echo.
    echo  [ERROR] flutter pub get failed. See error above.
    pause
    exit /b 1
)
echo.
echo  [OK] Flutter dependencies installed.
echo.

:: ============================================================
:: STEP 4 — Create .env from .env.example if missing
:: ============================================================
echo [4/7] Checking environment configuration...
echo.

if not exist "%API_DIR%\.env" (
    if exist "%API_DIR%\.env.example" (
        copy "%API_DIR%\.env.example" "%API_DIR%\.env" >nul
        echo  Created services\api\.env from .env.example
    ) else (
        echo  [ERROR] .env.example not found at %API_DIR%\.env.example
        pause
        exit /b 1
    )
) else (
    echo  services\api\.env already exists -- skipping copy.
)
echo.

:: ============================================================
:: STEP 5 — Prompt for Supabase credentials
:: ============================================================
echo [5/7] Supabase configuration
echo  ------------------------------------------------------------
echo.
echo  You need three values from your Supabase dashboard:
echo    Project Settings ^> API ^> Project URL
echo    Project Settings ^> API ^> service_role key  (secret!)
echo    Project Settings ^> API ^> JWT Settings ^> JWT Secret
echo.
echo  Press ENTER to keep any value that is already set.
echo.

:: Read existing values from .env
set "CURRENT_URL="
set "CURRENT_SRK="
set "CURRENT_JWT="

for /f "usebackq tokens=1,* delims==" %%a in ("%API_DIR%\.env") do (
    if /i "%%a"=="SUPABASE_URL"              set "CURRENT_URL=%%b"
    if /i "%%a"=="SUPABASE_SERVICE_ROLE_KEY" set "CURRENT_SRK=%%b"
    if /i "%%a"=="SUPABASE_JWT_SECRET"       set "CURRENT_JWT=%%b"
)

:: Strip placeholder defaults so we prompt for real values
if "!CURRENT_URL!"=="https://your-project-ref.supabase.co" set "CURRENT_URL="
if "!CURRENT_SRK!"=="your-service-role-key"                set "CURRENT_SRK="
if "!CURRENT_JWT!"=="your-jwt-secret"                      set "CURRENT_JWT="

:: Supabase URL
if defined CURRENT_URL (
    echo  Supabase URL already set: !CURRENT_URL!
    set /p "NEW_URL=  New URL (ENTER to keep): "
) else (
    set /p "NEW_URL=  Supabase Project URL: "
)
if not "!NEW_URL!"=="" set "CURRENT_URL=!NEW_URL!"

:: Service Role Key
if defined CURRENT_SRK (
    echo  Service role key already set (hidden).
    set /p "NEW_SRK=  New key (ENTER to keep): "
) else (
    set /p "NEW_SRK=  Supabase service_role key: "
)
if not "!NEW_SRK!"=="" set "CURRENT_SRK=!NEW_SRK!"

:: JWT Secret
if defined CURRENT_JWT (
    echo  JWT secret already set (hidden).
    set /p "NEW_JWT=  New secret (ENTER to keep): "
) else (
    set /p "NEW_JWT=  Supabase JWT Secret: "
)
if not "!NEW_JWT!"=="" set "CURRENT_JWT=!NEW_JWT!"

:: Write values back using PowerShell (handles special chars in keys safely)
echo.
echo  Writing credentials to services\api\.env ...

powershell -NoProfile -Command ^
 "$f = '%API_DIR%\.env';" ^
 "$c = Get-Content $f -Raw;" ^
 "$c = $c -replace '(?m)^SUPABASE_URL=.*', ('SUPABASE_URL=!CURRENT_URL!');" ^
 "$c = $c -replace '(?m)^SUPABASE_SERVICE_ROLE_KEY=.*', ('SUPABASE_SERVICE_ROLE_KEY=!CURRENT_SRK!');" ^
 "$c = $c -replace '(?m)^SUPABASE_JWT_SECRET=.*', ('SUPABASE_JWT_SECRET=!CURRENT_JWT!');" ^
 "Set-Content $f $c -NoNewline -Encoding UTF8"

if %ERRORLEVEL% neq 0 (
    echo  [WARN] Could not auto-write .env -- edit services\api\.env manually.
) else (
    echo  [OK] .env updated.
)
echo.

:: ============================================================
:: STEP 6 — Flutter dart-define values
:: ============================================================
echo [6/7] Flutter configuration
echo  ------------------------------------------------------------
echo.
echo  The Flutter app needs your Supabase ANON key.
echo  (Different from the service_role key -- the anon key is safe for clients.)
echo  Find it at: Project Settings ^> API ^> anon public
echo.

set "ANON_KEY="
set /p "ANON_KEY=  Supabase anon public key: "

if "!ANON_KEY!"=="" (
    echo  [WARN] Anon key not provided. App will launch but auth will fail.
    set "ANON_KEY=YOUR_ANON_KEY_HERE"
)

set "API_BASE=http://localhost:3000/api/v1"
echo.
echo  API base URL -- press ENTER for default: http://localhost:3000/api/v1
echo    Android emulator: use http://10.0.2.2:3000/api/v1
echo    Physical device:  use your PC LAN IP e.g. http://192.168.1.X:3000/api/v1
echo.
set /p "API_BASE_INPUT=  API base URL (ENTER for default): "
if not "!API_BASE_INPUT!"=="" set "API_BASE=!API_BASE_INPUT!"
echo.

:: ============================================================
:: STEP 7 — Launch
:: ============================================================
echo [7/7] Launching Mintro...
echo  ------------------------------------------------------------
echo.

:: Check for connected Flutter devices
echo  Checking for Flutter devices / emulators...
cd /d "%FLUTTER_DIR%"

flutter devices > "%TEMP%\mintro_devices.txt" 2>&1
set "LAUNCH_FLUTTER=0"
findstr /i "android\|ios\|chrome\|windows\|emulator" "%TEMP%\mintro_devices.txt" >nul 2>&1
if %ERRORLEVEL% equ 0 set "LAUNCH_FLUTTER=1"
del "%TEMP%\mintro_devices.txt" >nul 2>&1

if "!LAUNCH_FLUTTER!"=="0" (
    echo  [WARN] No Flutter devices found.
    echo.
    echo  To connect one:
    echo    Android emulator : Open Android Studio ^> Device Manager ^> click Play
    echo    Physical Android : Enable USB Debugging, connect via USB
    echo.
    echo  The Node API will still start below. Re-run setup.bat
    echo  once a device or emulator is ready.
    echo.
)

:: Start Node API in a new window
echo  Starting Node API in a new window (port 3000)...
cd /d "%API_DIR%"
start "Mintro API" cmd /k "title Mintro API && echo Starting Mintro API... && npm run dev"

:: Give the API a moment to initialise before Flutter hits it
echo  Waiting 4 seconds for API to initialise...
timeout /t 4 /nobreak >nul

if "!LAUNCH_FLUTTER!"=="1" (
    echo  Starting Flutter app...
    echo.
    cd /d "%FLUTTER_DIR%"
    call flutter run ^
        "--dart-define=SUPABASE_URL=!CURRENT_URL!" ^
        "--dart-define=SUPABASE_ANON_KEY=!ANON_KEY!" ^
        "--dart-define=API_BASE_URL=!API_BASE!"
) else (
    echo  Flutter launch skipped (no device found).
    echo.
    echo  When a device is ready, run this in a new terminal:
    echo.
    echo    cd apps\flutter_app
    echo    flutter run ^
    echo      --dart-define=SUPABASE_URL=!CURRENT_URL! ^
    echo      --dart-define=SUPABASE_ANON_KEY=!ANON_KEY! ^
    echo      --dart-define=API_BASE_URL=!API_BASE!
    echo.
)

echo.
echo  ============================================================
echo   Mintro is running!
echo.
echo   API server  : http://localhost:3000  (in the other window)
echo   Health check: http://localhost:3000/health
echo.
echo   Demo account (run scripts\seed_demo_user.mjs first):
echo     Email   : demo@mintro.app
echo     Password: Mintro2024!
echo.
echo   To stop the API: close the "Mintro API" window.
echo   To re-run later: just run setup.bat again.
echo   (Dependencies are already installed -- it will be fast.)
echo  ============================================================
echo.

endlocal
pause
