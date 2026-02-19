@echo off
setlocal enabledelayedexpansion

:: =================================================================
:: CONFIGURATION & BRANDING
:: =================================================================
set "TOOL_NAME=Zhiro Quick Tools"
set "TOOL_VERSION=1.0"
set "SCRIPT_NAME=Suite Updater"
set "SCRIPT_VERSION=1.1"

:: 1. GENERATE TIMESTAMP
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "dt=%%I"
set "TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%%dt:~10,2%"

:: =================================================================
:: 2. GITHUB REPO DETAILS
:: =================================================================
:: Define where to look for updates
set "REPO_RAW_URL=https://raw.githubusercontent.com/Zhiro90/bat-zhiro-quicktools/main/version.txt"
set "REPO_ZIP_URL=https://github.com/Zhiro90/bat-zhiro-quicktools/archive/refs/heads/main.zip"
set "EXTRACTED_FOLDER_NAME=bat-zhiro-quicktools-main"

:: =================================================================
:: 3. PRE-FLIGHT CHECKS & PATHS
:: =================================================================
set "CURRENT_DIR=%~dp0"
set "LOCAL_VERSION_FILE=%CURRENT_DIR%version.txt"
set "TEMP_DIR=%TEMP%\ZhiroUpdate_%TIMESTAMP%"

where curl >nul 2>&1 || (
    echo [ERROR] curl is required but not found in Windows.
    pause
    exit /b 1
)
where 7z >nul 2>&1 || (
    echo [ERROR] 7-Zip is required for extraction but not found in PATH.
    pause
    exit /b 1
)

:: =================================================================
:: 4. UI SETUP
:: =================================================================
cls
echo =======================================================
echo   %TOOL_NAME% v%TOOL_VERSION%
echo   %SCRIPT_NAME% v%SCRIPT_VERSION%
echo =======================================================
echo.
echo [INFO] Checking for updates...

:: Read Local Version
if exist "%LOCAL_VERSION_FILE%" (
    set /p LOCAL_VER=<"%LOCAL_VERSION_FILE%"
) else (
    set "LOCAL_VER=0.0"
    echo [WARN] Local version.txt not found. Assuming version 0.0.
)

:: Download Remote Version
curl -s -f -o "%TEMP%\zhiro_remote_ver.txt" "%REPO_RAW_URL%"
if %errorlevel% neq 0 (
    echo [ERROR] Could not connect to GitHub. Check your internet connection.
    pause
    exit /b 1
)

set /p REMOTE_VER=<"%TEMP%\zhiro_remote_ver.txt"
del "%TEMP%\zhiro_remote_ver.txt"

echo Local Version:  !LOCAL_VER!
echo Remote Version: !REMOTE_VER!
echo.

if "!LOCAL_VER!"=="!REMOTE_VER!" (
    echo [INFO] You are already using the latest version.
    pause
    exit /b 0
)

:: =================================================================
:: 5. DOWNLOAD & EXTRACT
:: =================================================================
echo [INFO] New version found! Downloading update...
mkdir "%TEMP_DIR%"
curl -L -o "%TEMP_DIR%\update.zip" "%REPO_ZIP_URL%"

if not exist "%TEMP_DIR%\update.zip" (
    echo [ERROR] Download failed.
    pause
    exit /b 1
)

echo [INFO] Extracting files...
7z x "%TEMP_DIR%\update.zip" -o"%TEMP_DIR%" -y >nul

if not exist "%TEMP_DIR%\%EXTRACTED_FOLDER_NAME%" (
    echo [ERROR] Extraction failed or folder structure changed.
    pause
    exit /b 1
)

:: =================================================================
:: 6. THE SWAP (KAMIKAZE SCRIPT)
:: =================================================================
echo [INFO] Preparing to install updates...

set "SWAP_SCRIPT=%TEMP%\zhiro_swap.bat"

:: Create the temporary script that will overwrite the current files
echo @echo off > "%SWAP_SCRIPT%"
echo title Installing Update... >> "%SWAP_SCRIPT%"
echo echo Please wait, applying update... >> "%SWAP_SCRIPT%"
:: Wait 2 seconds to ensure the main updater has closed completely
echo timeout /t 2 /nobreak ^>nul >> "%SWAP_SCRIPT%"
:: Copy all files from the extracted folder to the current installation folder, overwriting (/Y)
echo xcopy /Y /S /I "%TEMP_DIR%\%EXTRACTED_FOLDER_NAME%\*" "%CURRENT_DIR%" ^>nul >> "%SWAP_SCRIPT%"
:: Clean up temp folder
echo rd /s /q "%TEMP_DIR%" >> "%SWAP_SCRIPT%"
echo cls >> "%SWAP_SCRIPT%"
echo echo ======================================================= >> "%SWAP_SCRIPT%"
echo echo   UPDATE COMPLETE! >> "%SWAP_SCRIPT%"
echo echo   Welcome to version %REMOTE_VER% >> "%SWAP_SCRIPT%"
echo echo ======================================================= >> "%SWAP_SCRIPT%"
echo pause >> "%SWAP_SCRIPT%"
:: Self-destruct the swap script
echo del "%%~f0" >> "%SWAP_SCRIPT%"

:: Execute the swap script in a new window and exit this one immediately
start "" "%SWAP_SCRIPT%"
exit /b