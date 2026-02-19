@echo off
setlocal enabledelayedexpansion

:: =================================================================
:: CONFIGURATION & BRANDING
:: =================================================================
set "TOOL_NAME=Zhiro Quick Tools"
set "TOOL_VERSION=1.0"
set "SCRIPT_NAME=Quick Convert to x264 (MP4)"
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
    echo Please drag and drop Video files onto this script.
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
set "outFile=!fileDir!!fileBase!_x264_%TIMESTAMP%.mp4"

echo Processing: "!fileName!"

:: -c:v libx264   : Best compatibility video codec
:: -crf 23        : Excellent balance of quality and size
:: -preset medium : Balance between speed and file size
:: -c:a aac       : Standard MP4 audio codec
:: -pix_fmt yuv420p: Pixel format for maximum device compatibility
ffmpeg -v error -stats -i "!inputFile!" -c:v libx264 -crf 23 -preset medium -c:a aac -pix_fmt yuv420p -y "!outFile!"

if exist "!outFile!" (
    echo    - [SUCCESS] Converted.
) else (
    echo    - [ERROR] Failed to convert.
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
pause
exit /b