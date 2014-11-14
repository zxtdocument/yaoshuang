#!/bin/ksh
## @ job_type=serial
# @ comment=T639
# @ job_type=parallel
# @ job_name=vortex_bogus_intensify
# @ initialdir =/cmd/u/yaosh/T639L60_GSI3.3/logdir
# @ input= /dev/null
# @ output = $(initialdir)/$(job_name).out
# @ error  = $(initialdir)/$(job_name).err
# @ notify_user =yaosh@cmd01n02
# @ notification = error
# @ checkpoint = no
# @ restart = no
# @ node = 1
# @ tasks_per_node = 6
# @ node_usage = shared
# @ network.MPI = sn_single,not_shared,US
##@ network.MPI = css0,shared,US
# @ wall_clock_limit = 01:50:00, 01:50:00
# @ class = normal
# @ queue


set -e # stop the shell on first error
set -u # fail when using an undefined variable
set -x # echo script lines as they are executed
set -a
#===================================================================#
#===================================================================#
   timex date
#===================================================================#
#===================================================================#

# Set up running variables, such as path and directories

  export WORKDIR=/cmd/u/yaosh/T639L60_GSI3.3
       . $WORKDIR/script/envars.ksh

#================================================
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


#===================================================================#
  if [ ! -d ${TCRUN} ]; then
     mkdir -p ${TCRUN}
  else
     rm -rf ${TCRUN}/*
  fi
  if [ ! -d $BAKDAT ] ; then
       mkdir -p $BAKDAT
  fi
  if [ ! -d $BAKLOG ] ; then
       mkdir -p $BAKLOG
  fi

#===================================================================#
# === to add vortex to the backfground that was produced by model
# === to intensify the vortex in the backfground 

    # == to get current date time from logdir
    DATE=`cat $LOGDIR/DATE`
    TIME=`cat $LOGDIR/TIME`

  DATE1=`${EXEDIR}/smsdate ${DATE}${TIME} +06 | cut -c1-8`
  TIME1=`${EXEDIR}/smsdate ${DATE}${TIME} +06 | cut -c9-10`
  echo $DATE $TIME $DATE1 $TIME1

  rm -rf ${TCRUN}/*
  cd ${TCRUN}

   if [ -s ${TCBOGUS}/tc_message.bogus_$DATE1$TIME1 ]; then
       cp ${TCBOGUS}/tc_message.bogus_$DATE1$TIME1    ${TCRUN}/tc_message.bogus
       echo " add  bogus vortex for new tc "
   fi
   if [ -s ${INTENSIFY}/tc_message.intensify_$DATE1$TIME1 ]; then
       cp ${INTENSIFY}/tc_message.intensify_$DATE1$TIME1  ${TCRUN}/tc_message.intensify
       echo " enhance vortex for old TC "
   fi

   cp ${ANLDAT}/xsp03.dat$DATE$TIME   ${TCRUN}/
   cp ${ANLDAT}/xsp06.dat$DATE$TIME   ${TCRUN}/
   cp ${ANLDAT}/xsp09.dat$DATE$TIME   ${TCRUN}/

   cp ${EXEDIR}/vortex_bogus_intensify.exe_tempest   ${TCRUN}/vortex_bogus_intensify.exe
   cp ${EXEDIR}/libessl_r.a    ${TCRUN}/
   cp ${EXEDIR}/libessl.a      ${TCRUN}/
   export LIBPATH=$TCRUN:$LIBPATH

#========== modified by anex for shortenning run time for T639==============
   ln -sf xsp03.dat$DATE$TIME     nmc03.dat 
   ln -sf nmc03_modify.dat               new_nmc03.dat
   timex echo 03 |vortex_bogus_intensify.exe
   ln -sf xsp06.dat$DATE$TIME     nmc06.dat 
   ln -sf nmc06_modify.dat               new_nmc06.dat
   timex echo 06 |vortex_bogus_intensify.exe  
   ln -sf xsp09.dat$DATE$TIME     nmc09.dat 
   ln -sf nmc09_modify.dat               new_nmc09.dat
   timex echo 09 |vortex_bogus_intensify.exe 



     if [ -s nmc06_modify.dat ];then
       echo " bogus_intensify vortex success " 
     fi


# == return the modified FGS OF SSI, including add vortex and modfied vortex
  cp  nmc03_modify.dat  ${ANLDAT}/xsp03.dat$DATE$TIME 
  cp  nmc06_modify.dat  ${ANLDAT}/xsp06.dat$DATE$TIME 
  cp  nmc09_modify.dat  ${ANLDAT}/xsp09.dat$DATE$TIME 
   
  rm -f ${TCRUN}/*

  rm  -f   ${INTENSIFY}/*
  rm  -f   ${TCBOGUS}/*

#============================================================================
#     llsubmit $SCRIPT/gsi_639.ksh
llsubmit  $SCRIPT/run_gsi_global.ksh
#======================================================================
#======================================================================
  cp ${LOGDIR}/vortex_bogus_intensify.out    ${BAKLOG}/vortex_bogus_intensify.out_$DATE1$TIME1
  cp ${LOGDIR}/vortex_bogus_intensify.err    ${BAKLOG}/vortex_bogus_intensify.err_$DATE1$TIME1

#===================================================================#
#===================================================================#
   timex date
#===================================================================#
#===================================================================#
#============================================================================
exit 0       # End the shell

