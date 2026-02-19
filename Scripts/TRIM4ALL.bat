@echo off
setlocal enabledelayedexpansion

:: =================================================================
:: CONFIGURATION & BRANDING
:: =================================================================
set "TOOL_NAME=Zhiro Quick Tools"
set "TOOL_VERSION=1.0"
set "SCRIPT_NAME=Media Trimmer"
set "SCRIPT_VERSION=1.0"

:: =================================================================
:: 1. FILE VALIDATION
:: =================================================================
if "%~1"=="" (
    echo [ERROR] No input file found.
    echo Please drag and drop a media file onto this script.
    pause
    exit /b
)

set "file_path=%~1"
set "file_name=%~n1"
set "file_ext=%~x1"
set "file_dir=%~dp1"

:: =================================================================
:: 2. SMART UI & INPUT
:: =================================================================
cls
echo =======================================================
echo   %TOOL_NAME% v%TOOL_VERSION%
echo   %SCRIPT_NAME% v%SCRIPT_VERSION%
echo =======================================================
echo.
echo Input File: "%~nx1"
echo.
echo -------------------------------------------------------
echo INSTRUCTIONS:
echo 1. PRECISE MODE (Default): Just enter the START TIME.
echo    (Re-encodes. Accurate. Works for audio/video.)
echo.
echo 2. FAST MODE: Type 'copy' to switch to stream copy.
echo    (No re-encode. Fast but cuts on keyframes.)
echo -------------------------------------------------------
echo.

set "USER_INPUT="
set /p "USER_INPUT=Enter START TIME (or type 'copy'): "

:: --- LOGIC BRANCHING ---
if /I "!USER_INPUT!"=="copy" goto :MODE_FAST

:: --- MODE: PRECISE (DEFAULT) ---
:MODE_PRECISE
set "start_time=!USER_INPUT!"
set "codec_params="
set "mode_display=Precise (Re-encode)"

echo.
echo [Precise Mode Selected]
echo.
set /p "end_time=Enter END TIME (Leave empty for end of file): "
goto :EXECUTE

:: --- MODE: FAST (COPY) ---
:MODE_FAST
set "codec_params=-c copy"
set "mode_display=Fast (Stream Copy)"

echo.
echo [Fast Mode Selected]
echo.
set /p "start_time=Enter START TIME (Leave empty for 0): "
set /p "end_time=Enter END TIME (Leave empty for end of file): "
goto :EXECUTE

:: =================================================================
:: 3. EXECUTION
:: =================================================================
:EXECUTE

:: Generate standard timestamp (YYYY-MM-DD_HHMM)
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "dt=%%I"
set "TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%%dt:~10,2%"

set "output_file=%file_dir%%file_name%_trim_%TIMESTAMP%%file_ext%"

:: Construct FFmpeg flags
set "ss_param="
if not "!start_time!"=="" set "ss_param=-ss !start_time!"

set "to_param="
if not "!end_time!"=="" set "to_param=-to !end_time!"

cls
echo =======================================================
echo   PROCESSING...
echo =======================================================
echo.
echo Mode:  !mode_display!
echo Start: !start_time!
echo End:   !end_time!
echo.
echo Output: "%file_name%_trim_%TIMESTAMP%%file_ext%"
echo.

:: Execute FFmpeg
ffmpeg -v error -stats -i "!file_path!" !ss_param! !to_param! !codec_params! "!output_file!"

echo.
if exist "!output_file!" (
    echo [SUCCESS] File created successfully.
) else (
    echo [ERROR] Failed to create file. Check your inputs.
)
echo.
echo =======================================================
pause