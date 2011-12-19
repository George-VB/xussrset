@echo off
if /i "%1" == "setup" goto :Setup
:: No valid parameter, no run directly
echo.
echo This file contains configuration information.
echo Do not run directly!
goto :EOF

:: Setup
:Setup
set PATH=C:\MinGW\msys\1.0\bin;C:\MinGW\bin;C:\DOSUtil\Nml3;%PATH%
set NMLNAME=xussr
set GRFFOLDER=%USERPROFILE%\Documents\OpenTTD\content_download\data\my\ecs
