@echo off
set PATH=C:\MinGW\msys\1.0\bin;C:\Program Files\7-Zip;%PATH%
:: определяем текущую ревизию
for /F %%i in ('hg id -n') do set REPO_REVISION=%%i

:: убираем +, если он есть
if "%REPO_REVISION:~-1%" == "+" set REPO_REVISION=%REPO_REVISION:~0,-1%

:: имя папки
set TITLE=xussr_railway_set-1.0.%REPO_REVISION%_alpha

:: prepare files
md temp\%TITLE%
copy docs\*.txt temp\%TITLE%\
copy xussr.grf temp\%TITLE%\

cd temp

:: create tar arhive
tar -cf ../%TITLE%.tar *.*

:: cleanup
rd /s /q %TITLE%
cd ..

:: create 7z arhive
set FNAME=xussr.%REPO_REVISION%.tar.7z
7z a %FNAME% %TITLE%.tar

:: cleanup
del /f /q %TITLE%.tar

echo [Ok]
