@echo off
setlocal enabledelayedexpansion

:: =================================================================
:: CONFIGURATION & BRANDING
:: =================================================================
set "TOOL_NAME=Zhiro Quick Tools"
set "TOOL_VERSION=1.0"
set "SCRIPT_NAME=Smart Audio Converter"
set "SCRIPT_VERSION=2.1"

:: 1. GENERATE TIMESTAMP
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "dt=%%I"
set "TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%%dt:~10,2%"

:: =================================================================
:: 2. PRE-FLIGHT CHECKS
:: =================================================================
if "%~1"=="" (
    echo [ERROR] No input files provided.
    echo Please drag and drop audio files onto this script.
    pause
    exit /b 1
)

:: Check for FFmpeg
where ffmpeg >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] FFmpeg not found. Please install it or add it to your PATH.
    pause
    exit /b 1
)

:: Check if input source is WAV (based on first file)
set "IS_WAV=0"
if /I "%~x1"==".wav" set "IS_WAV=1"

:: =================================================================
:: 3. UI & MENU
:: =================================================================
cls
echo =======================================================
echo   %TOOL_NAME% v%TOOL_VERSION%
echo   %SCRIPT_NAME% v%SCRIPT_VERSION%
echo =======================================================
echo.
echo Batch ID: %TIMESTAMP%
echo Input:    "%~nx1" (and others if selected)
echo.
echo SELECT FORMAT:
echo.
echo   [1] MP3  (Universal, Lossy)
echo   [2] OPUS (High Efficiency, Lossy) [Default]
if "%IS_WAV%"=="1" echo   [3] FLAC (Lossless - WAV Only)
echo.

set "format="
set /p format="Choose format: "
if "!format!"=="" set format=2

:: VALIDATION: Prevent selecting FLAC if not WAV
if "!format!"=="3" (
    if "!IS_WAV!"=="0" (
        echo.
        echo [ERROR] FLAC conversion is only available for WAV sources.
        echo Defaulting to OPUS.
        set format=2
        pause
    )
)

echo.
echo -------------------------------------------------------

:: ROUTING LOGIC (The Fix)
if "!format!"=="1" goto :SETUP_MP3
if "!format!"=="3" goto :SETUP_FLAC
:: Default to OPUS for any other input
goto :SETUP_OPUS


:: =================================================================
:: 4. QUALITY CONFIGURATION (ISOLATED BLOCKS)
:: =================================================================

:SETUP_MP3
    echo MP3 QUALITY SELECTION:
    echo   [1] 160 kbps (Medium)
    echo   [2] 192 kbps (Standard)
    echo   [3] 256 kbps (High)
    echo   [4] 320 kbps (Ultra)
    echo.
    set /p q_choice="Select Quality [1-4]: "
    
    set "bitrate=256"
    if "!q_choice!"=="1" set bitrate=160
    if "!q_choice!"=="2" set bitrate=192
    if "!q_choice!"=="3" set bitrate=256
    if "!q_choice!"=="4" set bitrate=320
    
    set "EXTENSION=mp3"
    set "ARGS=-vn -c:a libmp3lame -b:a !bitrate!k"
    echo Configured: MP3 !bitrate!kbps
    goto :START_PROCESSING

:SETUP_OPUS
    echo OPUS CONFIGURATION:
    set "opus_vbr=96"
    set /p opus_vbr="Enter VBR Bitrate (64-256) [Default 96]: "
    if "!opus_vbr!"=="" set opus_vbr=96
    
    set "EXTENSION=opus"
    set "ARGS=-vn -c:a libopus -b:a !opus_vbr!k"
    echo Configured: OPUS !opus_vbr!kbps
    goto :START_PROCESSING

:SETUP_FLAC
    echo FLAC CONFIGURATION:
    echo Converting to Lossless FLAC...
    
    set "EXTENSION=flac"
    :: Using FFmpeg for FLAC
    set "ARGS=-c:a flac -compression_level 12"
    goto :START_PROCESSING


:: =================================================================
:: 5. PROCESSING LOOP
:: =================================================================
:START_PROCESSING
echo.
echo -------------------------------------------------------
echo PROCESSING FILES...
echo -------------------------------------------------------

for %%F in (%*) do (
    set "filename=%%~nxF"
    set "outfile=%%~dpnF_%TIMESTAMP%.!EXTENSION!"
    
    echo Converting: "!filename!"
    
    ffmpeg -v error -stats -i "%%~fF" !ARGS! "!outfile!" -y
    
    if !errorlevel! equ 0 (
        echo [SUCCESS] Saved as: "!EXTENSION!"
    ) else (
        echo [ERROR] Conversion failed.
    )
    echo.
)

echo =======================================================
echo   ALL TASKS COMPLETE.
echo =======================================================
pause