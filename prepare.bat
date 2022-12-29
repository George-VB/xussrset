@echo off
cd lang
rem for %%f in (*.lng) do ..\scripts\Adjust2Master.pl english.lng %%f lng
cd ..
      	
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes-capacity-box.pnml		ct2cl
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes-capacity-flatbed.pnml		ct2cl
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes-capacity-gondola.pnml		ct2cl
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes-capacity-hopper.pnml		ct2cl
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes-capacity-ref.pnml		ct2cl
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes-capacity-tank.pnml		ct2cl
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes-loadspeed-box.pnml		ct2cl
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes-loadspeed-cont.pnml		ct2cl
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes-loadspeed-tank.pnml		ct2cl
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes-loadspeed-flatbed.pnml		ct2cl
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes-loadspeed-hopper.pnml		ct2cl

scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes5\cargoes.pnml		ct2cl 
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes5\cargoes-flatbed.pnml	ct2cl 
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes6\cargoes.pnml		ct2cl 
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes6\cargoes-gondola.pnml	ct2cl 
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes6\cargoes-flatbed.pnml	ct2cl 
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes7\cargoes-gondola.pnml	ct2cl 
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes8\cargoes.pnml		ct2cl 
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes8\cargoes-gondola.pnml	ct2cl 
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes8\cargoes-flatbed.pnml	ct2cl 
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes9\cargoes.pnml		ct2cl 
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes9\cargoes-gondola.pnml	ct2cl 
scripts\Adjust2Master.pl src\cargotable.pnml src\freight\cargoes9\cargoes-flatbed.pnml	ct2cl 
