@echo off
::gcc -v --help
::gcc -C -E -P -o %NMLNAME%.nml - <src/%NMLNAME%.pnml
::gcc -C -E -P - <src/%NMLNAME%.pnml>%NMLNAME%.nml

:: задаём переменные окружения
call config setup
:: собираем
:: -E            Stop after the preprocessing stage;
::               do not run the compiler proper.
:: -C            Tell the preprocessor not to discard comments.
::               Used with the `-E' option.
:: -P            без служебного вывода
:: -x c          считаем исходные файлы написанными на Си
:: -o filename   результат записываем в файл
:: -D amacro=defn Define macro amacro as defn.
gcc -E -C -P -x c -o %NMLNAME%.nml src/%NMLNAME%.pnml
if /i not %errorlevel% == 0 goto :Error
:: компилируем
nmlc --nfo=%NMLNAME%.nfo --grf=%NMLNAME%.grf ^
  --nml=%NMLNAME%_optimized.nml -M --MF=%NMLNAME%_dep.txt %NMLNAME%.nml
if /i not %errorlevel% == 0 goto :Error
:: копируем
xcopy /y %NMLNAME%.grf "%GRFFOLDER%\"
if /i not %errorlevel% == 0 goto :Error
echo [Ok]
goto :EOF
:Error
echo [ERR]
