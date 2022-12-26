@echo off
cd lang
for %%f in (*.lng) do ..\scripts\Adjust2Master.pl english.lng %%f lng
del *.bak 
cd ..

