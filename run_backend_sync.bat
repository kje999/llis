@echo off
title LLIS - PCSO Background Sync Service (Port 8081)
color 0A

echo ======================================================================
echo           Lucky Lotto Information System (LLIS)
echo             Official PCSO Background Sync Worker
echo ======================================================================
echo.
echo Starting Background Sync Microservice with Playwright, SQLite Cache,
echo REST API (Port 8081), and Automated Nightly Cron (21:30 PHT)...
echo.

cd /d "%~dp0backend_sync_service"

if not exist node_modules (
    echo [INFO] Installing required dependencies...
    call npm install
)

echo [INFO] Launching sync server on port 8081...
node server.js

pause
