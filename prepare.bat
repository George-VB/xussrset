@echo off
cd lang
rem for %%f in (*.lng) do ..\scripts\Adjust2Master.pl english.lng %%f lng
cd ..

scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes-capacity-box.pnml           ct2cl
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes-capacity-flatbed.pnml       ct2cl
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes-capacity-gondola.pnml       ct2cl
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes-capacity-hopper.pnml        ct2cl
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes-capacity-ref.pnml           ct2cl
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes-capacity-tank.pnml          ct2cl
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes-loadspeed-box.pnml          ct2cl
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes-loadspeed-cont.pnml         ct2cl
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes-loadspeed-tank.pnml         ct2cl
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes-loadspeed-flatbed.pnml      ct2cl
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes-loadspeed-hopper.pnml       ct2cl
