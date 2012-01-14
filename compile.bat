@echo off
::gcc -v --help
::gcc -C -E -P -o %NMLNAME%.nml - <src/%NMLNAME%.pnml
::gcc -C -E -P - <src/%NMLNAME%.pnml>%NMLNAME%.nml

:: задаём переменные окружения
call config setup

:: определяем текущую ревизию
for /F %%i in ('hg id -n') do set REPO_REVISION=%%i

:: убираем +, если он есть
if "%REPO_REVISION:~-1%" == "+" set REPO_REVISION=%REPO_REVISION:~0,-1%

:: если MIN_COMPATIBLE_REVISION == 0, используем REPO_REVISION
if "%MIN_COMPATIBLE_REVISION%" == "0" ^
  set MIN_COMPATIBLE_REVISION=%REPO_REVISION%

:: создаём файл custom_tags
echo VERSION  :%REPO_REVISION%>%CUSTOM_TAGS%
echo MIN_COMPATIBLE_REVISION:%MIN_COMPATIBLE_REVISION%>>%CUSTOM_TAGS%
echo TITLE    :xUSSR Railway Set 1.0.%REPO_REVISION% Alpha>>%CUSTOM_TAGS%
echo FILENAME :xussr.grf>>%CUSTOM_TAGS%

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
  -E -C -P -x c -o %NMLNAME%.nml src/%NMLNAME%.pnml
if /i not %errorlevel% == 0 goto :Error
:: компилируем
nmlc --nfo=%NMLNAME%.nfo --grf=%NMLNAME%.grf ^
  -M --MF=%NMLNAME%_dep.txt %NMLNAME%.nml
:: --nml=%NMLNAME%_optimized.nml
if /i not %errorlevel% == 0 goto :Error
:: копируем
xcopy /y %NMLNAME%.grf "%GRFFOLDER%\"
if /i not %errorlevel% == 0 goto :Error
echo [Ok]
goto :EOF
:Error
echo [ERR]
