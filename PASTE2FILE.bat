@echo off
setlocal

:: 1. Si se pasa un argumento (la carpeta donde hiciste click), ir a ella.
:: Esto es crucial para que el archivo se guarde donde diste el click derecho.
if not "%~1"=="" pushd "%~1"

:: 2. Generar nombre de archivo con fecha y hora para no sobrescribir
:: Formato: Portapapeles_AAAA-MM-DD_HH-MM-SS.txt
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set "fecha=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%"
set "hora=%datetime:~8,2%-%datetime:~10,2%-%datetime:~12,2%"
set "nombre_archivo=Portapapeles_%fecha%_%hora%.txt"

:: 3. Usar PowerShell para obtener el portapapeles y guardarlo
powershell -NoProfile -Command "Get-Clipboard | Out-File -FilePath '%nombre_archivo%' -Encoding UTF8"

:: (Opcional) Mensaje visual rápido de que se creó (puedes borrar esta línea si quieres que sea silencioso)
:: timeout /t 1 >nul

endlocal