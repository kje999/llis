@echo off
title LLIS - Stop All Services
color 0E

echo ======================================================================
echo           Lucky Lotto Information System (LLIS)
echo               Stop All Active Services
echo ======================================================================
echo.

echo Terminating active services on Port 8080 [Web] and Port 8081 [Backend]...

set found=0

REM Terminate any process listening on 8081
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8081') do (
    echo [INFO] Stopping process on Port 8081 with PID %%a
    taskkill /f /pid %%a >nul 2>&1
    set found=1
)

REM Terminate any process listening on 8080
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8080') do (
    echo [INFO] Stopping process on Port 8080 with PID %%a
    taskkill /f /pid %%a >nul 2>&1
    set found=1
)

echo.
if "%found%"=="1" (
    color 0A
    echo [SUCCESS] All LLIS services have been stopped successfully.
) else (
    echo [INFO] No active LLIS services were found running on ports 8080 or 8081.
)

echo.
ping 127.0.0.1 -n 3 >nul 2>&1
exit

