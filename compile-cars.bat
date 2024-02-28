@echo off
set datebeg=%date%
set timest=%time%
scripts\clean-lng.pl
if ERRORLEVEL 1 goto :EOF
cd lang 
start /min ..\scripts\MonaLisa.pl 
cd ..

if /i "%1" == "selfconfig" goto :SelfConfig
if /i "%1" == "gethgrev" goto :GetHgRev
if /i "%1" == "writecustomtags" goto :WriteCustomTags
::if /i "%1" == "echoparams" goto :EchoParams
if /i "%1" == "cleanup" goto :Cleanup

::gcc -v --help
::gcc -C -E -P -o %NMLNAME%.nml - <src/%NMLNAME%.pnml
::gcc -C -E -P - <src/%NMLNAME%.pnml>%NMLNAME%.nml

::: параметры для набора
call :SelfConfig
:: параметры пользователя
call ..\config user

:: задаём переменные окружения
set PATH=%PATHMINGW%;%PATHNML%;%PATHTHG%;%PATH%

:: определяем текущую ревизию
call :GetHgRev

:: если MIN_COMPATIBLE_REVISION == 0, используем REPO_REVISION
if "%MIN_COMPATIBLE_REVISION%" == "0" ^
  set MIN_COMPATIBLE_REVISION=%REPO_REVISION%

:::call :EchoParams
:::exit
:: создаём файл custom_tags
call :WriteCustomTags>%CUSTOM_TAGS%

:: собираем
:: -E            Stop after the preprocessing stage;
::               do not run the compiler proper.
:: -C            Tell the preprocessor not to discard comments.
::               Used with the `-E' option.
:: -P            без служебного вывода
:: -x c          считаем исходные файлы написанными на Си
:: -o filename   результат записываем в файл
:: -D amacro=defn Define macro amacro as defn.
gcc -D REPO_REVISION=%REPO_REVISION% ^
  -D MIN_COMPATIBLE_REVISION=%MIN_COMPATIBLE_REVISION% ^
  -E -C -P -x c -o %NMLNAME%.nml %NMLNAME%.pnml
if /i not %errorlevel% == 0 goto :Error
:: компилируем
scripts\change.pl xussr-cars.nml "\s*\{\s*" "\n\{\n  "
scripts\change.pl xussr-cars.nml "\s*\}\s*" "\n\}\n"
scripts\change.pl xussr-cars.nml "\;" "\;\n"
scripts\change.pl xussr-cars.nml "\n\r*\n" "\n"
scripts\change.pl xussr-cars.nml "\{\s*([a-z0-9_ ]+);\s*\}" "{ $1; }"

del xussr-cars.bak
nmlc --grf=%NMLNAME%.grf %NMLCOPTION% %NMLNAME%.nml
if /i not %errorlevel% == 0 goto :Error
:: копируем, если задан путь
if /i not "%GRFFOLDER%" == "" (
  xcopy /y %NMLNAME%.grf "%GRFFOLDER%"
  if /i not %errorlevel% == 0 goto :Error
:: выкладывать файл сборки в папку с именем ветки, имя ветки брать в .git/HEAD в строке вида ref: refs/heads/main где main имя ветки
  scripts\copy-branch.pl %NMLNAME%.grf 
  if /i not %errorlevel% == 0 goto :Error
)

echo [Ok]
set compres=[Ok]
goto :END
:Error
echo [ERR]
set compres=[Err]
goto :END

:: GetHgRev
:GetHgRev

:: определяем текущую ревизию
for /F %%i in (%YDPATH%\My\-todelete\xUSSRset\%NMLNAME%.ver) do set REPO_REVISION=%%i
set /a REPO_REVISION=%REPO_REVISION%+1
echo %REPO_REVISION%>%YDPATH%\My\-todelete\xUSSRset\%NMLNAME%.ver

goto :EOF

:: WriteCustomTags
:WriteCustomTags
echo VERSION  :%REPO_REVISION%
echo MIN_COMPATIBLE_REVISION:%MIN_COMPATIBLE_REVISION%
echo TITLE    :xUSSR Railway Cars Set 0.8.1.r%REPO_REVISION%
echo FILENAME :%NMLNAME%.grf
goto :EOF

:: SelfConfig
:SelfConfig
:: имя файла с набором
set NMLNAME=xussr-cars
:: имя служебного файла для сборки
set CUSTOM_TAGS=custom_tags.txt
:: минимальная совместимая ревизия
set MIN_COMPATIBLE_REVISION=1
goto :EOF

:EchoParams
echo --------------
echo NMLNAME=%NMLNAME%
echo CUSTOM_TAGS=%CUSTOM_TAGS%
echo MIN_COMPATIBLE_REVISION=%MIN_COMPATIBLE_REVISION%
echo REPO_REVISION=%REPO_REVISION%
echo NMLCOPTION=%NMLCOPTION%
echo GRFFOLDER=%GRFFOLDER%
echo PATHMINGW=%PATHMINGW%
echo PATHNML=%PATHNML%
echo PATHTHG=%PATHTHG%
echo PATH7Z=%PATH7Z%
echo --------------
goto :EOF

:: очистка папки от рабочих файлов по команде "compile cleanup"
:Cleanup
call :SelfConfig
del /q /f %NMLNAME%.grf.cache %NMLNAME%.grf.cacheindex %NMLNAME%.grf ^
  %NMLNAME%.nfo %NMLNAME%.nml %NMLNAME%_optimized.nml parsetab.py ^
  custom_tags.txt %NMLNAME%_dep.txt
goto :EOF

:END
set timefin=%time%
set timest=%timest:~0,8%
set timefin=%timefin:~0,8%
set timest=%timest: =0%
set timefin=%timefin: =0%
set /a gettick1=(1%timest:~6,2%-100)+(1%timest:~3,2%-100)*60+(1%timest:~0,2%-100)*3600
set /a gettick2=(1%timefin:~6,2%-100)+(1%timefin:~3,2%-100)*60+(1%timefin:~0,2%-100)*3600
set /a timetot=gettick2-gettick1
set /a timetot1=timetot-(timetot/60)*60
set timetot1=0%timetot1%
set timetot1=%timetot1:~-2%
set /a timetot=timetot/60
set /a timetot2=timetot-(timetot/60)*60
set timetot2=0%timetot2%
set timetot2=%timetot2:~-2%
set /a timetot=timetot/60
set /a timetot3=timetot-(timetot/24)*24
set timetot3=0%timetot3%
set timetot3=%timetot3:~-2%
rem более 24 часов не считает
echo Total time: %timetot3%:%timetot2%:%timetot1%
echo %datebeg% %timefin% - %timetot3%:%timetot2%:%timetot1% %compres%>>compile.stat

cd src 
start /min ..\scripts\MonaLisa.pl 
cd ..

:EOF
