@echo off
setlocal enabledelayedexpansion
:: Set UTF-8 encoding so the script understands special characters
chcp 65001 >nul

:: =================================================================
:: CONFIGURATION & BRANDING
:: =================================================================
set "TOOL_NAME=Zhiro Quick Tools"
set "TOOL_VERSION=1.0"
set "SCRIPT_NAME=Universal Caption Tool"
set "SCRIPT_VERSION=3.5"

:: 1. GENERATE TIMESTAMP (YYYY-MM-DD_HHMM)
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "dt=%%I"
set "TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%%dt:~10,2%"

:: =================================================================
:: 2. PRE-FLIGHT CHECKS
:: =================================================================
if "%~1"=="" (
    echo [ERROR] No file provided.
    echo Please drag and drop a file onto this script.
    pause
    exit /b 1
)

where magick >nul 2>&1 || (echo [ERROR] ImageMagick not found in PATH. & set "dep_error=1")
where ffmpeg >nul 2>&1 || (echo [ERROR] FFmpeg not found in PATH. & set "dep_error=1")
if defined dep_error (pause & exit /b 1)

:: =================================================================
:: 3. UI & FILE ROUTING
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

:: Detect Type
set "extension=%~x1"
set "image_exts=.jpg .jpeg .png .gif .bmp .webp"
set "video_exts=.mp4 .mkv .mov .webm .avi .flv"

echo %image_exts% | find /i "%extension%" >nul && goto :ProcessImage
echo %video_exts% | find /i "%extension%" >nul && goto :ProcessVideo

echo [ERROR] Unsupported file type ("%extension%").
pause & exit /b 1

:: =================================================================
::                           IMAGE ROUTINE
:: =================================================================
:ProcessImage
set "DEFAULT_FONT=Arial"
set "DEFAULT_TEXT_COLOR=black"
set "DEFAULT_BACKGROUND=white"
set "DEFAULT_STROKE_COLOR=black"
set "DEFAULT_STROKE_WIDTH=2"
set "TEXT_PADDING=15"
set "TOP_SPACE=10"
set "DEFAULT_MAX_CHARS=25"
set "MIN_FONT_SIZE=8"

:StyleMenu
echo CHOOSE CAPTION STYLE:
echo.
echo [0] Default Plain (Arial, Black Text on White Bar)
echo [1] Classic Meme (Impact, White Text w/ Black Outline)
echo [2] Full Custom (Bar style)
echo [3] Floating Text (Overlay directly on image - No Bar)
echo.
set /p "STYLE_CHOICE=Enter choice [0-3]: "
if "%STYLE_CHOICE%"=="" set "STYLE_CHOICE=0"

if "%STYLE_CHOICE%"=="0" (
    set "USER_FONT=%DEFAULT_FONT%"
    set "USER_TEXT_COLOR=%DEFAULT_TEXT_COLOR%"
    set "USER_BACKGROUND=%DEFAULT_BACKGROUND%"
    set "USER_STROKE_COLOR=none"
    set "USER_STROKE_WIDTH=0"
    set "MAX_CHARS_PER_LINE=%DEFAULT_MAX_CHARS%"
    set "USER_FONT_SIZE=0"
    goto :ProcessImage_Continue
)
if "%STYLE_CHOICE%"=="1" (
    set "USER_FONT=Impact"
    set "USER_TEXT_COLOR=white"
    set "USER_BACKGROUND=%DEFAULT_BACKGROUND%"
    set "USER_STROKE_COLOR=%DEFAULT_STROKE_COLOR%"
    set "USER_STROKE_WIDTH=%DEFAULT_STROKE_WIDTH%"
    set "MAX_CHARS_PER_LINE=15"
    set "USER_FONT_SIZE=0"
    goto :ProcessImage_Continue
)
if "%STYLE_CHOICE%"=="2" (
    set "MAX_CHARS_PER_LINE=%DEFAULT_MAX_CHARS%"
    set /p "USER_FONT=Enter font name (leave empty for %DEFAULT_FONT%): "
    if "!USER_FONT!"=="" set "USER_FONT=%DEFAULT_FONT%"
    set /p "USER_BACKGROUND=Enter background color (leave empty for %DEFAULT_BACKGROUND%): "
    if "!USER_BACKGROUND!"=="" set "USER_BACKGROUND=%DEFAULT_BACKGROUND%"
    set /p "USER_TEXT_COLOR=Enter text color (leave empty for %DEFAULT_TEXT_COLOR%): "
    if "!USER_TEXT_COLOR!"=="" set "USER_TEXT_COLOR=%DEFAULT_TEXT_COLOR%"
    set /p "USER_STROKE_COLOR=Enter text OUTLINE color (leave empty for %DEFAULT_STROKE_COLOR%): "
    if "!USER_STROKE_COLOR!"=="" set "USER_STROKE_COLOR=%DEFAULT_STROKE_COLOR%"
    set /p "USER_STROKE_WIDTH=Enter text OUTLINE width (leave empty for %DEFAULT_STROKE_WIDTH%): "
    if "!USER_STROKE_WIDTH!"=="" set "USER_STROKE_WIDTH=%DEFAULT_STROKE_WIDTH%"
    goto :ProcessImage_Continue
)
if "%STYLE_CHOICE%"=="3" (
    goto :SetupOverlay
)
goto :StyleMenu

:: --- SETUP FOR OPTION 3 (OVERLAY) ---
:SetupOverlay
echo.
echo --- Floating Text Settings ---
set "MAX_CHARS_PER_LINE=20"

:: 1. Alignment
echo Select Alignment:
echo [7] Top-Left   [8] Top-Center   [9] Top-Right
echo [4] Mid-Left   [5] Center       [6] Mid-Right
echo [1] Bot-Left   [2] Bot-Center   [3] Bot-Right
set /p "ALIGN_INPUT=Choose position (Default 2): "
if "!ALIGN_INPUT!"=="" set "ALIGN_INPUT=2"
if "!ALIGN_INPUT!"=="7" set "USER_GRAVITY=NorthWest"
if "!ALIGN_INPUT!"=="8" set "USER_GRAVITY=North"
if "!ALIGN_INPUT!"=="9" set "USER_GRAVITY=NorthEast"
if "!ALIGN_INPUT!"=="4" set "USER_GRAVITY=West"
if "!ALIGN_INPUT!"=="5" set "USER_GRAVITY=Center"
if "!ALIGN_INPUT!"=="6" set "USER_GRAVITY=East"
if "!ALIGN_INPUT!"=="1" set "USER_GRAVITY=SouthWest"
if "!ALIGN_INPUT!"=="2" set "USER_GRAVITY=South"
if "!ALIGN_INPUT!"=="3" set "USER_GRAVITY=SouthEast"

:: 2. Appearance
set /p "USER_FONT=Enter font name (Default Impact): "
if "!USER_FONT!"=="" set "USER_FONT=Impact"

set /p "USER_TEXT_COLOR=Text Color (Default white): "
if "!USER_TEXT_COLOR!"=="" set "USER_TEXT_COLOR=white"

echo.
echo For TRANSPARENT outline, type: none
set /p "USER_STROKE_COLOR=Outline Color (Default black, or 'none'): "
if "!USER_STROKE_COLOR!"=="" set "USER_STROKE_COLOR=black"
if /i "!USER_STROKE_COLOR!"=="transparente" set "USER_STROKE_COLOR=none"
if /i "!USER_STROKE_COLOR!"=="transparent" set "USER_STROKE_COLOR=none"

set /p "USER_STROKE_WIDTH=Outline Width (Default 2): "
if "!USER_STROKE_WIDTH!"=="" set "USER_STROKE_WIDTH=2"

set /p "USER_FONT_SIZE=Font Size (Enter 0 for auto-scale): "
if "!USER_FONT_SIZE!"=="" set "USER_FONT_SIZE=0"

goto :ProcessImage_Continue


:ProcessImage_Continue
cls
:: Only ask for font size here if it wasn't Option 3 (which already asked)
if not "%STYLE_CHOICE%"=="3" (
    if "%STYLE_CHOICE%"=="2" (
        set /p "USER_FONT_SIZE=Enter font size (leave empty or 0 for auto-scale): "
        if "!USER_FONT_SIZE!"=="" set "USER_FONT_SIZE=0"
    ) else ( set "USER_FONT_SIZE=0" )
)

:Image_GetCaption
echo --------------------------------------------------------
echo Processing: %~nx1
set "CAPTION="
set /p "CAPTION=Enter caption for %~nx1 (use 'linebreak' for new row): "

if not defined CAPTION (echo No caption entered. Skipping. & goto :EndScript)

set "CAPTION=!CAPTION:linebreak=\n!"
for /f "tokens=1 delims= " %%a in ('magick identify -format "%%w" "%~1"') do (set /a IMG_WIDTH=%%a)

:: Font Size Calculation Logic
if "!USER_FONT_SIZE!"=="0" (
    if defined IMG_WIDTH (
        set /a FONT_SIZE=IMG_WIDTH / !MAX_CHARS_PER_LINE!
        if !FONT_SIZE! lss %MIN_FONT_SIZE% set /a FONT_SIZE=%MIN_FONT_SIZE%
    ) else ( set /a FONT_SIZE=24 )
) else (
    set /a FONT_SIZE=USER_FONT_SIZE
    if !FONT_SIZE! lss %MIN_FONT_SIZE% set /a FONT_SIZE=%MIN_FONT_SIZE%
)

echo Creating image with font size: !FONT_SIZE!pt

:: --- UPDATE: USING BRANDED TIMESTAMP ---
set "outputFile=%~dpn1_captioned_%TIMESTAMP%.png"

:: --- BRANCHING POINT: If Option 3, go to Overlay Logic ---
if "%STYLE_CHOICE%"=="3" goto :RenderOverlay

:: --- STANDARD LOGIC (Append Bar) ---
magick "%~1" ^
    ^( -clone 0 -set option:width %%w -background "!USER_BACKGROUND!" -font "!USER_FONT!" -pointsize !FONT_SIZE! -fill "!USER_TEXT_COLOR!" -stroke "!USER_STROKE_COLOR!" -strokewidth !USER_STROKE_WIDTH! -gravity center -size "%%[width]x" caption:"!CAPTION!" -bordercolor "!USER_BACKGROUND!" -border !TEXT_PADDING!x!TEXT_PADDING! ^) ^
    -delete 0 -reverse -append -gravity north -splice 0x%TOP_SPACE% ^
    "!outputFile!"
goto :CheckResult

:: --- NEW LOGIC (Overlay Text) ---
:RenderOverlay
magick "%~1" ^
    -font "!USER_FONT!" -pointsize !FONT_SIZE! ^
    -fill "!USER_TEXT_COLOR!" ^
    -stroke "!USER_STROKE_COLOR!" -strokewidth !USER_STROKE_WIDTH! ^
    -gravity !USER_GRAVITY! ^
    -annotate +0+20 "!CAPTION!" ^
    "!outputFile!"
goto :CheckResult

:CheckResult
if exist "!outputFile!" (echo [SUCCESS] Created: "!outputFile!") else (echo [ERROR] Failed to create image.)
goto :EndScript


:: =================================================================
::                           VIDEO ROUTINE
:: =================================================================
:ProcessVideo
echo.
echo -------------------------------------------------------
echo VIDEO CAPTION SETUP
echo -------------------------------------------------------
set "inputFile=%~1"

:: --- UPDATE: USING BRANDED TIMESTAMP ---
set "uniqueFileName=%~dpn1_captioned_%TIMESTAMP%.mp4"

:: --- 1. Font Setup ---
copy /y "C:\Windows\Fonts\arial.ttf" "%TEMP%\temp_arial.ttf" >nul
set "fontPath=%TEMP%\temp_arial.ttf"

:: --- 2. User Input ---
set "user_text="
set /p "user_text=Enter your caption text: "
if "!user_text!"=="" (echo No text entered. & exit /b)

set /p "boxcolor=Enter background color (default black): "
if "!boxcolor!"=="" set "boxcolor=black"

set /p "boxopacity=Enter background opacity (0.0-1.0, default 1.0): "
if "!boxopacity!"=="" set "boxopacity=1.0"

set /p "fontcolor=Enter text color (default white): "
if "!fontcolor!"=="" set "fontcolor=white"

set /p "fontsize=Enter font size (default 40): "
if "!fontsize!"=="" set "fontsize=40"

echo.
echo === Alignment Options ===
echo 1. Top Left, 2. Top Center, 3. Top Right
echo 4. Bottom Left, 5. Bottom Center, 6. Bottom Right
echo 7. Center
set /p align="Enter alignment number (default 5): "
if "%align%"=="" set align=5

:: --- 3. Set Alignment Logic ---
set "margin=10"
if "!align!"=="1" set "pos=x=%margin%:y=%margin%"
if "!align!"=="2" set "pos=x=(w-text_w)/2:y=%margin%"
if "!align!"=="3" set "pos=x=w-text_w-%margin%:y=%margin%"
if "!align!"=="4" set "pos=x=%margin%:y=h-text_h-%margin%"
if "!align!"=="5" set "pos=x=(w-text_w)/2:y=h-text_h-%margin%"
if "!align!"=="6" set "pos=x=w-text_w-%margin%:y=h-text_h-%margin%"
if "!align!"=="7" set "pos=x=(w-text_w)/2:y=(h-text_h)/2"
if not defined pos set "pos=x=(w-text_w)/2:y=h-text_h-%margin%"

:: --- 4. Prepare Text Variables ---
:: FIX 1: Replace Full-Width Colon (：) with Normal Colon (:) in Batch
set "user_text=!user_text:：=:!"
:: FIX 2: Escape Single Quotes ( ' -> '' ) for PowerShell
set "ps_text=!user_text:'=''!"

:: --- 5. Write Text File Safely ---
set "captionFile=%TEMP%\ffmpeg_text_%RANDOM%.txt"

:: We use the .NET WriteAllText method because it is bulletproof against syntax errors
powershell -NoProfile -Command "$txt = '%ps_text%'; $enc = [System.Text.UTF8Encoding]::new($false); [System.IO.File]::WriteAllText('%captionFile%', $txt, $enc)"

set "filterScriptFile=%TEMP%\ffmpeg_filter_%RANDOM%.txt"

:: Prepare paths (Escape backslashes and colons for FFmpeg)
set "safeCaptionFile=!captionFile:\=/!"
set "safeCaptionFile=!safeCaptionFile::=\:!"
set "safeFontPath=!fontPath:\=/!"
set "safeFontPath=!safeFontPath::=\:!"

:: --- 6. Construct Filter Command ---
set "filter_cmd=drawtext=textfile='!safeCaptionFile!':"
set "filter_cmd=!filter_cmd!fontfile='!safeFontPath!':"
set "filter_cmd=!filter_cmd!fontsize=!fontsize!:"
set "filter_cmd=!filter_cmd!fontcolor=!fontcolor!:"
set "filter_cmd=!filter_cmd!!pos!:"
set "filter_cmd=!filter_cmd!box=1:boxcolor=!boxcolor!@!boxopacity!:boxborderw=10"

:: Write filter to file
(echo !filter_cmd!) > "!filterScriptFile!"

:: --- 7. Execute FFmpeg ---
echo.
echo Processing Video... please wait.
echo Input:  %~nx1
echo Output: %~nx1_captioned_%TIMESTAMP%.mp4

:: Use -/filter_complex to avoid path warnings
ffmpeg -v error -stats -i "%inputFile%" -/filter_complex "!filterScriptFile!" -c:a aac "%uniqueFileName%"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] FFMPEG FAILED!
) else (
    echo.
    echo [SUCCESS] Created: "%uniqueFileName%"
)

:: Cleanup
if exist "!captionFile!" del "!captionFile!"
if exist "!filterScriptFile!" del "!filterScriptFile!"
if exist "%TEMP%\temp_arial.ttf" del "%TEMP%\temp_arial.ttf"
goto :EndScript

:: =================================================================
::                           END SCRIPT
:: =================================================================
:EndScript
echo.
echo =======================================================
echo   PROCESS FINISHED.
echo =======================================================
pause
exit /b 0