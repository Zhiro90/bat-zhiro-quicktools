@echo off
setlocal ENABLEDELAYEDEXPANSION
set fName=%1
set ffmpeg="ffmpeg.exe"
 
for /f "tokens=* delims= " %%F in ('echo %fName%') do (
ffmpeg.exe -i "%%~fF" -ab 320k "%%~dpnF.mp3"
)