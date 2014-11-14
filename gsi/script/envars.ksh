#!/bin/ksh

#===================================================================#
#== set up running variables, such as path and directories



#== about main system 
  #export SYSTEM=${HOME}/${SYSNAME} 
  export SCRIPT=${WORKDIR}/script
  export EXEDIR=${WORKDIR}/bin
  export CONDAT=${WORKDIR}/condat
  export ANLFIX=${CONDAT}/anlfix
  export CLIDAT=${CONDAT}/climate
  export GSIFIX=${CONDAT}/gsifix

#== about run/work  =========================
  

  export LOGDIR=${WORKDIR}/logdir
  export RUNDIR=${WORKDIR}/rundir
  export MODDAT=${WORKDIR}/moddat
  export BAKDAT=${WORKDIR}/bakdat
  export BAKLOG=${BAKDAT}/LOG
  export ANLDAT=${WORKDIR}/anldat
  export CHECKDAT=${WORKDIR}/checkdat
  export SFCDAT=${WORKDIR}/sfcdat

  export GSIDIR=${WORKDIR}/gsidir
  export GSISFC=${GSIDIR}/gsisfc
  export GSIOUT=${GSIDIR}/gsiout
  export GSIFGS=${GSIDIR}/gsifgs

  export OBSDIR=${WORKDIR}/obsdir
  export AOBDAT=${OBSDIR}/aobdat
  export AOBQCD=${OBSDIR}/aob_qc
  export OBSDAT=${OBSDIR}/obsdat
  export SATDAT=${OBSDIR}/satdat
  export SSTDAT=${OBSDIR}/sstdat

  export GFDAT=${WORKDIR}/gfdat

  export MODFCST=${WORKDIR}/modfcst
  export POSTDAT=${WORKDIR}/post

  export VERIFY=${WORKDIR}/verify


#==  about vortex  part=================#
  export TCFIX=${CONDAT}/tcfix
  export TCMESS=${OBSDIR}/tcmess
  export VORTEX=${WORKDIR}/vortex
  export TCRUN=${VORTEX}/rundir
  export TCPOST=${VORTEX}/tcpost
  export TCGRAPH=${VORTEX}/tcgraph
  export TCLIB=${VORTEX}/tclib

  export MESSDAT=${VORTEX}/tcmess
  export SPLIT=${VORTEX}/split

  export TCBOGUS=${VORTEX}/tcbogus
  export TRACKER=${VORTEX}/tracker
  export RELOCAT=${VORTEX}/relocat
  export INTENSIFY=${VORTEX}/intensify
  export OUT9H_TRACKER=${VORTEX}/trackdata_9h
#===================================================================#


#== history data bank --zhangtao add
#export Data_Bank=/cma/g5/ldas_xp/Data_Bank
#export MY_OBS_BANK=${Data_Bank}/aobdata/${YYYY}
#export SATLIB=${Data_Bank}/satdata
#export MY_SAT_BANK=${Data_Bank}/satdata/${YYYY}
#export TCMESSBANK=${Data_Bank}/tcmess_data/${YYYY}
#export SSTBANK=${Data_Bank}/sst_data/${YYYY}
#YYYY=`cat $LOGDIR/DATE|cut -c1-4`
#YYYY=${DATE:0:4}
date0="`cat $LOGDIR/DATE` `cat $LOGDIR/TIME`"
YYYY=`zt_date +%Y -d "$date0 6 hour"`
export Data_Bank=${WORKDIR}/Data_Bank
export MY_OBS_BANK=${Data_Bank}/aob
export SATLIB=${Data_Bank}/sat
export MY_SAT_BANK=${Data_Bank}/sat
export TCMESSBANK=${Data_Bank}/tcmess_data
export SSTBANK=${Data_Bank}/sst
