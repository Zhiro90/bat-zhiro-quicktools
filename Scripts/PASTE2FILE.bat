@echo off
setlocal enabledelayedexpansion

:: =================================================================
:: CONFIGURATION & BRANDING
:: =================================================================
set "TOOL_NAME=Zhiro Quick Tools"
set "TOOL_VERSION=1.0"
set "SCRIPT_NAME=Paste to Text File"
set "SCRIPT_VERSION=2.0"

:: 1. GENERATE TIMESTAMP (With Seconds to prevent overwriting rapid pastes)
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "dt=%%I"
set "TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%%dt:~10,2%%dt:~12,2%"

:: =================================================================
:: 2. TARGET DIRECTORY
:: =================================================================
:: Si haces clic derecho en el fondo de una carpeta, %1 toma esa ruta
set "TARGET_DIR=%~1"
if "!TARGET_DIR!"=="" set "TARGET_DIR=%CD%"

:: Asegurar que la ruta termine en barra diagonal
if not "!TARGET_DIR:~-1!"=="\" set "TARGET_DIR=!TARGET_DIR!\"

set "OUT_FILE=!TARGET_DIR!Clipboard_!TIMESTAMP!.txt"

:: =================================================================
:: 3. UI SETUP
:: =================================================================
cls
echo =======================================================
echo   %TOOL_NAME% v%TOOL_VERSION%
echo   %SCRIPT_NAME% v%SCRIPT_VERSION%
echo =======================================================
echo.
echo Target: "!TARGET_DIR!"
echo.
echo [INFO] Accessing clipboard... (Starting PowerShell)

:: =================================================================
:: 4. EXECUTION (UTF-8 No BOM)
:: =================================================================
:: -Raw: Keeps multi-line formatting intact
:: UTF8Encoding::new($false): Forces UTF-8 Without BOM
set "PS_CMD=$txt = Get-Clipboard -Raw; if ($null -ne $txt -and $txt -ne '') { [System.IO.File]::WriteAllText('!OUT_FILE!', $txt, [System.Text.UTF8Encoding]::new($false)) } else { exit 1 }"

powershell -NoProfile -Command "!PS_CMD!"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Clipboard is empty or contains non-text data (e.g., an image).
    timeout /t 3 >nul
    exit /b 1
)

echo.
echo [SUCCESS] Saved to:
echo "Clipboard_!TIMESTAMP!.txt"
timeout /t 2 >nul
exit /b