@echo off
setlocal enabledelayedexpansion

:: =================================================================
:: CONFIGURATION & BRANDING
:: =================================================================
set "TOOL_NAME=Zhiro Quick Tools"
set "TOOL_VERSION=1.0"
set "SCRIPT_NAME=Universal Image Converter"
set "SCRIPT_VERSION=1.0"

:: 1. GENERATE TIMESTAMP (YYYY-MM-DD_HHMM)
:: We use WMIC to get a region-independent date format
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "dt=%%I"
set "TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%%dt:~10,2%"

:: 2. CHECK DEPENDENCIES
where magick >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] ImageMagick not found. Please install it.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo [ERROR] No files provided. 
    echo Please drag and drop image files onto this script icon.
    pause
    exit /b 1
)

:: 3. UI & MENU
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
echo   [0] PNG  (Transparent, Best Quality) [Default]
echo   [1] WebP (Web optimized, Quality 95)
echo   [2] ICO  (Multi-resolution icon)
echo   [3] JPG  (Compressed, Quality 80)
echo.

set "choice="
set /p choice="Enter choice [0-3]: "
if not defined choice set "choice=0"

echo.
echo -------------------------------------------------------
echo STARTING CONVERSION...
echo -------------------------------------------------------
echo.

:: 4. PROCESSING LOOP
for %%F in (%*) do (
    set "filename=%%~nxF"
    
    :: Construct Output Name: OriginalName_YYYY-MM-DD_HHMM
    :: This ensures uniqueness as requested.
    set "outPath=%%~dpnF_%TIMESTAMP%"
    
    echo Processing: "!filename!"

    if "%choice%"=="0" call :ConvertToPng "%%~F" "!outPath!"
    if "%choice%"=="1" call :ConvertToWebp "%%~F" "!outPath!"
    if "%choice%"=="2" call :ConvertToIco "%%~F" "!outPath!"
    if "%choice%"=="3" call :ConvertToJpg "%%~F" "!outPath!"
)

:: 5. FINISH
echo.
echo =======================================================
echo   ALL TASKS COMPLETE.
echo =======================================================
pause
goto :eof


:: =============================================================
:: SUBROUTINES
:: =============================================================

:ConvertToPng
:: %1 = Input File, %2 = Output Base Name (includes timestamp)
magick "%~1" -quiet -alpha on -background none -quality 100 "%~2.png"
if !errorlevel! equ 0 (
    echo    - Success: Saved as PNG
) else (
    echo    - ERROR: Failed to convert PNG
)
goto :eof

:ConvertToWebp
magick "%~1" -quality 95 -define webp:lossless=false "%~2.webp"
if !errorlevel! equ 0 (
    echo    - Success: Saved as WebP
) else (
    echo    - ERROR: Failed to convert WebP
)
goto :eof

:ConvertToIco
magick "%~1" -background none ^
    ( -clone 0 -resize 16x16   -gravity center -extent 16x16   ) ^
    ( -clone 0 -resize 32x32   -gravity center -extent 32x32   ) ^
    ( -clone 0 -resize 48x48   -gravity center -extent 48x48   ) ^
    ( -clone 0 -resize 64x64   -gravity center -extent 64x64   ) ^
    ( -clone 0 -resize 128x128 -gravity center -extent 128x128 ) ^
    ( -clone 0 -resize 256x256 -gravity center -extent 256x256 ) ^
    -delete 0 -alpha on ^
    "%~2.ico"

if !errorlevel! equ 0 (
    echo    - Success: Saved as ICO
) else (
    echo    - ERROR: Failed to convert ICO
)
goto :eof

:ConvertToJpg
:: Flatten onto white background to handle transparency correctly
magick "%~1" -background white -flatten -quality 80 "%~2.jpg"
if !errorlevel! equ 0 (
    echo    - Success: Saved as JPG
) else (
    echo    - ERROR: Failed to convert JPG
)
goto :eof