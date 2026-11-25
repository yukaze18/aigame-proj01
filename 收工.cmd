@echo off
rem ============================================================
rem  launcher for Tools\checkin.ps1  --  just double-click this file
rem
rem  Why this file contains only ASCII text:
rem    .cmd files carry no encoding marker, so Chinese text here
rem    would be garbled depending on the console code page.
rem    All Chinese output comes from Tools\checkin.ps1 instead,
rem    which is stored as UTF-8 with BOM and always renders right.
rem ============================================================

title AIGame_Proj01 - checkin
cd /d "%~dp0"

if not exist "%~dp0Tools\checkin.ps1" (
    echo.
    echo [ERROR] Tools\checkin.ps1 not found.
    echo         Keep this launcher in the repository root.
    echo.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Tools\checkin.ps1" %*

if errorlevel 1 (
    echo.
    echo ############################################################
    echo #  FAILED  -  scroll up and read the red lines first       #
    echo #  Do NOT disconnect until you understand what happened.   #
    echo ############################################################
) else (
    echo.
    echo ############################################################
    echo #  OK  -  committed, pushed and verified.                  #
    echo #  Safe to disconnect the remote desktop.                  #
    echo ############################################################
)

echo.
pause
