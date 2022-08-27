
@echo off
if /i "%1" == "user" goto :User
:: No valid parameter, no run directly
echo.
echo This file contains configuration information.
echo Do not run directly!
echo Файл содержит актуальные для конкретной рабочей станции параметры
echo Перед применением необходимо проверить правильность путей
goto :EOF

:: User
:User

:: Здесь указываются пути к MinGW, nmlc, 7-Zip и TortoiseHg
:: для конкретного пользовательского компьютера

:: путь к MinGW
set PATHMINGW=f:\MinGW\msys\1.0\bin;f:\MinGW\bin
:: путь к NML 0.3
set PATHNML=f:\Utils\nml
:: путь к архиватору 7-Zip
set PATH7Z=C:\Program Files\7-Zip
:: путь к TortoiseHg
set PATHTHG=C:\Program Files\TortoiseHg
:: путь по которому копируется новый .grf после успешной сборки
:: либо пусто, тогда не копируется никуда
set GRFFOLDER=f:\GAMES\OpenTTD\DATA
:: Параметры nmlc: "-c" - вырезать синьку. другие - "nmlc --help"
set NMLCOPTION=-c --nfo=%NMLNAME%.nfo --nml=%NMLNAME%_optimized.nml -M --MF=%NMLNAME%_dep.txt

set YDPATH=F:\Мои_Документы\YandexDisk