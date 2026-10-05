@echo off
title LLIS - Central Backend Services & Sync Engine (Port 8081)
color 0A

echo ======================================================================
echo           Lucky Lotto Information System (LLIS)
echo        Central Backend Services, SQLite & PCSO Sync Engine
echo ======================================================================
echo.

REM 1. Verify Node.js is installed
where node >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo [ERROR] Node.js is not found in your system PATH!
    echo Please install Node.js from https://nodejs.org/ to run backend services.
    echo.
    pause
    exit /b 1
)

REM 2. Free up Port 8081 if occupied
echo [INFO] Checking Port 8081 availability...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8081') do taskkill /f /pid %%a >nul 2>&1

REM 3. Navigate to backend directory
cd /d "%~dp0backend_sync_service"

REM 4. Check dependencies
if not exist node_modules (
    echo [INFO] Installing required backend dependencies...
    call npm install
    if %errorlevel% neq 0 (
        color 0C
        echo [ERROR] Failed to install backend npm dependencies.
        pause
        exit /b 1
    )
)

echo.
echo ======================================================================
echo  ACTIVE BACKEND SERVICES & SUBSYSTEMS:
echo  --------------------------------------------------------------------
echo  [1] Central SQLite Database Engine [llis_central_sync.db]
echo  [2] Official PCSO Scraper & Sync Engine [Playwright / Fallback]
echo  [3] Draw Results REST API Gateway    : http://localhost:8081/api/pcso-results
echo  [4] User Accounts Sync API           : http://localhost:8081/api/users
echo  [5] Lucky Picks Sync API             : http://localhost:8081/api/picks
echo  [6] Real-time SSE Live Log Stream    : http://localhost:8081/api/sync/live-logs
echo  [7] Service Health Status             : http://localhost:8081/api/health
echo  [8] Automated Nightly Cron Job        : Daily at 21:30 [9:30 PM PHT]
echo ======================================================================
echo.
echo [INFO] Launching backend server on port 8081...
echo Press Ctrl+C at any time to stop the backend service.
echo.

node server.js

if %errorlevel% neq 0 (
    echo.
    color 0C
    echo [WARN] Backend server exited with error code %errorlevel%.
)

pause

