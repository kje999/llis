@echo off
title LLIS - Complete System Launcher (Flutter Web + Central Backend)
color 0B

echo ======================================================================
echo           Lucky Lotto Information System (LLIS)
echo                  Full Stack Quick Launcher
echo ======================================================================
echo.

REM 1. Verify Node.js
where node >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo [ERROR] Node.js is not found in your system PATH!
    echo Please install Node.js from https://nodejs.org/ to run LLIS services.
    echo.
    pause
    exit /b 1
)

REM 2. Free up Ports 8080 and 8081 if in use
echo [INFO] Releasing existing processes on Ports 8080 and 8081...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8081') do taskkill /f /pid %%a >nul 2>&1
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8080') do taskkill /f /pid %%a >nul 2>&1

REM 3. Ensure Flutter Web build exists
if not exist "%~dp0build\web\index.html" (
    echo [WARN] Web release build not found at build\web!
    echo [INFO] Compiling Flutter Web application in release mode...
    call flutter build web --release --pwa-strategy=none
    if %errorlevel% neq 0 (
        color 0C
        echo [ERROR] Flutter Web build failed. Please check Flutter setup.
        pause
        exit /b 1
    )
)

echo.
REM 4. Launch Backend Sync Service in a dedicated window
echo [1/2] Launching Central Backend Sync Service and SQLite on Port 8081...
start "LLIS Central Backend Service (Port 8081)" cmd /k "cd /d "%~dp0backend_sync_service" && node server.js"

REM 5. Wait 3 seconds for backend service to bind
echo [INFO] Waiting for backend services to initialize...
ping 127.0.0.1 -n 4 >nul 2>&1

REM 6. Launch Web Server for Flutter Web in a dedicated window
echo [2/2] Launching Flutter Web Server on Port 8080...
start "LLIS Flutter Web Server (Port 8080)" cmd /k "cd /d "%~dp0" && npx --yes serve -s build/web -l 8080"

REM 7. Give web server 2 seconds to bind port
ping 127.0.0.1 -n 3 >nul 2>&1

echo.
echo ======================================================================
echo           ALL LLIS SERVICES HAVE BEEN STARTED SUCCESSFULLY!
echo ======================================================================
echo   - Web Application UI    : http://localhost:8080
echo   - PCSO Draw REST API    : http://localhost:8081/api/pcso-results
echo   - User Accounts API     : http://localhost:8081/api/users
echo   - Lucky Picks API       : http://localhost:8081/api/picks
echo   - Central SQLite Cache  : backend_sync_service\llis_central_sync.db
echo   - Stop All Services     : Run stop_all_services.bat
echo ======================================================================
echo.
echo Opening browser to http://localhost:8080 ...
start http://localhost:8080

echo.
echo Both background service windows are now running.
echo Keep this window open or press any key to close this launcher.
echo (Closing this window will NOT stop the backend or web server).
echo.
pause
