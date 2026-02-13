@echo off
REM Jira Sync Launcher for Windows
REM This batch file launches the PowerShell setup script

setlocal enabledelayedexpansion

REM Check if PowerShell is available
where pwsh >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: PowerShell Core (pwsh) not found
    echo Please install PowerShell Core from https://github.com/PowerShell/PowerShell
    pause
    exit /b 1
)

REM Get the directory where this script is located
set SCRIPT_DIR=%~dp0

REM Change to workspace root (parent of scripts directory)
cd /d "%SCRIPT_DIR%.."

REM Run the setup script
pwsh -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%setup-jira-sync.ps1"

pause
