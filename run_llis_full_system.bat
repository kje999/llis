@echo off
title LLIS - Complete System Launcher (Flutter Web + Backend Sync)
color 0B

echo ======================================================================
echo           Lucky Lotto Information System (LLIS)
echo                  Full Stack Quick Launcher
echo ======================================================================
echo.

REM 1. Launch Backend Sync Service in a dedicated window
echo [1/2] Starting PCSO Background Sync Service (Port 8081)...
start "LLIS Backend Sync Service" cmd /k "cd /d "%~dp0backend_sync_service" && node server.js"

REM Wait 2 seconds for backend to start up
timeout /t 2 /nobreak > nul

REM 2. Launch Web Server for Flutter Web in a dedicated window
echo [2/2] Starting Flutter Web Application (Port 8080)...
start "LLIS Flutter Web Server" cmd /k "cd /d "%~dp0" && npx serve -l 8080 build/web"

echo.
echo ======================================================================
echo  All services started successfully!
echo   - Web Application: http://localhost:8080
echo   - Sync REST API:   http://localhost:8081/api/pcso-results
echo ======================================================================
echo.
echo Opening browser to http://localhost:8080 ...
timeout /t 2 /nobreak > nul
start http://localhost:8080

exit
