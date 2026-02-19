@echo off
setlocal enabledelayedexpansion

:: =================================================================
:: CONFIGURATION & BRANDING
:: =================================================================
set "TOOL_NAME=Zhiro Quick Tools"
set "TOOL_VERSION=1.1"
set "SCRIPT_NAME=Quick Extract MP3 (320kbps)"
set "SCRIPT_VERSION=2.0"

:: 1. GENERATE TIMESTAMP
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "dt=%%I"
set "TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%%dt:~10,2%"

:: =================================================================
:: 2. PRE-FLIGHT CHECKS
:: =================================================================
where ffmpeg >nul 2>&1 || (
    echo [ERROR] FFmpeg not found in PATH.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo [ERROR] No input files provided.
    echo Please drag and drop Media files onto this script.
    pause
    exit /b 1
)

:: =================================================================
:: 3. UI SETUP
:: =================================================================
cls
echo =======================================================
echo   %TOOL_NAME% v%TOOL_VERSION%
echo   %SCRIPT_NAME% v%SCRIPT_VERSION%
echo =======================================================
echo.
echo Batch ID: %TIMESTAMP%
echo.
echo -------------------------------------------------------
echo PROCESSING FILES...
echo -------------------------------------------------------

:: =================================================================
:: 4. MAIN PROCESSING LOOP (SHIFT METHOD)
:: =================================================================
:PROCESS_LOOP
if "%~1"=="" goto :FINISHED

set "inputFile=%~f1"
set "fileName=%~nx1"
set "fileDir=%~dp1"
set "fileBase=%~n1"
set "outFile=!fileDir!!fileBase!_320kbps_%TIMESTAMP%.mp3"

echo Processing: "!fileName!"

:: -vn removes video stream if present (faster extraction)
:: -c:a libmp3lame forces MP3 codec
:: -b:a 320k forces 320kbps bitrate
ffmpeg -v error -stats -i "!inputFile!" -vn -c:a libmp3lame -b:a 320k -y "!outFile!"

if exist "!outFile!" (
    echo    - [SUCCESS] Extracted.
) else (
    echo    - [ERROR] Failed to extract.
)
echo.

:NEXT_FILE
shift
goto :PROCESS_LOOP

:: =================================================================
:: 5. FINISH
:: =================================================================
:FINISHED
echo =======================================================
echo   ALL TASKS COMPLETE.
echo =======================================================
:: Optional: Remove the pause below if you want the window to close instantly
pause
exit /b