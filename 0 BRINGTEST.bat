@echo off
setlocal

:: =================================================================
::               Script Copier and Renamer (V2)
:: =================================================================
:: This script copies a predefined source file to its own location
:: and renames it based on user input, automatically adding .bat.
:: =================================================================

:: --- CONFIGURATION ---
:: Set the full, absolute path to the source file you want to copy.
set "sourceFile=C:\Users\Zhiro\AppData\Roaming\Microsoft\Windows\SendTo\TEST.bat"

:: --- 1. VERIFY SOURCE FILE EXISTS ---
if not exist "%sourceFile%" (
    echo ERROR: The source file could not be found at the specified path.
    echo.
    echo Path: %sourceFile%
    echo.
    echo Please check the path in the script and try again.
    pause
    goto :eof
)

:: --- 2. PROMPT FOR NEW FILENAME ---
cls
echo This utility will copy a template script to the current folder.
echo Source: %sourceFile%
echo.
set /p "newFilename=Enter a base name for the new script (the .bat extension will be added): "

:: --- 3. VALIDATE USER INPUT ---
if not defined newFilename (
    echo.
    echo No name was entered. Operation cancelled.
    pause
    goto :eof
)

:: --- 4. PERFORM THE COPY ---
:: %~dp0 is a special variable that expands to the drive and path of the current script.
:: The .bat extension is now added automatically.
set "destinationPath=%~dp0%newFilename%.bat"

echo.
echo Copying to: %destinationPath%
copy "%sourceFile%" "%destinationPath%" > nul

:: --- 5. VERIFY THE RESULT ---
if exist "%destinationPath%" (
    echo.
    echo SUCCESS!
    echo The script has been created at: %destinationPath%
) else (
    echo.
    echo ERROR: The file could not be copied. Please check permissions.
)

echo.
pause
goto :eof