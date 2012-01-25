@echo off
set PATH=C:\MinGW\msys\1.0\bin;C:\Program Files\7-Zip;%PATH%
:: определяем текущую ревизию
for /F %%i in ('hg id -n') do set REPO_REVISION=%%i

:: убираем +, если он есть
if "%REPO_REVISION:~-1%" == "+" set REPO_REVISION=%REPO_REVISION:~0,-1%

:: create grf.7z arhive
7z a xussr.%REPO_REVISION%.grf.7z xussr.grf

:: create src.7z arhive
7z a -r xussr.%REPO_REVISION%.src.7z docs\*.* lang\*.* src\*.*
7z a xussr.%REPO_REVISION%.src.7z *.bat xussr.nfo xussr.nml custom_tags.txt
