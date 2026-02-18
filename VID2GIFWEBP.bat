@echo off
setlocal enabledelayedexpansion

:: =================================================================
:: CONFIGURATION & BRANDING
:: =================================================================
set "TOOL_NAME=Zhiro Quick Tools"
set "TOOL_VERSION=1.0"
set "SCRIPT_NAME=Universal Animation Converter (GIF/WebP)"
set "SCRIPT_VERSION=2.2"

:: 1. GENERATE TIMESTAMP
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "dt=%%I"
set "TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%%dt:~10,2%"

:: =================================================================
:: 2. PRE-FLIGHT CHECKS
:: =================================================================
if "%~1"=="" (
    echo [ERROR] No input files provided.
    echo Please drag and drop video files onto this script.
    pause
    exit /b 1
)

:: Check FFmpeg
where ffmpeg >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] FFmpeg not found. Please install it.
    pause
    exit /b 1
)

:: Check MediaInfo (Preferred)
set "HAS_MEDIAINFO=0"
where mediainfo >nul 2>&1
if %errorlevel% equ 0 set "HAS_MEDIAINFO=1"

:: Check FFprobe (Backup)
set "HAS_FFPROBE=0"
where ffprobe >nul 2>&1
if %errorlevel% equ 0 set "HAS_FFPROBE=1"

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
echo.
echo SELECT OUTPUT FORMAT:
echo.
echo   [1] GIF  (High Quality, Larger File)
echo   [2] WebP (High Efficiency, Smaller File) [Default]
echo.

set "FORMAT=2"
set /p "FORMAT=Choose [1-2]: "
if "!FORMAT!"=="" set "FORMAT=2"

:: =================================================================
:: 4. GLOBAL SETTINGS
:: =================================================================
echo.
echo -------------------------------------------------------
echo CONFIGURATION
echo -------------------------------------------------------

:: Ask for Force FPS
echo.
echo [FPS SETTINGS]
echo Enter a value ONLY if you want to force a specific speed for ALL files.
echo Leave EMPTY to Auto-Detect the FPS of each video individually.
echo.
set "GLOBAL_FPS="
set /p "GLOBAL_FPS=Force Frame Rate (e.g. 24, 60): "

:: WebP Quality Question
set "WEBP_Q=80"
if "!FORMAT!"=="2" (
    echo.
    set /p "WEBP_Q=Enter WebP Quality (1-100) [Default 80]: "
    if "!WEBP_Q!"=="" set "WEBP_Q=80"
)

:: =================================================================
:: 5. PROCESSING LOOP
:: =================================================================
echo.
echo -------------------------------------------------------
echo PROCESSING FILES...
echo -------------------------------------------------------

for %%F in (%*) do (
    set "inputFile=%%~fF"
    set "baseName=%%~nF"
    set "fileDir=%%~dpF"
    
    echo Processing: "%%~nxF"
    
    :: --- FPS DETECTION LOGIC ---
    set "FINAL_FPS=30"
    
    if defined GLOBAL_FPS (
        set "FINAL_FPS=!GLOBAL_FPS!"
        echo    - [INFO] Using Forced FPS: !FINAL_FPS!
    ) else (
        call :DETECT_FPS "%%~fF"
    )

    :: ROUTING
    if "!FORMAT!"=="1" call :CONVERT_GIF
    if "!FORMAT!"=="2" call :CONVERT_WEBP
    
    echo.
)

echo =======================================================
echo   ALL TASKS COMPLETE.
echo =======================================================
pause
exit /b

:: =================================================================
:: SUBROUTINES
:: =================================================================

:DETECT_FPS
:: Arg1 = Input File Path
set "rawFPS="

:: 1. Try MediaInfo (Best)
if "!HAS_MEDIAINFO!"=="1" (
    :: Try FrameRate_Original first (Standard logic from v1.0)
    for /f "tokens=*" %%a in ('mediainfo --Output^="Video;%%FrameRate_Original%%" "%~1"') do set "rawFPS=%%a"
    
    :: If empty, try FrameRate
    if "!rawFPS!"=="" (
        for /f "tokens=*" %%a in ('mediainfo --Output^="Video;%%FrameRate%%" "%~1"') do set "rawFPS=%%a"
    )
)

:: 2. Try FFprobe (Backup)
if "!rawFPS!"=="" (
    if "!HAS_FFPROBE!"=="1" (
        for /f "tokens=*" %%a in ('ffprobe -v 0 -of csv^=p^=0 -select_streams v:0 -show_entries stream^=r_frame_rate "%~1"') do set "rawFPS=%%a"
    )
)

:: 3. Clean/Validate (Logic restored from original script)
if not "!rawFPS!"=="" (
    set "cleanFPS=!rawFPS!"
    set "cleanFPS=!cleanFPS: =!"
    set "cleanFPS=!cleanFPS:,=.!"
    set "cleanFPS=!cleanFPS:FPS=!"
    set "cleanFPS=!cleanFPS:Hz=!"
    set "FINAL_FPS=!cleanFPS!"
    echo    - [AUTO] Detected FPS: !FINAL_FPS!
) else (
    echo    - [WARN] Detection failed. Defaulting to 30.
    set "FINAL_FPS=30"
)
goto :eof


:CONVERT_GIF
set "palFile=%TEMP%\palette_%RANDOM%.png"
set "outFile=!fileDir!!baseName!_%TIMESTAMP%.gif"

echo    - Step 1: Generating Palette (FPS: !FINAL_FPS!)...
ffmpeg -v error -stats -i "!inputFile!" -vf "fps=!FINAL_FPS!,colorspace=bt709:iall=bt601-6-625:fast=1,palettegen=stats_mode=diff" -y "!palFile!"

if not exist "!palFile!" (
    echo    - [ERROR] Palette generation failed. Check input video.
    goto :eof
)

echo    - Step 2: Rendering GIF...
ffmpeg -v error -stats -i "!inputFile!" -i "!palFile!" -lavfi "fps=!FINAL_FPS!,colorspace=bt709:iall=bt601-6-625:fast=1 [x]; [x][1:v] paletteuse=dither=sierra2_4a:diff_mode=rectangle" -y "!outFile!"

:: Cleanup Temp Palette
if exist "!palFile!" del "!palFile!"

if exist "!outFile!" (
    echo    - [SUCCESS] Created GIF.
) else (
    echo    - [ERROR] Failed to create GIF.
)
goto :eof


:CONVERT_WEBP
set "outFile=!fileDir!!baseName!_%TIMESTAMP%.webp"

echo    - Rendering WebP (FPS: !FINAL_FPS! / Q: !WEBP_Q!)...
:: Note: Using -vsync vfr helps prevent dup frames if input is variable framerate
ffmpeg -v error -stats -i "!inputFile!" ^
  -vf "fps=!FINAL_FPS!,format=yuva420p" ^
  -vsync vfr ^
  -c:v libwebp ^
  -lossless 0 ^
  -compression_level 4 ^
  -qscale !WEBP_Q! ^
  -loop 0 ^
  -an ^
  -y "!outFile!"

if exist "!outFile!" (
    echo    - [SUCCESS] Created WebP.
) else (
    echo    - [ERROR] Failed to create WebP.
)
goto :eof