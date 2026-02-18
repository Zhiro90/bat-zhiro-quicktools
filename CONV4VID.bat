@echo off
setlocal enabledelayedexpansion

:: =================================================================
:: CONFIGURATION & BRANDING
:: =================================================================
set "TOOL_NAME=Zhiro Quick Tools"
set "TOOL_VERSION=1.0"
set "SCRIPT_NAME=Multi-Format Video Converter"
set "SCRIPT_VERSION=2.0"

:: 1. GENERATE TIMESTAMP (YYYY-MM-DD_HHMM)
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "dt=%%I"
set "TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%%dt:~10,2%"

:: =================================================================
:: 2. PRE-FLIGHT CHECKS
:: =================================================================
if "%~1"=="" (
    echo [ERROR] No input file provided.
    echo Please drag and drop a video file onto this script.
    pause
    exit /b
)

:: Environment Check (Path Agnostic)
where ffmpeg >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] FFmpeg not found. Please install it or add it to your PATH.
    pause
    exit /b
)

:: =================================================================
:: 3. AGILE MENU (Logic Preserved)
:: =================================================================
cls
echo =======================================================
echo   %TOOL_NAME% v%TOOL_VERSION%
echo   %SCRIPT_NAME% v%SCRIPT_VERSION%
echo =======================================================
echo.
echo Input File: "%~nx1"
echo Batch ID:   %TIMESTAMP%
echo.
echo SELECT OPTION:
echo ----------------------------------------------------
echo [Enter] (or 0) = MP4, H.264, Original Res (Default)
echo 1              = MP4, 1080p
echo 2              = MP4, 720p
echo 3              = MP4, 480p
echo 4              = MP4, 320p
echo 5              = MP4, 240p
echo 6              = MP4, 144p
echo [number] (e.g. 100) = MP4, Custom Height
echo ----------------------------------------------------
echo w                = WebM (VP9), Original Res
echo w[number] (e.g. w720) = WebM (VP9), Custom Height
echo ----------------------------------------------------
echo.

set "CHOICE="
set /p "CHOICE=Option: "

:: DEFAULT: Treat empty input as 0
if "%CHOICE%"=="" set "CHOICE=0"

:: --- LOGIC BRANCHING ---
:: If input starts with 'w' (case insensitive), go to WebM flow
if /I "%CHOICE:~0,1%"=="w" goto :FLOW_WEBM

:: =================================================================
:: FLOW A: MP4 MODE (DEFAULT)
:: =================================================================
:FLOW_MP4
set "OUTPUT_EXT=.mp4"
set "CODECS=-c:v libx264 -crf 23 -preset medium -c:a aac -pix_fmt yuv420p"
set "TARGET_H_NUM=%CHOICE%"

:: Preset Logic
if "%TARGET_H_NUM%"=="0" (
    set "SUFFIX=_h264"
    set "SCALE_FILTER="
) else if "%TARGET_H_NUM%"=="1" (
    set "SUFFIX=_1080p"
    set "SCALE_FILTER=-vf scale=-2:min(ih\,1080)"
) else if "%TARGET_H_NUM%"=="2" (
    set "SUFFIX=_720p"
    set "SCALE_FILTER=-vf scale=-2:min(ih\,720)"
) else if "%TARGET_H_NUM%"=="3" (
    set "SUFFIX=_480p"
    set "SCALE_FILTER=-vf scale=-2:min(ih\,480)"
) else if "%TARGET_H_NUM%"=="4" (
    set "SUFFIX=_320p"
    set "SCALE_FILTER=-vf scale=-2:min(ih\,320)"
) else if "%TARGET_H_NUM%"=="5" (
    set "SUFFIX=_240p"
    set "SCALE_FILTER=-vf scale=-2:min(ih\,240)"
) else if "%TARGET_H_NUM%"=="6" (
    set "SUFFIX=_144p"
    set "SCALE_FILTER=-vf scale=-2:min(ih\,144)"
) else (
    :: Case: Custom Number (e.g., 500)
    set "SUFFIX=_%TARGET_H_NUM%p"
    set "SCALE_FILTER=-vf scale=-2:min(ih\,%TARGET_H_NUM%)"
    echo.
    echo [Custom MP4 Height]: %TARGET_H_NUM%p
)

goto :EXECUTE_UNIFIED

:: =================================================================
:: FLOW B: WEBM MODE
:: =================================================================
:FLOW_WEBM
echo.
echo [WebM Mode (VP9/Opus) Selected]
set "OUTPUT_EXT=.webm"
set "CODECS=-c:v libvpx-vp9 -crf 30 -b:v 0 -c:a libopus"

:: Extract number AFTER 'w'
set "TARGET_H_NUM=%CHOICE:~1%"

if "%TARGET_H_NUM%"=="" (
    :: Case: Just 'w' (Original)
    set "SUFFIX=_webm"
    set "SCALE_FILTER="
) else (
    :: Case: 'w[number]' (Resize)
    set "SUFFIX=_%TARGET_H_NUM%p_webm"
    set "SCALE_FILTER=-vf scale=-2:min(ih\,%TARGET_H_NUM%)"
    echo [Custom WebM Height]: %TARGET_H_NUM%p
)

:: Fall through to execution...

:: =================================================================
:: 4. UNIFIED EXECUTION
:: =================================================================
:EXECUTE_UNIFIED
:: Construct Output Name: Name_Suffix_Timestamp.ext
set "OUTPUT_FILE=%~dp1%~n1%SUFFIX%_%TIMESTAMP%%OUTPUT_EXT%"

echo.
echo -------------------------------------------------------
echo PROCESSING...
echo Format: %OUTPUT_EXT%
echo Output: "%~n1%SUFFIX%_%TIMESTAMP%%OUTPUT_EXT%"
echo -------------------------------------------------------
echo.

:: Execute FFmpeg
ffmpeg -v error -stats -i "%~1" %SCALE_FILTER% %CODECS% "%OUTPUT_FILE%"

echo.
echo =======================================================
if exist "%OUTPUT_FILE%" (
    echo   SUCCESS.
) else (
    echo   ERROR: Process failed.
)
echo =======================================================
pause
endlocal