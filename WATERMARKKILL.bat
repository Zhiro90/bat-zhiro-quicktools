@echo off
setlocal EnableDelayedExpansion

rem Ruta al ejecutable
set "TOOL=C:\z\Path\GeminiWatermarkTool.exe"

if not exist "%TOOL%" (
    echo ERROR: No se encontro la herramienta:
    echo %TOOL%
    pause
    exit /b
)

for %%F in (%*) do (
    echo Procesando %%F

    set "OUT=%%~dpnF_clean%%~xF"
    echo Guardando en: !OUT!

    "%TOOL%" -i "%%F" -o "!OUT!"
)

echo Listo.
pause
