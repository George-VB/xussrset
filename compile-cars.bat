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

::: ��ࠬ���� ��� �����
call :SelfConfig
:: ��ࠬ���� ���짮��⥫�
call ..\config user

:: ����� ��६���� ���㦥���
set PATH=%PATHMINGW%;%PATHNML%;%PATHTHG%;%PATH%

:: ��।��塞 ⥪���� ॢ����
call :GetHgRev

:: �᫨ MIN_COMPATIBLE_REVISION == 0, �ᯮ��㥬 REPO_REVISION
if "%MIN_COMPATIBLE_REVISION%" == "0" ^
  set MIN_COMPATIBLE_REVISION=%REPO_REVISION%

:::call :EchoParams
:::exit
:: ᮧ��� 䠩� custom_tags
call :WriteCustomTags>%CUSTOM_TAGS%

:: ᮡ�ࠥ�
:: -E            Stop after the preprocessing stage;
::               do not run the compiler proper.
:: -C            Tell the preprocessor not to discard comments.
::               Used with the `-E' option.
:: -P            ��� �㦥����� �뢮��
:: -x c          ��⠥� ��室�� 䠩�� ����ᠭ�묨 �� ��
:: -o filename   १���� �����뢠�� � 䠩�
:: -D amacro=defn Define macro amacro as defn.
gcc -D REPO_REVISION=%REPO_REVISION% ^
  -D MIN_COMPATIBLE_REVISION=%MIN_COMPATIBLE_REVISION% ^
  -E -C -P -x c -o %NMLNAME%.nml %NMLNAME%.pnml
if /i not %errorlevel% == 0 goto :Error
:: ��������㥬
scripts\change.pl xussr-cars.nml "\s*\{\s*" "\n\{\n  "
scripts\change.pl xussr-cars.nml "\s*\}\s*" "\n\}\n"
scripts\change.pl xussr-cars.nml "\;" "\;\n"
scripts\change.pl xussr-cars.nml "\n\r*\n" "\n"
scripts\change.pl xussr-cars.nml "\{\s*([a-z0-9_ ]+);\s*\}" "{ $1; }"

del xussr-cars.bak
nmlc --grf=%NMLNAME%.grf %NMLCOPTION% %NMLNAME%.nml
if /i not %errorlevel% == 0 goto :Error
:: �����㥬, �᫨ ����� ����
if /i not "%GRFFOLDER%" == "" (
  xcopy /y %NMLNAME%.grf "%GRFFOLDER%"
  if /i not %errorlevel% == 0 goto :Error
:: �몫��뢠�� 䠩� ᡮન � ����� � ������ ��⪨, ��� ��⪨ ���� � .git/HEAD � ��ப� ���� ref: refs/heads/main ��� main ��� ��⪨
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

:: ��।��塞 ⥪���� ॢ����
for /F %%i in (%YDPATH%\%NMLNAME%.ver) do set REPO_REVISION=%%i
set /a REPO_REVISION=%REPO_REVISION%+1
echo %REPO_REVISION%>%YDPATH%\%NMLNAME%.ver

goto :EOF

:: WriteCustomTags
:WriteCustomTags
echo VERSION  :%REPO_REVISION%
echo MIN_COMPATIBLE_REVISION:%MIN_COMPATIBLE_REVISION%
echo TITLE    :xUSSR Railway Cars Set 0.8.2.r%REPO_REVISION%
echo FILENAME :%NMLNAME%.grf
goto :EOF

:: SelfConfig
:SelfConfig
:: ��� 䠩�� � ����஬
set NMLNAME=xussr-cars
:: ��� �㦥����� 䠩�� ��� ᡮન
set CUSTOM_TAGS=custom_tags.txt
:: �������쭠� ᮢ���⨬�� ॢ����
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

:: ���⪠ ����� �� ࠡ��� 䠩��� �� ������� "compile cleanup"
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
rem ����� 24 �ᮢ �� ��⠥�
echo Total time: %timetot3%:%timetot2%:%timetot1%
echo %datebeg% %timefin% - %timetot3%:%timetot2%:%timetot1% %compres%>>compile.stat

cd src 
start /min ..\scripts\MonaLisa.pl 
cd ..

:EOF
