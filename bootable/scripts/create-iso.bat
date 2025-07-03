@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0make-uefi.ps1"
if errorlevel 1 (
    echo Error creating ISO
    pause
    exit /b 1
)
echo ISO created successfully
pause 