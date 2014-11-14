#!/bin/ksh
# @ comment=T639
# @ job_type=serial
# @ job_name=vortex_post_relocat
# @ initialdir =/cmd/u/yaosh/T639L60_GSI3.3/logdir
# @ input= /dev/null
# @ output = $(initialdir)/$(job_name).out
# @ error  = $(initialdir)/$(job_name).err
# @ notify_user =yaosh@cmd01n02
# @ notification = error
# @ checkpoint = no
# @ restart = no
# @ node_usage = shared
# @ wall_clock_limit = 00:50:00, 00:50:00
# @ class = serial
# @ queue
#==========================================
set -x 
#=====set env for running===========#
MBX_SIZE=160000000;export MBX_SIZE
export MP_RESD=yes
export MP_EAGER_LIMIT=65536
export MP_RESD=yes
export MP_EAGER_LIMIT=65536
export MP_BUFFER_MEM=32M
export MP_CSS_INTERRUPT=yes
export MP_INFOLEVEL=2
export AIX_THREAD_MNRATIO=1:1
export SPILLOOPTIME=500
export YIELDLOOPTIME=500
export OMP_DYNAMIC=FALSE,AIX_THREAD_SCOPE=S,MALLOCMULTIHEAP=TRUE
export XLSMPOPTS="parthds=1:stack=50000000:schedule=affinity"
#
#export MP_LABELIO=yes
#export MP_RMPOOL=0
#export MP_HOSTFILE=host.list
#export MP_SHARED_MEMORY=yes
#
export MP_MSG_API=mpi
export MP_EUIDEVELOP=min
export MP_WAIT_MODE=poll
export MP_REXMIT_BUF_SIZE=66000
export MP_USE_ISFIFO=no
# =======================================================
set -e #======= stop the shell on first error
set -x #======= echo script lines as they are executed
set -a
#===================================================================#
# Set up running variables, such as path and directories

  export WORKDIR=/cmd/u/yaosh/T639L60_GSI3.3
       . $WORKDIR/script/envars.ksh
#===================================================================#
  if [ ! -d ${VORTEX} ]; then
     mkdir -p ${VORTEX}
  fi

  if [ ! -d $TCRUN ] ; then
       mkdir -p $TCRUN
  else 
      rm -rf $TCRUN/*
  fi

  if [ ! -d ${OUT9H_TRACKER} ]; then
     mkdir -p ${OUT9H_TRACKER}
  else
     rm -f ${OUT9H_TRACKER}/*
  fi
#===================================================================#
  test -f $LOGDIR/DATE ||  { echo file DATE not exist ; exit 1; }
  test -f $LOGDIR/TIME ||  { echo file TIME not exist ; exit 1; }

  DATE=`cat $LOGDIR/DATE`
  TIME=`cat $LOGDIR/TIME`
  DATE1=`${EXEDIR}/smsdate $DATE$TIME +06 | cut -c1-8`
  TIME1=`${EXEDIR}/smsdate $DATE$TIME +06 | cut -c9-10`
  echo $DATE $TIME $DATE1 $TIME1

#anex================================================================
   cd ${TCRUN}
   rm -rf ${TCRUN}/*

   # =====  to get track.dat from GDB library ========

   test -f ${POSTDAT}/ICMPL0001+000003+$DATE$TIME  || { echo " NO $POSTDAT/ICMPL0001+000003+$DATE$TIME exist!! " ; exit 1; }
   test -f ${POSTDAT}/ICMPL0001+000006+$DATE$TIME  || { echo " NO $POSTDAT/ICMPL0001+000006+$DATE$TIME exist!! " ; exit 1; }
   test -f ${POSTDAT}/ICMPL0001+000009+$DATE$TIME  || { echo " NO $POSTDAT/ICMPL0001+000009+$DATE$TIME exist!! " ; exit 1; }

   test -f ${POSTDAT}/ICMGG0001+000003+$DATE$TIME  || { echo " NO $POSTDAT/ICMGG0001+000003+$DATE$TIME exist!! " ; exit 1; }
   test -f ${POSTDAT}/ICMGG0001+000006+$DATE$TIME  || { echo " NO $POSTDAT/ICMGG0001+000006+$DATE$TIME exist!! " ; exit 1; }
   test -f ${POSTDAT}/ICMGG0001+000009+$DATE$TIME  || { echo " NO $POSTDAT/ICMGG0001+000009+$DATE$TIME exist!! " ; exit 1; }

   test -f ${POSTDAT}/mslq+000003+$DATE$TIME  || { echo " NO $POSTDAT/mslq+000003+$DATE$TIME exist!! " ; exit 1; }
   test -f ${POSTDAT}/mslq+000006+$DATE$TIME  || { echo " NO $POSTDAT/mslq+000006+$DATE$TIME exist!! " ; exit 1; }
   test -f ${POSTDAT}/mslq+000009+$DATE$TIME  || { echo " NO $POSTDAT/mslq+000009+$DATE$TIME exist!! " ; exit 1; }

   test -f ${POSTDAT}/rh2m+000003+$DATE$TIME  || { echo " NO $POSTDAT/rh2m+000003+$DATE$TIME exist!! " ; exit 1; }
   test -f ${POSTDAT}/rh2m+000006+$DATE$TIME  || { echo " NO $POSTDAT/rh2m+000006+$DATE$TIME exist!! " ; exit 1; }
   test -f ${POSTDAT}/rh2m+000009+$DATE$TIME  || { echo " NO $POSTDAT/rh2m+000009+$DATE$TIME exist!! " ; exit 1; }

   cp ${POSTDAT}/ICMPL0001+000003+$DATE$TIME                ${TCRUN}/
   cp ${POSTDAT}/ICMPL0001+000006+$DATE$TIME                ${TCRUN}/
   cp ${POSTDAT}/ICMPL0001+000009+$DATE$TIME                ${TCRUN}/

   cp ${POSTDAT}/ICMGG0001+000003+$DATE$TIME                ${TCRUN}/
   cp ${POSTDAT}/ICMGG0001+000006+$DATE$TIME                ${TCRUN}/
   cp ${POSTDAT}/ICMGG0001+000009+$DATE$TIME                ${TCRUN}/

   cp ${POSTDAT}/mslq+000003+$DATE$TIME                ${TCRUN}/
   cp ${POSTDAT}/mslq+000006+$DATE$TIME                ${TCRUN}/
   cp ${POSTDAT}/mslq+000009+$DATE$TIME                ${TCRUN}/

   cp ${POSTDAT}/rh2m+000003+$DATE$TIME                ${TCRUN}/
   cp ${POSTDAT}/rh2m+000006+$DATE$TIME                ${TCRUN}/
   cp ${POSTDAT}/rh2m+000009+$DATE$TIME                ${TCRUN}/

   cp ${EXEDIR}/vortex_readpost_relocat_tracker.exe      ${TCRUN}/

   echo ${DATE}${TIME} | vortex_readpost_relocat_tracker.exe


   # == output file  track.dat
   if [ ! -s fcst_03_06_09.dat ]; then
       echo " no file fcst_03_06_09.dat from post output, no exist  "
       exit  1
   else
       mv fcst_03_06_09.dat  $OUT9H_TRACKER/fcst_03_06_09.dat_$DATE$TIME
   fi
#===================================================
#===================================================
exit 0       # End the shell
