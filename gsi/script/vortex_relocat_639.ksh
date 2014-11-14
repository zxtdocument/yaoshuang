#!/bin/ksh
# @ comment=T639
# @ job_type=serial
# @ job_name=vortex_relocat
# @ initialdir =/cmd/u/yaosh/T639L60_GSI3.3/logdir
# @ input= /dev/null
# @ output = $(initialdir)/$(job_name).out
# @ error  = $(initialdir)/$(job_name).err
# @ notification = error
# @ checkpoint = no
# @ restart = no
# @ node_usage = shared
# @ wall_clock_limit = 00:30:00, 00:30:00
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
#================== ===========================================

set -e #======= stop the shell on first error
set -x #======= echo script lines as they are executed
set -a
#===================================================================#
# Set up running variables, such as path and directories

  export WORKDIR=/cmd/u/yaosh/T639L60_GSI3.3
       . $WORKDIR/script/envars.ksh

#===================================================================#
  if [ ! -d $OBSDIR ] ; then
      echo NO $OBSDIR EXIST !!
      exit 1
  fi

  if [ ! -d ${VORTEX} ]; then
     mkdir -p ${VORTEX}
  fi

  if [ ! -d $TCRUN ] ; then
       mkdir -p $TCRUN
  else 
      rm -rf $TCRUN/*
  fi

  if [ ! -d ${MESSDAT} ]; then
     mkdir -p ${MESSDAT}
  fi

  if [ ! -d ${TCLIB} ]; then
     mkdir -p ${TCLIB}
  fi

  if [ ! -d ${SPLIT} ]; then
     mkdir -p ${SPLIT}
  else
     rm -f ${SPLIT}/*
  fi

  if [ ! -d ${TCBOGUS} ]; then
     mkdir -p ${TCBOGUS}
  else
     rm -f ${TCBOGUS}/*
  fi

  if [ ! -d ${INTENSIFY} ]; then
     mkdir -p ${INTENSIFY}
  else
     rm -f ${INTENSIFY}/*
  fi

  if [ ! -d ${RELOCAT} ]; then
     mkdir -p ${RELOCAT}
  else
     rm -f ${RELOCAT}/*
  fi

  if [ ! -d ${TRACKER} ]; then
     mkdir -p ${TRACKER}
  else
     rm -f ${TRACKER}/*
  fi
  if [ ! -d $BAKDAT ] ; then
       mkdir -p $BAKDAT
  fi
  if [ ! -d $BAKLOG ] ; then
       mkdir -p $BAKLOG
  fi
#===================================================================#
#===================================================================#
  test -f $LOGDIR/DATE ||  { echo file DATE not exist ; exit 1; }
  test -f $LOGDIR/TIME ||  { echo file TIME not exist ; exit 1; }

  DATE=`cat $LOGDIR/DATE`
  TIME=`cat $LOGDIR/TIME`
  DATE1=`${EXEDIR}/smsdate $DATE$TIME +06 | cut -c1-8`
  TIME1=`${EXEDIR}/smsdate $DATE$TIME +06 | cut -c9-10`
  echo $DATE $TIME $DATE1 $TIME1
#anex================================================================
#====to check real time TC report, yes or no ========
  if [ ! -s ${TCMESS}/tc_report_${DATE1}${TIME1} ]; then
      echo " no real time TC message "
      echo " soemthing must be wrong!!! "
      exit 0
  else
      rm -f ${MESSDAT}/*
     
      if [ ! -s ${TCLIB}/tc_report.sum ]; then
           cat ${TCMESS}/tc_report_${DATE1}${TIME1} > ${TCLIB}/tc_report.sum
      else
           cat ${TCMESS}/tc_report_${DATE1}${TIME1} >> ${TCLIB}/tc_report.sum
      fi

      cp ${TCMESS}/tc_report_${DATE1}${TIME1}  ${MESSDAT}/tc_report.current_${DATE1}${TIME1}
      if [ -s ${TCMESS}/tc_report_${DATE}${TIME} ]; then
         cp ${TCMESS}/tc_report_${DATE}${TIME}   ${MESSDAT}/tc_report.oldtime_${DATE}${TIME}   
      fi

  fi

#==== to split tc_report from current and old time tc_report =========

  cd  ${TCRUN}
  rm -rf ${TCRUN}/*

  test -f ${MESSDAT}/tc_report.oldtime_${DATE}${TIME} || echo "old tc report at last time no exist "

  if [ -f ${MESSDAT}/tc_report.oldtime_${DATE}${TIME} ]; then
     cp ${MESSDAT}/tc_report.oldtime_${DATE}${TIME}     ${TCRUN}/tc_report.oldtime
     echo " tc_report.oldtime  as follows "
     cat ${MESSDAT}/tc_report.oldtime_${DATE}${TIME}
  fi

   echo " tc_report.current  as follows "
   cat ${MESSDAT}/tc_report.current_${DATE1}${TIME1}

   cp ${MESSDAT}/tc_report.current_${DATE1}${TIME1}     ${TCRUN}/tc_report.current

   cp ${EXEDIR}/vortex_split_tc_report.exe      ${TCRUN}/

   timex vortex_split_tc_report.exe  > ${LOGDIR}/vortex_split_tc_report.log

   cp ${LOGDIR}/vortex_split_tc_report.log    ${BAKLOG}/vortex_split_tc_report.log_$DATE1$TIME1

  rm -f ${SPLIT}/*
  cp ${TCRUN}/tc_message.track  ${SPLIT}/
  cp ${TCRUN}/tc_message.bogus  ${SPLIT}/

  cp ${TCRUN}/tc_message.bogus  ${TCBOGUS}/

     echo " after split,tc_report.track  as follows "
     cat ${SPLIT}/tc_message.track
     echo " after split,tc_report.bogus  as follows "
     cat ${SPLIT}/tc_message.bogus

  rm -rf ${TCRUN}/*

# ==== if tc_message.track > 0, exist vortex in the background
# ==== to track the tc_message.track ========
# ====  get current date information =========
if [ -s ${SPLIT}/tc_message.track ]; then
  
   echo " exist old vortex, so need to search it in the background"

   cd ${TCRUN}
   rm -rf ${TCRUN}/*

   cp ${SPLIT}/tc_message.track  ${TCRUN}/

   YY=`echo $DATE1 | cut -c1-4`
   MM=`echo $DATE1 | cut -c5-6`
   DD=`echo $DATE1 | cut -c7-8`
   HH=`echo $TIME1 | cut -c1-2`

   LASTTIME=$DATE$TIME
   echo $LASTTIME
   YYY=`echo $DATE | cut -c1-4`
   MMM=`echo $DATE | cut -c5-6`
   DDD=`echo $DATE | cut -c7-8`
   HHH=`echo $TIME | cut -c1-2`

   # == check 3h/6h/9h output fcstpost file
   if [ ! -s $OUT9H_TRACKER/fcst_03_06_09.dat_$DATE$TIME ]; then
       echo " no file fcst_03_06_09.dat from post output, no exist  "
       exit  1
   else 
      cp $OUT9H_TRACKER/fcst_03_06_09.dat_$DATE$TIME   $TCRUN/fcst_03_06_09.dat
   fi

  timex date

   # === to track TC position at the fcst gdb 
   # == 1): to produce the namelist file fro tracker programer
cat >namelist.input <<EOF

   &datein   
        inp = ${YYY},${MMM},${DDD},${HHH}/

EOF

   cp ${SPLIT}/tc_message.track               ${TCRUN}/
   cp ${EXEDIR}/vortex_tracker_relocat.exe       ${TCRUN}/vortex_tracker_relocat.exe
   # =================================
   timex vortex_tracker_relocat.exe > ${LOGDIR}/vortex_tracker_relocat.log 
   cp ${LOGDIR}/vortex_tracker_relocat.log    ${BAKLOG}/vortex_tracker_relocat.log_$DATE1$TIME1

   if [ $? -ne 0 ]; then
     echo  run vortex_tracker_relocat.exe error
   fi


   # ==== to analyze tc_locat.fcst file ====
  if [ ! -d ${TRACKER} ]; then
     mkdir -p ${TRACKER}
  else
     rm -f ${TRACKER}/*
  fi

   if [ ! -s tc_locat.fcst ];then
      echo " exist old vortex, but no FIND TC track in background fields "
   else 
      cp tc_locat.fcst   ${TRACKER}/tc_locat.fcst
   fi

   echo "  TCs need being tracked , as follows:   "
   cat tc_message.track

   if [  -s tc_locat.fcst ];then
      echo " BACKGROUND TCs  last time, as follows:   "
      cat tc_locat.fcst
   fi

   timex date

   cd ${TCRUN}
   rm -f ${TCRUN}/*
# ==== to check the shallow vortex exist or not
# ===== if no exist, must add tc_message.track to tc_message.bogus
   if [  -f ${SPLIT}/tc_message.bogus ];then
      cp ${SPLIT}/tc_message.bogus    ${TCRUN}/
   fi
   cp ${SPLIT}/tc_message.track     ${TCRUN}/
   if [  -f ${TRACKER}/tc_locat.fcst ];then
      cp  ${TRACKER}/tc_locat.fcst  ${TCRUN}/
   fi
   cp ${EXEDIR}/vortex_combine_tc_report.exe    ${TCRUN}/

   timex vortex_combine_tc_report.exe >${LOGDIR}/vortex_combine_mess.log

   # == output file : new tc_message.bogus, be bogused
   # == output file : tc_message.relocat , be relocated
   # == output file : tc_message.intensify , be intensified
   # == output file : trackdata.relocat, shallow vortex center

   echo " after combine TC  report, TC NEED BEING BOGUSSED as follows"
   cat tc_message.bogus
   echo " after combine TC  report, TC NEED BEING relocated as follows"
   cat tc_message.relocat
   echo " after combine TC  report, TC NEED BEING intensified as follows"
   cat tc_message.intensify

    if [ ! -d ${RELOCAT} ]; then
       mkdir -p ${RELOCAT}
    else
       rm -f ${RELOCAT}/*
    fi

    if [ ! -d ${INTENSIFY} ]; then
       mkdir -p ${INTENSIFY}
    else
       rm -f ${INTENSIFY}/*
    fi

   if [ -s ${TCRUN}/tc_message.bogus ]; then
       rm -rf  ${TCBOGUS}/tc_message.bogus
       cp ${TCRUN}/tc_message.bogus    ${TCBOGUS}/tc_message.bogus_$DATE1$TIME1
   fi
   if [ -s ${TCRUN}/tc_message.relocat ]; then
       cp ${TCRUN}/tc_message.relocat  ${RELOCAT}/
   fi
   if [ -s ${TCRUN}/tc_message.intensify ]; then
       cp ${TCRUN}/tc_message.intensify  ${INTENSIFY}/tc_message.intensify_$DATE1$TIME1
   fi
   if [ -s ${TCRUN}/trackdata.relocat ]; then
       cp ${TCRUN}/trackdata.relocat   ${RELOCAT}/
   fi

   rm  -f  ${TCRUN}/*

# == to get current date time from logdir

# === to relocate the shallow vortex in the background  
   cd ${TCRUN}
   rm  -rf  ${TCRUN}/*
   if [ -s ${RELOCAT}/tc_message.relocat  -a -s ${RELOCAT}/trackdata.relocat ]; then
      echo " exist old vortex, and FIND TC track in background fields "
      echo " vortex relocation  start "
     cp ${RELOCAT}/tc_message.relocat  ${TCRUN}/
     cp ${RELOCAT}/trackdata.relocat   ${TCRUN}/
     cp ${GSIFGS}/xsp03.dat$DATE$TIME   ${TCRUN}/
     cp ${GSIFGS}/xsp06.dat$DATE$TIME   ${TCRUN}/
     cp ${GSIFGS}/xsp09.dat$DATE$TIME   ${TCRUN}/
  
     # === input files
     ln -sf tc_message.relocat      fort.11
     ln -sf trackdata.relocat       fort.30
     ln -sf xsp03.dat$DATE$TIME    fort.20 
     ln -sf xsp06.dat$DATE$TIME    fort.21
     ln -sf xsp09.dat$DATE$TIME    fort.22

     # == output files
     ln -sf nmc03.output    fort.53 
     ln -sf nmc06.output    fort.56
     ln -sf nmc09.output    fort.59

     cp ${EXEDIR}/vortex_relocate_mv_nvortex_tempest    ${TCRUN}/vortex_relocate_mv_nvortex
     cp ${EXEDIR}/libessl_r.a    ${TCRUN}/
     cp ${EXEDIR}/libessl.a      ${TCRUN}/
     export LIBPATH=$TCRUN:$LIBPATH
     
#========= modified for T639 == SHORTENNING RUN TIME ==========
#========modified by anex for shortenning run time for T639
     timex echo 3 1280 640 | vortex_relocate_mv_nvortex 
     timex echo 6 1280 640 | vortex_relocate_mv_nvortex 
     timex echo 9 1280 640 | vortex_relocate_mv_nvortex

     if [ -s nmc06.output ];then
       echo " relocation vortex success " 
     fi

     if [ -s nmc09.output ];then
       echo " relocation vortex success " 
     # == return the modified FGS OF SSI
       cp  nmc03.output  ${ANLDAT}/xsp03.dat$DATE$TIME 
       cp  nmc06.output  ${ANLDAT}/xsp06.dat$DATE$TIME 
       cp  nmc09.output  ${ANLDAT}/xsp09.dat$DATE$TIME
     else
       echo "relocation vortex failed   "
     fi

     rm -f ${TCRUN}/*
   else
     echo  "exist old vortex, but no find tc track in the background fileds "
     echo  "in order to resubmit this job, the background file must be covered"
     cp ${GSIFGS}/xsp03.dat$DATE$TIME   ${ANLDAT}/.
     cp ${GSIFGS}/xsp06.dat$DATE$TIME   ${ANLDAT}/.
     cp ${GSIFGS}/xsp09.dat$DATE$TIME   ${ANLDAT}/.
   fi
# === end of relocating the shallow vortex in the background  

else
   echo " no exist old vortex "
   echo  "in order to resubmit this job, the background file must be covered"
     cp ${GSIFGS}/xsp03.dat$DATE$TIME   ${ANLDAT}/.
     cp ${GSIFGS}/xsp06.dat$DATE$TIME   ${ANLDAT}/.
     cp ${GSIFGS}/xsp09.dat$DATE$TIME   ${ANLDAT}/.

fi


#================= submit next job =================
 llsubmit ${SCRIPT}/vortex_bogus_intensify_639.ksh

  DATE2=`${EXEDIR}/smsdate $DATE$TIME -12 | cut -c1-8`
  TIME2=`${EXEDIR}/smsdate $DATE$TIME -12 | cut -c9-10`

  rm  -f   ${RELOCAT}/*
  rm  -f   ${TRACKER}/*
  rm  -f   ${SPLIT}/*
  rm  -f   ${MESSDAT}/*
#======================================================================
#======================================================================
  cp ${LOGDIR}/vortex_relocat.out    ${BAKLOG}/vortex_relocat.out_$DATE1$TIME1
  cp ${LOGDIR}/vortex_relocat.err    ${BAKLOG}/vortex_relocat.err_$DATE1$TIME1
#======================================================================

#================== ===========================================
#================== ===========================================
   timex date
#================== ===========================================
#================== ===========================================

exit 0       # End the shell
