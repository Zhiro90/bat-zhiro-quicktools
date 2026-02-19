@echo off
setlocal enabledelayedexpansion

:: =================================================================
:: CONFIGURATION & BRANDING
:: =================================================================
set "TOOL_NAME=Zhiro Quick Tools"
set "TOOL_VERSION=1.1"
set "SCRIPT_NAME=Universal MKV Demuxer"
set "SCRIPT_VERSION=1.0"

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
    echo Please drag and drop Video files [MKV/MP4] onto this script.
    pause
    exit /b 1
)

:: =================================================================
:: 3. UI SETUP & MENU
:: =================================================================
cls
echo =======================================================
echo   %TOOL_NAME% v%TOOL_VERSION%
echo   %SCRIPT_NAME% v%SCRIPT_VERSION%
echo =======================================================
echo.
echo Batch ID: %TIMESTAMP%
echo.
echo SELECT DEMUX MODE:
echo   [1] ALL  - Extract Video, Audios, Subs, and Fonts [Default]
echo   [2] SUBS - Extract ONLY Subs and Fonts (ASS Assets)
echo.

set "MODE=1"
set /p "MODE=Option [1-2]: "
if "!MODE!"=="" set "MODE=1"

:: =================================================================
:: 4. MAIN PROCESSING LOOP (SHIFT METHOD)
:: =================================================================
echo.
echo -------------------------------------------------------
echo PROCESSING FILES...
echo -------------------------------------------------------

:PROCESS_LOOP
if "%~1"=="" goto :FINISHED

set "inputFile=%~f1"
set "fileName=%~nx1"
set "fileDir=%~dp1"
set "fileBase=%~n1"

:: Create a dedicated folder for the demuxed files
set "OUT_FOLDER=!fileDir!!fileBase!_Demux_!TIMESTAMP!"
mkdir "!OUT_FOLDER!"

echo Processing: "!fileName!"
echo    - Extracting to: "!fileBase!_Demux_!TIMESTAMP!\"

:: Move into the output folder to dump attachments easily
pushd "!OUT_FOLDER!"

:: --- STEP A: EXTRACT FONTS / ATTACHMENTS (Always) ---
echo    - Dumping fonts and attachments...
ffmpeg -v error -dump_attachment:t "" -i "!inputFile!" -y >nul 2>&1

:: --- STEP B: EXTRACT SUBTITLES (Always) ---
echo    - Extracting Subtitles...
for /L %%S in (0,1,15) do (
    echo      Searching for Subtitle Track %%S...
    ffmpeg -v error -i "!inputFile!" -map 0:s:%%S -c copy "!fileBase!_sub_%%S.ass" >nul 2>&1
    
    :: Use explicit !errorlevel! check to avoid loop bugs
    if !errorlevel! neq 0 (
        echo      Track %%S not found. Stopping subtitle search.
        if exist "!fileBase!_sub_%%S.ass" del "!fileBase!_sub_%%S.ass" >nul 2>&1
        goto :DONE_SUBS
    )
)
:DONE_SUBS

:: If Mode is 2 (Subs Only), skip the Audio/Video section
if "!MODE!"=="2" goto :SKIP_AV

:: --- STEP C: EXTRACT AUDIO ---
echo    - Extracting Audio tracks...
for /L %%A in (0,1,10) do (
    echo      Searching for Audio Track %%A...
    ffmpeg -v error -i "!inputFile!" -map 0:a:%%A -c copy "!fileBase!_audio_%%A.mka" >nul 2>&1
    
    if !errorlevel! neq 0 (
        echo      Track %%A not found. Stopping audio search.
        if exist "!fileBase!_audio_%%A.mka" del "!fileBase!_audio_%%A.mka" >nul 2>&1
        goto :DONE_AUDIO
    )
)
:DONE_AUDIO

:: --- STEP D: EXTRACT VIDEO ---
echo    - Extracting Video track...
echo      Dumping pure video stream...
ffmpeg -v error -stats -i "!inputFile!" -map 0:v:0 -c copy "!fileBase!_video.mkv" >nul 2>&1

:SKIP_AV
:: Return to original directory
popd

echo    - [SUCCESS] Demux complete.
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