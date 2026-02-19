@echo off
setlocal enabledelayedexpansion

:: =================================================================
:: CONFIGURATION & BRANDING
:: =================================================================
set "TOOL_NAME=Zhiro Quick Tools"
set "TOOL_VERSION=1.0"
set "SCRIPT_NAME=Audio to Video (Smart Cover)"
set "SCRIPT_VERSION=2.2"

:: 1. GENERATE TIMESTAMP
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "dt=%%I"
set "TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%%dt:~10,2%"

:: 2. PATHS
set "SCRIPT_DIR=%~dp0"
set "DEFAULT_IMG=%SCRIPT_DIR%default.jpg"

:: =================================================================
:: 3. PRE-FLIGHT CHECKS
:: =================================================================
if "%~1"=="" (
    echo [ERROR] No input file provided.
    echo Please drag and drop an Audio file onto this script.
    pause
    exit /b 1
)

:: Check Dependencies
where ffmpeg >nul 2>&1 || (
    echo [ERROR] FFmpeg not found in PATH.
    pause
    exit /b 1
)
where ffprobe >nul 2>&1 || (
    echo [ERROR] FFprobe not found in PATH.
    pause
    exit /b 1
)

:: =================================================================
:: 4. SETUP & ROUTING
:: =================================================================
cls
echo =======================================================
echo   %TOOL_NAME% v%TOOL_VERSION%
echo   %SCRIPT_NAME% v%SCRIPT_VERSION%
echo =======================================================
echo.
echo Input:    "%~nx1"
echo Batch ID: %TIMESTAMP%
echo.

set "AUDIO_FILE=%~1"
set "FILE_DIR=%~dp1"
set "BASE_NAME=%~n1"
set "OUTPUT_FILE=%FILE_DIR%%BASE_NAME%_video_%TIMESTAMP%.mp4"

:: --- PRIORITY 1: CHECK EMBEDDED ART ---
echo [CHECK] Scanning for Embedded Cover Art...
set "HAS_COVER=0"

ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "%AUDIO_FILE%" > "%TEMP%\cover_check.tmp"
for %%A in ("%TEMP%\cover_check.tmp") do if %%~zA GTR 0 set "HAS_COVER=1"
del "%TEMP%\cover_check.tmp"

if "%HAS_COVER%"=="1" goto :RENDER_EMBEDDED

:: --- PRIORITY 2: CHECK EXTERNAL ANIMATION (GIF/WEBP) ---
echo [CHECK] No embedded art. Scanning for Animations...
if exist "%FILE_DIR%%BASE_NAME%.gif" (
    set "IMG_SOURCE=%FILE_DIR%%BASE_NAME%.gif"
    goto :RENDER_ANIMATION
)
if exist "%FILE_DIR%%BASE_NAME%.webp" (
    set "IMG_SOURCE=%FILE_DIR%%BASE_NAME%.webp"
    goto :RENDER_ANIMATION
)

:: --- PRIORITY 3: CHECK EXTERNAL STATIC IMAGE ---
echo [CHECK] No animation found. Scanning for Static Images...
if exist "%FILE_DIR%%BASE_NAME%.jpg" (
    set "IMG_SOURCE=%FILE_DIR%%BASE_NAME%.jpg"
    goto :RENDER_STATIC
)
if exist "%FILE_DIR%%BASE_NAME%.png" (
    set "IMG_SOURCE=%FILE_DIR%%BASE_NAME%.png"
    goto :RENDER_STATIC
)
if exist "%FILE_DIR%%BASE_NAME%.jpeg" (
    set "IMG_SOURCE=%FILE_DIR%%BASE_NAME%.jpeg"
    goto :RENDER_STATIC
)
if exist "%FILE_DIR%%BASE_NAME%.bmp" (
    set "IMG_SOURCE=%FILE_DIR%%BASE_NAME%.bmp"
    goto :RENDER_STATIC
)

:: --- PRIORITY 4: DEFAULT FALLBACK ---
echo [CHECK] No local image found. Checking Default...
if exist "%DEFAULT_IMG%" (
    set "IMG_SOURCE=%DEFAULT_IMG%"
    echo [INFO] Using Default Image: "default.jpg"
    goto :RENDER_STATIC
)

:: --- FAILURE ---
echo.
echo [ERROR] No visual source found!
echo I looked for:
echo   1. Embedded Art in the audio file.
echo   2. %BASE_NAME%.gif/webp/jpg/png in the same folder.
echo   3. default.jpg in the script folder.
echo.
pause
exit /b 1

:: =================================================================
:: RENDER LOGIC
:: =================================================================

:RENDER_EMBEDDED
echo [MODE] Embedded Cover Art detected.
echo [INFO] Rendering video from internal stream...
ffmpeg -v error -stats -loop 1 -i "%AUDIO_FILE%" -map 0:v -map 0:a -c:v libx264 -tune stillimage -c:a copy -shortest -pix_fmt yuv420p -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" "%OUTPUT_FILE%"
goto :FINISH

:RENDER_ANIMATION
for %%F in ("!IMG_SOURCE!") do echo [MODE] External Animation detected: "%%~nxF"
echo [INFO] Looping animation (Infinite Loop)...

:: FIX: -stream_loop -1 forces infinite looping regardless of GIF metadata
:: FIX: -ignore_loop 0 ensures GIF logic is respected but overridden by stream loop
:: FIX: -shortest cuts video when audio ends
ffmpeg -v error -stats -stream_loop -1 -i "%IMG_SOURCE%" -i "%AUDIO_FILE%" -c:v libx264 -preset medium -c:a copy -shortest -fflags +shortest -max_interleave_delta 100M -pix_fmt yuv420p -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" "%OUTPUT_FILE%"
goto :FINISH

:RENDER_STATIC
for %%F in ("!IMG_SOURCE!") do echo [MODE] Static Image detected: "%%~nxF"
echo [INFO] Creating video stream...
ffmpeg -v error -stats -loop 1 -i "%IMG_SOURCE%" -i "%AUDIO_FILE%" -c:v libx264 -tune stillimage -c:a copy -shortest -pix_fmt yuv420p -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" "%OUTPUT_FILE%"
goto :FINISH

:FINISH
echo.
echo =======================================================
if exist "%OUTPUT_FILE%" (
    echo   SUCCESS.
    for %%F in ("!OUTPUT_FILE!") do echo   Created: "%%~nxF"
) else (
    echo   ERROR: Encoding failed.
)
echo =======================================================
pause
exit /b