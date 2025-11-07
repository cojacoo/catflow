#!/bin/bash
#rm *.o 

gfortran -c -o ADDSTEPS.o ./src/ADDSTEPS.f 
gfortran -c -o BACHW.o ./src/BACHW.f 
gfortran -c -o BALANC.o ./src/BALANC.f 
gfortran -c -o BODTAB.o ./src/BODTAB.f 
gfortran -c -o CALBNA.o ./src/CALBNA.f 
gfortran -c -o CALGEO.o ./src/CALGEO.f 
gfortran -c -o CATFLOW.o ./src/CATFLOW.f 
gfortran -c -o C_IPOB.o ./src/C_IPOB.f 
gfortran -c -o DCG.o ./src/DCG.f 
gfortran -c -o ETINTZ.o ./src/ETINTZ.f 
gfortran -c -o FIL_IO.o ./src/FIL_IO.f 
gfortran -c -o GGCROSS.o ./src/GGCROSS.f 
gfortran -c -o HG.o ./src/HG.f 
gfortran -c -o HG_OPERA.o ./src/HG_OPERA.f 
gfortran -c -o KINNEN.o ./src/KINNEN.f 
gfortran -c -o KOEFF.o ./src/KOEFF.f 
gfortran -c -o KOEFFBR.o ./src/KOEFFBR.f 
gfortran -c -o KOEFFRB.o ./src/KOEFFRB.f 
gfortran -c -o KSENKEN.o ./src/KSENKEN.f 
gfortran -c -o OBERFLW.o ./src/OBERFLW.f 
gfortran -c -o PMASS.o ./src/PMASS.f 
gfortran -c -o POINT_IN_POLYGON.o ./src/POINT_IN_POLYGON.f 
gfortran -c -o PTKINJ2.o ./src/PTKINJ2.f 
gfortran -c -o P_STEPB.o ./src/P_STEPB.f 
gfortran -c -o RDMINF.o ./src/RDMINF.f 
gfortran -c -o RDRBF.o ./src/RDRBF.f 
gfortran -c -o RDZRBF.o ./src/RDZRBF.f 
gfortran -c -o RD_RB.o ./src/RD_RB.f 
gfortran -c -o REL_SECW.o ./src/REL_SECW.f 
gfortran -c -o STEPS.o ./src/STEPS.f 
gfortran -c -o TCALW.o ./src/TCALW.f 
gfortran -c -o V_INTB.o ./src/V_INTB.f 
gfortran -c -o V_STRB.o ./src/V_STRB.f 
gfortran -c -o ZUFALL.o ./src/ZUFALL.f 
gfortran -c -o rd_wr.o ./src/rd_wr.f 

gfortran -o catflow ADDSTEPS.o BACHW.o BALANC.o BODTAB.o CALBNA.o CALGEO.o CATFLOW.o C_IPOB.o DCG.o ETINTZ.o FIL_IO.o GGCROSS.o HG.o HG_OPERA.o KINNEN.o KOEFF.o KOEFFBR.o KOEFFRB.o KSENKEN.o OBERFLW.o PMASS.o POINT_IN_POLYGON.o PTKINJ2.o P_STEPB.o RDMINF.o RDRBF.o RDZRBF.o RD_RB.o REL_SECW.o STEPS.o TCALW.o V_INTB.o V_STRB.o ZUFALL.o rd_wr.o 
rm *.o 
 
