@echo off
setlocal enabledelayedexpansion

:: =================================================================
:: CONFIGURATION & BRANDING
:: =================================================================
set "TOOL_NAME=Zhiro Quick Tools"
set "TOOL_VERSION=1.1"
set "SCRIPT_NAME=Permanent ReplayGain Applicator"
set "SCRIPT_VERSION=1.0"

:: --- CONFIG SWITCH ---
:: 0 = Show Menu (Ask every time)
:: 1 = Auto-Start in TRACK Mode (Skip menu)
set "AUTO_START_TRACK=1"

:: 1. GENERATE TIMESTAMP
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "dt=%%I"
set "TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%%dt:~10,2%"

:: =================================================================
:: 2. PRE-FLIGHT CHECKS
:: =================================================================
where ffmpeg >nul 2>&1 || (
    echo [ERROR] FFmpeg not found.
    pause
    exit /b 1
)
where ffprobe >nul 2>&1 || (
    echo [ERROR] FFprobe not found.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo [ERROR] No input files. Drag and drop Audio files here.
    pause
    exit /b 1
)

:: =================================================================
:: 3. SETUP & MENU
:: =================================================================
cls
echo =======================================================
echo   %TOOL_NAME% v%TOOL_VERSION%
echo   %SCRIPT_NAME% v%SCRIPT_VERSION%
echo =======================================================
echo.
echo Batch ID: %TIMESTAMP%
echo.

if "%AUTO_START_TRACK%"=="1" (
    echo [CONFIG] Auto-Start Enabled: Defaulting to TRACK Gain.
    set "AF_FILTER=volume=replaygain=track"
    set "SUFFIX=_trackgain"
    goto :PRE_LOOP
)

echo SELECT MODE:
echo   [1] Use TRACK Tags (Best for Shuffle/Playlists)
echo   [2] Use ALBUM Tags (Best for Full Albums)
echo   [3] NO TAGS? -> Auto-Normalize (EBU R128)
echo.

set "MODE=1"
set /p "MODE=Option [1-3]: "
if "!MODE!"=="" set "MODE=1"

if "!MODE!"=="1" (
    set "AF_FILTER=volume=replaygain=track"
    set "SUFFIX=_trackgain"
) else if "!MODE!"=="2" (
    set "AF_FILTER=volume=replaygain=album"
    set "SUFFIX=_albumgain"
) else (
    set "AF_FILTER=loudnorm=I=-16:TP=-1.5:LRA=11"
    set "SUFFIX=_normalized"
)

:PRE_LOOP
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
set "fileExt=%~x1"
set "fileBase=%~n1"

echo Processing: "!fileName!"

if not exist "!inputFile!" (
    echo    - [ERROR] File not accessible.
    goto :NEXT_FILE
)

:: --- STEP A: CHECK INTEGRITY ---
:: Verify if the file is valid audio before trying to read tags
ffprobe -v error -show_format -i "!inputFile!" >nul 2>&1
if errorlevel 1 (
    echo    - [ERROR] File appears corrupt or invalid. Skipping.
    goto :NEXT_FILE
)

:: --- STEP B: DETECT CODEC SETTINGS ---
set "ENC_ARGS="
if /I "!fileExt!"==".flac" set "ENC_ARGS=-c:a flac -compression_level 5"
if /I "!fileExt!"==".mp3"  set "ENC_ARGS=-c:a libmp3lame -b:a 320k"
if /I "!fileExt!"==".wav"  set "ENC_ARGS=-c:a pcm_s16le"
if /I "!fileExt!"==".m4a"  set "ENC_ARGS=-c:a aac -b:a 320k"
if /I "!fileExt!"==".aac"  set "ENC_ARGS=-c:a aac -b:a 320k"
if /I "!fileExt!"==".ogg"  set "ENC_ARGS=-c:a libvorbis -q:a 6"

if "!ENC_ARGS!"=="" (
    echo    - [WARN] Unknown extension. Defaulting to high quality MP3.
    set "ENC_ARGS=-c:a libmp3lame -b:a 320k"
)

:: --- STEP C: READ CURRENT GAIN (Only for modes 1 & 2) ---
if not "!MODE!"=="3" (
    set "DETECTED_GAIN="
    
    ffprobe -v error -show_entries format_tags=REPLAYGAIN_TRACK_GAIN -of default=noprint_wrappers=1:nokey=1 "!inputFile!" > "%TEMP%\rg_check.tmp"
    
    :: Safe read
    for %%A in ("%TEMP%\rg_check.tmp") do (
        if %%~zA GTR 0 set /p DETECTED_GAIN=<"%TEMP%\rg_check.tmp"
    )
    del "%TEMP%\rg_check.tmp" 2>nul
    
    :: LOGIC CHECK: If no tag, skip gracefully
    if not defined DETECTED_GAIN (
        echo    - [INFO] No ReplayGain tag detected. Skipping.
        goto :NEXT_FILE
    ) else (
        echo    - [INFO] Found Tag Gain: !DETECTED_GAIN! dB
    )
)

:: Construct Output Path
set "outFile=!fileDir!!fileBase!!SUFFIX!_%TIMESTAMP%!fileExt!"

:: --- STEP D: APPLY GAIN & ENCODE ---
ffmpeg -v error -stats -i "!inputFile!" -af "!AF_FILTER!" !ENC_ARGS! -map_metadata 0 -y "!outFile!"

:: --- STEP E: VALIDATE SUCCESS ---
set "FILE_SIZE=0"
if exist "!outFile!" for %%A in ("!outFile!") do set "FILE_SIZE=%%~zA"

if !FILE_SIZE! GTR 0 (
    echo    - [SUCCESS] Saved.
) else (
    echo    - [ERROR] Encoding failed.
    if exist "!outFile!" del "!outFile!"
)
echo.

:NEXT_FILE
shift
goto :PROCESS_LOOP

:FINISHED
echo =======================================================
echo   ALL TASKS COMPLETE.
echo =======================================================
pause
exit /b