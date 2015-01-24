@echo off
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
call config user

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
nmlc --grf=%NMLNAME%.grf %NMLCOPTION% %NMLNAME%.nml
if /i not %errorlevel% == 0 goto :Error
:: копируем, если задан путь
if /i not "%GRFFOLDER%" == "" (
  xcopy /y %NMLNAME%.grf "%GRFFOLDER%\"
  if /i not %errorlevel% == 0 goto :Error
)
echo [Ok]
goto :EOF
:Error
echo [ERR]
goto :EOF

:: GetHgRev
:GetHgRev

:: определяем текущую ревизию
for /F %%i in ('hg id -n') do set REPO_REVISION=%%i

:: убираем +, если он есть
if "%REPO_REVISION:~-1%" == "+" set REPO_REVISION=%REPO_REVISION:~0,-1%

goto :EOF

:: WriteCustomTags
:WriteCustomTags
echo VERSION  :%REPO_REVISION%
echo MIN_COMPATIBLE_REVISION:%MIN_COMPATIBLE_REVISION%
echo TITLE    :xUSSR Railway Set 0.3.r%REPO_REVISION%
echo FILENAME :%NMLNAME%.grf
goto :EOF

:: SelfConfig
:SelfConfig
:: имя файла с набором
set NMLNAME=xussr
:: имя служебного файла для сборки
set CUSTOM_TAGS=custom_tags.txt
:: минимальная совместимая ревизия
set MIN_COMPATIBLE_REVISION=496
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
