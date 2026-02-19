@echo off
setlocal enabledelayedexpansion

:: =================================================================
:: CONFIGURATION & BRANDING
:: =================================================================
set "TOOL_NAME=Zhiro Quick Tools"
set "TOOL_VERSION=1.0"
set "SCRIPT_NAME=Smart Image Joiner"
set "SCRIPT_VERSION=2.0"

:: === CONFIG ===
:: Keep working directory as script location for the "Coordinator" logic to work
set "workdir=%~dp0"
set "controlfile=%workdir%imdone.imdone"

:: 1. GENERATE TIMESTAMP (YYYY-MM-DD_HHMM)
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "dt=%%I"
set "TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%%dt:~10,2%"

:: Get PID for temp file uniqueness
for /f %%a in ('powershell -nop -c "$PID"') do set "mypid=%%a"

echo [DEBUG] Script Started
echo [DEBUG] PID: %mypid%
echo [DEBUG] Batch ID: %TIMESTAMP%

:: Create Unique Temp File for this instance
set "tempfile=%workdir%route_%TIMESTAMP%_PID%mypid%_%RANDOM%.joinvert"
echo [DEBUG] Temp File: %tempfile%
echo %~1 > "%tempfile%"

if not exist "%tempfile%" (
    echo [ERROR] Could not write temp file. Check permissions.
    pause
    exit /b 1
)

:: =================================================================
:: COORDINATOR LOGIC (The "Caveman" Logic)
:: =================================================================

:: Check if a Coordinator already exists
if exist "%controlfile%" (
    echo [DEBUG] Coordinator already active. Passing data and closing.
    :: We just exit, leaving our temp file for the coordinator to pick up
    exit /b 0
)

:: Become the Coordinator
echo done > "%controlfile%"
echo [DEBUG] I am the COORDINATOR.
echo [DEBUG] Waiting for other instances...

:: Wait for other windows to write their files
timeout /t 2 >nul

:: =================================================================
:: COLLECTION PHASE
:: =================================================================
cls
echo =======================================================
echo   %TOOL_NAME% v%TOOL_VERSION%
echo   %SCRIPT_NAME% v%SCRIPT_VERSION%
echo =======================================================
echo.
echo [DEBUG] Collecting paths...

set "temp_list=%workdir%__list.tmp"
set "sorted_list=%workdir%__sorted.tmp"
del "%temp_list%" "%sorted_list%" 2>nul

:: Gather all .joinvert files in the directory
for %%F in ("%workdir%*.joinvert") do (
    for /f "usebackq tokens=*" %%A in ("%%F") do (
        echo %%~A>>"%temp_list%"
        echo    - Found: %%~nxA
    )
)

:: Sort unique paths to handle duplicates
echo [DEBUG] Sorting and cleaning list...
sort /unique "%temp_list%" > "%sorted_list%"

set "file_list="
for /f "usebackq delims=" %%Z in ("%sorted_list%") do (
    set "file_list=!file_list! "%%~Z""
)

if "!file_list!"=="" (
    echo [ERROR] File list is empty.
    del "%controlfile%"
    pause
    exit /b 1
)

:: Extract source directory from the first file
for /f "usebackq delims=" %%Z in ("%sorted_list%") do (
    for %%D in ("%%Z") do set "srcDir=%%~dpD"
    goto :GOT_SRC
)
:GOT_SRC

echo [DEBUG] Source Dir: %srcDir%

:: =================================================================
:: USER MENU
:: =================================================================
echo.
echo SELECT JOIN MODE:
echo.
echo   [1] Vertical   (Append Bottom) [Default]
echo   [2] Horizontal (Append Right)
echo.

set "joinmode=V"
set /p "mode=Choice: "

if "%mode%"=="2" (
    set "joinmode=H"
    echo [INFO] Selected: HORIZONTAL
) else (
    set "joinmode=V"
    echo [INFO] Selected: VERTICAL
)

:: Output Filename
set "output=%srcDir%Joined_Image_%TIMESTAMP%.png"

:: =================================================================
:: CALCULATION & PROCESSING
:: =================================================================

if "%joinmode%"=="V" (
    :: === VERTICAL ===
    echo [DEBUG] Calculating Max Width...
    set maxw=0

    for /f "usebackq delims=" %%Z in ("%sorted_list%") do (
        for /f %%A in ('magick identify -format "%%w" "%%Z" 2^>nul') do (
            if %%A GTR !maxw! set maxw=%%A
        )
    )

    echo [DEBUG] Max Width: !maxw!
    set "resize_cmd=-resize !maxw!x"
    set "append_cmd=-append"

) else (
    :: === HORIZONTAL ===
    echo [DEBUG] Calculating Max Height...
    set maxh=0

    for /f "usebackq delims=" %%Z in ("%sorted_list%") do (
        for /f %%A in ('magick identify -format "%%h" "%%Z" 2^>nul') do (
            if %%A GTR !maxh! set maxh=%%A
        )
    )

    echo [DEBUG] Max Height: !maxh!
    set "resize_cmd=-resize x!maxh!"
    set "append_cmd=+append"
)

:: =================================================================
:: EXECUTION
:: =================================================================
echo.
echo -------------------------------------------------------
echo JOINING IMAGES...
echo -------------------------------------------------------

magick !file_list! %resize_cmd% -background none -gravity center %append_cmd% "%output%" 2>nul

echo.
echo =======================================================
if exist "%output%" (
    echo   SUCCESS.
    echo   File: "%output%"
) else (
    echo   ERROR: ImageMagick failed.
)
echo =======================================================

:: =================================================================
:: CLEANUP
:: =================================================================
echo [DEBUG] Cleaning temp files...

:: Loop delete to ensure file locks are released
for /l %%C in (1,1,10) do (
    del "%workdir%*.joinvert" 2>nul
    del "%controlfile%" 2>nul
    del "%temp_list%" "%sorted_list%" 2>nul
)

pause
exit /b 0