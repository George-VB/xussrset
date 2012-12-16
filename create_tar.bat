@echo off
call compile selfconfig
call config user

:: задаём переменные окружения
set PATH=%PATHMINGW%;%PATH7Z%;%PATHTHG%;%PATH%

:: определяем текущую ревизию
call compile gethgrev

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
