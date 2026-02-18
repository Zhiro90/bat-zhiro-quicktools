@echo off
setlocal enabledelayedexpansion

:: =================================================================
:: CONFIGURATION & BRANDING
:: =================================================================
set "TOOL_NAME=Zhiro Quick Tools"
set "TOOL_VERSION=1.0"
set "SCRIPT_NAME=RECOMIC (Universal Round-Trip Converter)"
set "SCRIPT_VERSION=2.1"

:: 1. GENERATE TIMESTAMP
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "dt=%%I"
set "TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%%dt:~10,2%"

:: =================================================================
:: 2. PRE-FLIGHT CHECKS
:: =================================================================
echo [Checking Dependencies...]

where 7z >nul 2>&1 || (
    echo [ERROR] 7-Zip not found in PATH.
    pause
    exit /b 1
)

where magick >nul 2>&1 || (
    echo [ERROR] ImageMagick not found in PATH.
    pause
    exit /b 1
)

set "HAS_PDFTOTEXT=0"
where pdftotext >nul 2>&1
if %errorlevel% equ 0 set "HAS_PDFTOTEXT=1"

if "%~1"=="" (
    echo [ERROR] No input file provided.
    echo Please drag and drop a Comic or PDF file onto this script.
    pause
    exit /b 1
)

:: =================================================================
:: 3. ROUTING LOGIC
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

set "input=%~1"
set "ext=%~x1"
set "file_dir=%~dp1"
set "base_name=%~n1"

:: Routing based on extension
if /I "%ext%"==".pdf" goto :MODE_PDF_TO_ARCHIVE
if /I "%ext%"==".cbz" goto :MODE_ARCHIVE_TO_PDF
if /I "%ext%"==".cbr" goto :MODE_ARCHIVE_TO_PDF
if /I "%ext%"==".cb7" goto :MODE_ARCHIVE_TO_PDF
if /I "%ext%"==".zip" goto :MODE_ARCHIVE_TO_PDF
if /I "%ext%"==".rar" goto :MODE_ARCHIVE_TO_PDF

echo [ERROR] Unsupported format: %ext%
pause
exit /b 1

:: =================================================================
:: MODE A: COMIC -> PDF (Compile)
:: =================================================================
:MODE_ARCHIVE_TO_PDF
echo [MODE] Comic Archive to PDF.
set "final_output=%file_dir%%base_name%_%TIMESTAMP%.pdf"
set "temp_dir=%file_dir%%base_name%_temp_%TIMESTAMP%"
set "imglist=%temp_dir%\imglist.txt"

echo [INFO] Extracting archive...
if exist "%temp_dir%" rd /s /q "%temp_dir%"
mkdir "%temp_dir%"

7z e -o"%temp_dir%" -y "%input%" >nul
if %errorlevel% neq 0 (
    echo [ERROR] Extraction failed.
    goto :CLEANUP
)

pushd "%temp_dir%"
echo [INFO] Indexing images...
(
    for /f "delims=" %%f in ('dir /b /a-d *.jpg *.jpeg *.png *.webp *.bmp 2^>nul ^| sort') do (
        echo %%f
    )
) > "imglist.txt"

:: Verify image count
set count=0
for /f "usebackq delims=" %%f in ("imglist.txt") do set /a count+=1

if %count% lss 1 (
    echo [ERROR] No valid images found.
    popd
    goto :CLEANUP
)

echo [INFO] Compiling PDF (%count% pages)...
magick @"imglist.txt" -quality 85 -density 150 -units pixelsperinch "%final_output%"

popd
goto :FINISH_CHECK

:: =================================================================
:: MODE B: PDF -> COMIC (Decompile to ZIP)
:: =================================================================
:MODE_PDF_TO_ARCHIVE
echo [MODE] PDF to Comic Archive (ZIP).
set "final_output=%file_dir%%base_name%_%TIMESTAMP%.zip"
set "temp_dir=%file_dir%%base_name%_temp_%TIMESTAMP%"

if exist "%temp_dir%" rd /s /q "%temp_dir%"
mkdir "%temp_dir%"

echo [INFO] Rasterizing pages (This may take time)...
magick -density 150 "%input%" -quality 85 "%temp_dir%\page_%%04d.jpg"

if %errorlevel% neq 0 (
    echo [ERROR] Rasterization failed.
    goto :CLEANUP
)

:: Optional OCR Extraction
if "%HAS_PDFTOTEXT%"=="1" (
    echo [INFO] Extracting text layer (OCR)...
    pdftotext "%input%" "%temp_dir%\_ocr_content.txt"
)

echo [INFO] Archiving to ZIP...
7z a -tzip "%final_output%" "%temp_dir%\*" >nul

goto :FINISH_CHECK

:: =================================================================
:: FINISH & CLEANUP
:: =================================================================
:FINISH_CHECK
echo.
echo =======================================================
if exist "%final_output%" (
    echo   SUCCESS.
    echo   Created: "%~n1_%TIMESTAMP%%~x1" -> Output
) else (
    echo   ERROR: Output file not found.
)
echo =======================================================

:CLEANUP
echo [INFO] Cleaning up temp files...
if exist "%temp_dir%" rd /s /q "%temp_dir%" 2>nul

:: FIX: Explicitly remove the phantom 'output' file if it exists
if exist "output" del "output"

pause
exit /b