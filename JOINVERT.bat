@echo off
setlocal

:: =================================================================
:: Zhiro Quick Tools - Smart Image Joiner (Launcher)
:: =================================================================

powershell -ExecutionPolicy Bypass -File "%~dp0JoinVert.ps1" %*