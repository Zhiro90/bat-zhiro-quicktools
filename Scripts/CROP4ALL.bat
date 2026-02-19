@echo off
setlocal EnableDelayedExpansion

:: =================================================================
:: CONFIGURATION & BRANDING
:: =================================================================
set "TOOL_NAME=Zhiro Quick Tools"
set "TOOL_VERSION=1.0"
set "SCRIPT_NAME=Smart Crop & Fill"
set "SCRIPT_VERSION=3.5"

:: 1. GENERATE TIMESTAMP (YYYY-MM-DD_HHMM)
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "dt=%%I"
set "TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%%dt:~10,2%"

:: =================================================================
:: 2. FILE VALIDATION
:: =================================================================
if "%~1"=="" (
    echo [ERROR] Drag and drop a file onto the script.
    pause
    exit /b
)

set "file_path=%~1"
set "file_ext=%~x1"
set "file_name=%~n1"
set "file_dir=%~dp1"
set "file_type=unknown"

:: Detect file type
for %%E in (.jpg .jpeg .png .gif .bmp .webp .tif .tiff .heic .avif) do if /I "%%E"=="!file_ext!" set "file_type=image"

if "!file_type!"=="unknown" (
    for %%E in (.mp4 .mkv .avi .mov .wmv .flv .webm .mpg .mpeg .ts .vob) do if /I "%%E"=="!file_ext!" set "file_type=video"
)

if "!file_type!"=="unknown" (
    echo Unsupported file type: !file_ext!
    pause & exit /b
)

:: =================================================================
:: 3. SMART MENU
:: =================================================================
cls
echo =======================================================
echo   %TOOL_NAME% v%TOOL_VERSION%
echo   %SCRIPT_NAME% v%SCRIPT_VERSION%
echo =======================================================
echo.
echo Input File: "%~nx1"
echo Batch ID:   %TIMESTAMP%
echo Type:       !file_type!
echo.

if "!file_type!"=="video" goto :MENU_VIDEO
if "!file_type!"=="image" goto :MENU_IMAGE

:MENU_VIDEO
echo VIDEO MODE (Manual Crop Only)
echo.
echo   Enter the percentage to crop from TOP
echo   or press [Enter] to leave at 0 and configure other sides.
echo.
echo --------------------------------------------------------
set /p user_input="Top Percentage (0-100): "
if "!user_input!"=="" set "user_input=0"

:: Validation: Video does not support letter presets
echo !user_input!| findstr /r "[a-z]" >nul
if !errorlevel! equ 0 (
    echo.
    echo [ERROR] Presets -letters- are not available for video.
    echo Please enter numbers only.
    pause
    exit /b
)
goto :MANUAL_LOGIC

:MENU_IMAGE
echo IMAGE MODE (Manual or Presets)
echo.
echo   [Enter] = Manual (0%%)    [a] = 16:9   [c] = 2:3
echo   [Number]= Manual (%%)     [b] = 9:16   [d] = 1:1
echo.
echo --------------------------------------------------------
set /p user_input="Choice (%% Top or Letter): "
if "!user_input!"=="" set "user_input=0"

:: If letter input, go to presets
if /I "!user_input!"=="a" goto :PRESET_SETUP
if /I "!user_input!"=="b" goto :PRESET_SETUP
if /I "!user_input!"=="c" goto :PRESET_SETUP
if /I "!user_input!"=="d" goto :PRESET_SETUP

:: If number input, go to manual logic
goto :MANUAL_LOGIC


:: =========================================================
:: PRESETS (IMAGE ONLY)
:: =========================================================
:PRESET_SETUP
if /I "!user_input!"=="a" set "ratio_name=16:9"
if /I "!user_input!"=="b" set "ratio_name=9:16"
if /I "!user_input!"=="c" set "ratio_name=2:3"
if /I "!user_input!"=="d" set "ratio_name=1:1"

echo.
echo You chose preset !ratio_name!
echo [1] FILL (Fill with black background - No image cut)
echo [2] CROP (Crop to fill - Cuts image)
set /p fill_crop="Choose option (1 or 2): "

if "!fill_crop!"=="1" goto :EXECUTE_FILL
goto :EXECUTE_CROP

:: =========================================================
:: EXECUTE FILL (IMAGEMAGICK)
:: =========================================================
:EXECUTE_FILL
:: UPDATE: Added Timestamp
set "output_file=!file_dir!!file_name!_fill_!ratio_name::=x!_%TIMESTAMP%!file_ext!"
echo Processing FILL !ratio_name!...

if "!user_input!"=="a" magick "!file_path!" -gravity center -background black -extent "%%[fx:w/h^<16/9?h*16/9:w]x%%[fx:w/h^<16/9?h:w*9/16]" "!output_file!"
if "!user_input!"=="b" magick "!file_path!" -gravity center -background black -extent "%%[fx:w/h^<9/16?h*9/16:w]x%%[fx:w/h^<9/16?h:w*16/9]" "!output_file!"
if "!user_input!"=="c" magick "!file_path!" -gravity center -background black -extent "%%[fx:w/h^<2/3?h*2/3:w]x%%[fx:w/h^<2/3?h:w*3/2]" "!output_file!"
if "!user_input!"=="d" magick "!file_path!" -gravity center -background black -extent "%%[fx:max(w,h)]x%%[fx:max(w,h)]" "!output_file!"
goto :FIN

:: =========================================================
:: EXECUTE CROP (IMAGEMAGICK)
:: =========================================================
:EXECUTE_CROP
:: UPDATE: Added Timestamp
set "output_file=!file_dir!!file_name!_crop_!ratio_name::=x!_%TIMESTAMP%!file_ext!"
echo Processing CROP !ratio_name!...
magick "!file_path!" -gravity center -crop !ratio_name! +repage "!output_file!"
goto :FIN

:: =========================================================
:: MANUAL MODE (VIDEO & IMAGE)
:: =========================================================
:MANUAL_LOGIC
:: At this point, user_input contains the "TOP" value
set "top_pct=!user_input!"

echo.
set /p bottom_pct="Crop BOTTOM (%%): "
if "!bottom_pct!"=="" set "bottom_pct=0"
set /p left_pct="Crop LEFT (%%): "
if "!left_pct!"=="" set "left_pct=0"
set /p right_pct="Crop RIGHT (%%): "
if "!right_pct!"=="" set "right_pct=0"

echo.
echo Summary: Top:!top_pct! Bottom:!bottom_pct! Left:!left_pct! Right:!right_pct!

if /I "!file_type!"=="video" (
    :: Calculations for FFmpeg
    set "ffmpeg_w=iw*(1-(!left_pct!/100)-(!right_pct!/100))"
    set "ffmpeg_h=ih*(1-(!top_pct!/100)-(!bottom_pct!/100))"
    set "ffmpeg_x=iw*(!left_pct!/100)"
    set "ffmpeg_y=ih*(!top_pct!/100)"
    
    :: UPDATE: Added Timestamp
    set "output_file=!file_dir!!file_name!_manual_crop_%TIMESTAMP%.mp4"
    
    echo Processing video...
    ffmpeg -i "!file_path!" -vf "crop=!ffmpeg_w!:!ffmpeg_h!:!ffmpeg_x!:!ffmpeg_y!" -c:a copy "!output_file!"
)

if /I "!file_type!"=="image" (
    :: Calculations for ImageMagick
    for /F "tokens=1,2 delims=x " %%A in ('magick identify -format "%%wx%%h" "!file_path!"') do (
        set "width=%%A"
        set "height=%%B"
    )
    set /a "crop_left=!width! * !left_pct! / 100"
    set /a "crop_right=!width! * !right_pct! / 100"
    set /a "crop_top=!height! * !top_pct! / 100"
    set /a "crop_bottom=!height! * !bottom_pct! / 100"
    set /a "new_width=!width! - !crop_left! - !crop_right!"
    set /a "new_height=!height! - !crop_top! - !crop_bottom!"
    
    :: UPDATE: Added Timestamp
    set "output_file=!file_dir!!file_name!_manual_crop_%TIMESTAMP%!file_ext!"
    
    echo Processing image...
    magick "!file_path!" -crop !new_width!x!new_height!+!crop_left!+!crop_top! +repage "!output_file!"
)

:FIN
echo.
if exist "!output_file!" (
    echo [SUCCESS] File created: "%output_file%"
) else (
    echo [ERROR] File was not generated.
)
pause