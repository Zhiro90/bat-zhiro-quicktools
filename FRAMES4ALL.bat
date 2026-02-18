@echo off
setlocal enabledelayedexpansion

:: =================================================================
:: CONFIGURATION & BRANDING
:: =================================================================
set "TOOL_NAME=Zhiro Quick Tools"
set "TOOL_VERSION=1.0"
set "SCRIPT_NAME=Universal Frame Extractor"
set "SCRIPT_VERSION=2.2"

:: 1. GENERATE TIMESTAMP (YYYY-MM-DD_HHMM)
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "dt=%%I"
set "TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%%dt:~10,2%"

:: =================================================================
:: 2. PRE-FLIGHT CHECKS
:: =================================================================
echo [Checking Dependencies...]

:: Check for ImageMagick
where magick >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] ImageMagick not found in PATH. Required for GIF/WebP.
    pause
    exit /b 1
)

:: Check for FFmpeg
where ffmpeg >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] FFmpeg not found in PATH. Required for Video.
    pause
    exit /b 1
)

:: Check Inputs
if "%~1"=="" (
    echo [ERROR] No input files provided.
    echo Please drag and drop media files onto this script.
    pause
    exit /b 1
)

:: =================================================================
:: 3. PROCESSING LOOP
:: =================================================================
cls
echo =======================================================
echo   %TOOL_NAME% v%TOOL_VERSION%
echo   %SCRIPT_NAME% v%SCRIPT_VERSION%
echo =======================================================
echo.
echo Batch ID: %TIMESTAMP%
echo.

:PROCESS_LOOP
if "%~1"=="" goto :END_OF_FILES

set "currentFile=%~1"
set "baseName=%~n1"
set "fileExt=%~x1"
set "fileDir=%~dp1"

:: Output folder logic
set "outputFolder=%fileDir%%baseName%_frames_%TIMESTAMP%"

echo -------------------------------------------------------
echo Processing: "%~nx1"
echo Target:     "%baseName%_frames_%TIMESTAMP%\"

:: Create Output Directory
if not exist "!outputFolder!" mkdir "!outputFolder!"

:: --- LOGIC: EXTENSION BASED ROUTING ---
:: Default to VIDEO mode (FFmpeg) unless specific image extensions are found.
set "MODE=VIDEO"

if /I "!fileExt!"==".gif" set "MODE=IMAGE"
if /I "!fileExt!"==".webp" set "MODE=IMAGE"

echo Method:     !MODE!

if "!MODE!"=="VIDEO" (
    call :EXTRACT_FFMPEG
) else (
    call :EXTRACT_IMAGEMAGICK
)

echo.
shift
goto :PROCESS_LOOP

:: =================================================================
:: SUBROUTINES
:: =================================================================

:EXTRACT_FFMPEG
echo [INFO] Extracting with FFmpeg (High Speed)...
:: -vsync 0 prevents frame duplication/drop
:: %04d creates 0001.png, 0002.png, etc.
ffmpeg -v error -stats -i "!currentFile!" -vsync 0 -q:v 2 "!outputFolder!\frame_%%04d.png"

if exist "!outputFolder!\frame_0001.png" (
    echo [SUCCESS] Frames extracted.
) else (
    echo [ERROR] Extraction failed.
)
goto :eof

:EXTRACT_IMAGEMAGICK
echo [INFO] Extracting with ImageMagick (Coalesce)...
:: -coalesce handles GIF disposal methods correctly
magick "!currentFile!" -coalesce "!outputFolder!\frame_%%04d.png"

if exist "!outputFolder!\frame_0000.png" (
    echo [SUCCESS] Frames extracted.
) else (
    echo [ERROR] Extraction failed.
)
goto :eof

:: =================================================================
:: END
:: =================================================================
:END_OF_FILES
echo.
echo =======================================================
echo   ALL TASKS COMPLETE.
echo =======================================================
pause
exit /b 0