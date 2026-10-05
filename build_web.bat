@echo off
title LLIS - Rebuild Flutter Web
color 0B

echo ======================================================================
echo           Lucky Lotto Information System (LLIS)
echo               Rebuild Flutter Web Application
echo ======================================================================
echo.

cd /d "%~dp0"

echo [INFO] Running flutter pub get...
call flutter pub get

echo.
echo [INFO] Compiling Flutter Web in Release Mode...
call flutter build web --release --pwa-strategy=none

if %errorlevel% neq 0 (
    color 0C
    echo [ERROR] Flutter Web compilation failed.
) else (
    color 0A
    echo.
    echo [SUCCESS] Flutter Web build completed successfully!
    echo Output directory: %~dp0build\web
)

echo.
pause

