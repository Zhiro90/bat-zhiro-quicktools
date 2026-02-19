@echo off
setlocal EnableDelayedExpansion

:: =================================================================
:: CONFIGURATION & BRANDING
:: =================================================================
set "TOOL_NAME=Zhiro Quick Tools"
set "TOOL_VERSION=1.0"
set "SCRIPT_NAME=Hardsub Burner (SRT/ASS)"
set "SCRIPT_VERSION=3.1"

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

:: Check dependencies (Path Agnostic)
where ffmpeg >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] FFmpeg not found in PATH.
    pause
    exit /b
)

where ffprobe >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] FFprobe not found in PATH.
    pause
    exit /b
)

:: =================================================================
:: 3. SETUP & DETECTION
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

set "INPUT_FILE=%~1"
set "FILE_PATH=%~dp1"
set "FILE_NAME=%~n1"
set "OUTPUT_FILE=%FILE_PATH%%FILE_NAME%_hardsub_%TIMESTAMP%.mp4"

:: File Candidates
set "SRT_FILE=%FILE_PATH%%FILE_NAME%.srt"
set "ASS_FILE=%FILE_PATH%%FILE_NAME%.ass"

set "SUB_FOUND=no"
set "SUB_FILTER_CMD="
set "USE_NATIVE_STYLE=0"

:: --- LOGIC: SUBTITLE SOURCE DETECTION ---

:: 1. Priority A: External SRT (Apply Custom Styles)
if exist "!SRT_FILE!" goto :FOUND_SRT

:: 2. Priority B: External ASS (Keep Original Styles)
if exist "!ASS_FILE!" goto :FOUND_ASS

:: 3. Priority C: Internal Tracks
echo [INFO] No external subtitles found. Scanning internal tracks...
set count=0

for /f "tokens=1,2 delims=," %%A in ('ffprobe -v error -select_streams s -show_entries stream^=index^:stream_tags^=language -of csv^=p^=0 "!INPUT_FILE!" 2^>nul') do (
    set /a count+=1
    set "sub_idx[!count!]=%%A"
    set "sub_lang[!count!]=%%B"
    echo    - Found Track #%%A [Lang: %%B]
)

if !count! GTR 0 goto :SELECT_INTERNAL

:: 4. No subtitles found
goto :NO_SUBS_FOUND

:: =================================================================
:: BRANCH: EXTERNAL SRT
:: =================================================================
:FOUND_SRT
echo [INFO] External SRT found: "%FILE_NAME%.srt"
set "TARGET_SUB=!SRT_FILE!"
set "USE_NATIVE_STYLE=0" 
goto :PREPARE_FILTER

:: =================================================================
:: BRANCH: EXTERNAL ASS
:: =================================================================
:FOUND_ASS
echo [INFO] External ASS found: "%FILE_NAME%.ass"
set "TARGET_SUB=!ASS_FILE!"
set "USE_NATIVE_STYLE=1"
echo [INFO] ASS detected: Custom style menu will be skipped to preserve graphics.
goto :PREPARE_FILTER

:: =================================================================
:: BRANCH: INTERNAL TRACKS
:: =================================================================
:SELECT_INTERNAL
echo.
echo Select internal subtitle track to burn:
for /L %%i in (1,1,!count!) do (
    echo    [%%i] Language: !sub_lang[%%i]!
)
echo.
set /p selection="Enter track number [Default 1]: "

if not defined selection set selection=1
for %%j in (!selection!) do set "actual_index=!sub_idx[%%j]!"

echo [INFO] Selected FFmpeg Stream Index: !actual_index!
set "SUB_FILTER_CMD=subtitles='!INPUT_FILE!':si=!actual_index!"
set "USE_NATIVE_STYLE=0"
goto :STYLE_SELECTION

:: =================================================================
:: BRANCH: ERROR
:: =================================================================
:NO_SUBS_FOUND
echo.
echo [ERROR] No subtitles found (Neither .srt, .ass, nor internal tracks).
pause
exit /b

:: =================================================================
:: PREPARE EXTERNAL FILTER
:: =================================================================
:PREPARE_FILTER
:: Escape paths for FFmpeg filter (Windows backslashes kill FFmpeg)
set "ESCAPED_SUB=!TARGET_SUB:\=\\!"
set "ESCAPED_SUB=!ESCAPED_SUB::=\:!"
set "SUB_FILTER_CMD=subtitles='!ESCAPED_SUB!'"

:: If it is ASS, skip style selection immediately
if "!USE_NATIVE_STYLE!"=="1" goto :EXECUTE_BURN

goto :STYLE_SELECTION

:: =================================================================
:: 4. STYLE CONFIGURATION (SRT & Internal Only)
:: =================================================================
:STYLE_SELECTION
echo.
echo -------------------------------------------------------
echo SELECT CAPTION STYLE:
echo -------------------------------------------------------
echo  [1] Cinema Style (Yellow Text, Black Outline) [Default]
echo  [2] Simple White (Arial, Black Outline)
echo  [3] Custom (Manual Size/Color)
echo.

set /p style_choice="Option [1-3]: "
if "!style_choice!"=="" set style_choice=1

set "STYLE_SETTINGS="

:: Style 1: Cinema (Yellow)
if "!style_choice!"=="1" (
    set "STYLE_SETTINGS=:force_style='FontName=Arial,FontSize=24,PrimaryColour=&H0000FFFF,BorderStyle=1,Outline=2,Shadow=1,Alignment=2,MarginV=20,Bold=1'"
)

:: Style 2: Simple White
if "!style_choice!"=="2" (
    set "STYLE_SETTINGS=:force_style='FontName=Arial,PrimaryColour=&H00FFFFFF,BorderStyle=1,Outline=1,Shadow=0,Alignment=2,MarginV=25,FontSize=20'"
)

:: Style 3: Custom
if "!style_choice!"=="3" (
    echo.
    echo [CUSTOM SETTINGS]
    set /p custom_size="Font Size (Default 24): "
    set /p custom_color_rgb="Color HEX (RRGGBB) [Default FFFFFF]: "
    
    if "!custom_size!"=="" set custom_size=24
    if "!custom_color_rgb!"=="" set custom_color_rgb=FFFFFF
    
    :: Convert RGB to BGR for ASS format (&H00BBGGRR)
    set "R=!custom_color_rgb:~0,2!"
    set "G=!custom_color_rgb:~2,2!"
    set "B=!custom_color_rgb:~4,2!"
    set "ASS_COLOR=&H00!B!!G!!R!"
    
    set "STYLE_SETTINGS=:force_style='FontSize=!custom_size!,PrimaryColour=!ASS_COLOR!,BorderStyle=1,Outline=1,Shadow=1,Alignment=2,MarginV=20'"
)

goto :EXECUTE_BURN

:: =================================================================
:: 5. EXECUTION
:: =================================================================
:EXECUTE_BURN
set "FINAL_FILTER=!SUB_FILTER_CMD!!STYLE_SETTINGS!"

echo.
echo -------------------------------------------------------
echo BURNING SUBTITLES...
echo -------------------------------------------------------
echo Input:  "%~nx1"
echo Output: "%FILE_NAME%_hardsub_%TIMESTAMP%.mp4"
echo.

:: Execute FFmpeg
ffmpeg -v error -stats -i "!INPUT_FILE!" -vf "!FINAL_FILTER!" -c:v libx264 -crf 20 -preset medium -c:a copy "!OUTPUT_FILE!"

echo.
echo =======================================================
if %errorlevel% neq 0 (
    echo [ERROR] FFmpeg failed. Check input/subtitle integrity.
) else (
    echo [SUCCESS] File created successfully.
)
echo =======================================================
pause