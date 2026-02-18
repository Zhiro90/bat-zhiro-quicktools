@echo off
setlocal enabledelayedexpansion

:: =================================================================
:: CONFIGURATION & BRANDING
:: =================================================================
set "TOOL_NAME=Zhiro Quick Tools"
set "TOOL_VERSION=1.0"
set "SCRIPT_NAME=PDF OCR Enabler"
set "SCRIPT_VERSION=2.0"

:: 1. GENERATE TIMESTAMP (YYYY-MM-DD_HHMM)
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "dt=%%I"
set "TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%%dt:~10,2%"

:: =================================================================
:: 2. PRE-FLIGHT CHECKS
:: =================================================================
echo [Checking Dependencies...]

:: Check for Python
where python >nul 2>&1 || (
    echo [ERROR] Python not found in PATH.
    echo Please install Python to use this tool.
    pause
    exit /b 1
)

:: Check for OCRmyPDF module
python -c "import ocrmypdf" >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] 'ocrmypdf' module not found.
    echo Please run: pip install ocrmypdf
    pause
    exit /b 1
)

:: Check Input
if "%~1"=="" (
    echo [ERROR] No input file provided.
    echo Please drag and drop a PDF file onto this script.
    pause
    exit /b 1
)

:: =================================================================
:: 3. PROCESSING
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
set "output=%~dpn1_ocr_%TIMESTAMP%.pdf"

:: OCR Settings (Preserved from original)
:: -l eng+spa+fra : Languages
:: --rotate-pages : Fix orientation
:: --optimize 1   : Linearize PDF
:: --force-ocr    : Rasterize vector text if needed
:: --jobs 4       : Multithreading
set "ARGS=-l eng+spa+fra --rotate-pages --optimize 1 --force-ocr --jobs 4"

echo [INFO] Starting OCR process...
echo        This may take a while depending on page count.
echo.

:: Execute via Python Module
python -m ocrmypdf %ARGS% "%input%" "%output%"

echo.
echo =======================================================
if %errorlevel% neq 0 (
    echo   [ERROR] OCR process failed.
) else (
    echo   SUCCESS.
    echo   Created: "%~n1_ocr_%TIMESTAMP%.pdf"
)
echo =======================================================

pause
exit /b