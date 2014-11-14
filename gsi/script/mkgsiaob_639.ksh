#!/bin/ksh
# Loadlevel Job Keywords Configuraton
# @ comment = T639
# @ job_name = mkgsiaob
# @ job_type = serial
# @ initialdir =/cmd/u/yaosh/T639L60_GSI3.3/logdir
# @ output = $(initialdir)/$(job_name).out
# @ error  = $(initialdir)/$(job_name).err
# 
# @ notification = error
# @ checkpoint = no
# @ restart = yes
# @ node_usage = shared
# @ wall_clock_limit = 00:30:00
# @ class = serial
# @ queue

 set -x
#===================================================================#
# Set up running variables, such as path and directories

  export WORKDIR=/cmd/u/yaosh/T639L60_GSI3.3
       . $WORKDIR/script/envars.ksh

#===================================================================#
  test -f $LOGDIR/DATE ||  { echo file DATE not exist ; exit 1; }
  test -f $LOGDIR/TIME ||  { echo file TIME not exist ; exit 1; }

  DATE=`cat $LOGDIR/DATE`
  TIME=`cat $LOGDIR/TIME`
  DATE1=`${EXEDIR}/smsdate $DATE$TIME +06 | cut -c1-8`
  TIME1=`${EXEDIR}/smsdate $DATE$TIME +06 | cut -c9-10`
  echo $DATE $TIME $DATE1 $TIME1
  YYYY=$(echo $DATE1 | cut -c1-4)
#===============================================================
#  Set for this job itself.  

#===================================================================#
  if [ ! -d $RUNDIR ] ; then
       mkdir -p $RUNDIR
  else 
      rm -rf $RUNDIR/*
  fi
  if [ ! -d $OBSDIR ] ; then
       mkdir -p $OBSDIR
  fi

  if [ ! -d $AOBDAT ] ; then
       mkdir -p $AOBDAT
  else
     rm -rf $AOBDAT/*
  fi

  if [ ! -d $AOBQCD ] ; then
       mkdir -p $AOBQCD
  else
     rm -rf $AOBQCD/*
  fi

  if [ ! -d $OBSDAT ] ; then
       mkdir -p $OBSDAT
  else
     rm -rf $OBSDAT/*
  fi

  if [ ! -d $SSTDAT ] ; then
       mkdir -p $SSTDAT
  fi

  if [ ! -d $BAKDAT ] ; then
       mkdir -p $BAKDAT
  fi
  if [ ! -d $BAKLOG ] ; then
       mkdir -p $BAKLOG
  fi

#==== copy history aobdat ===========================================
#== my obs bank =====================================
#  MY_OBS_BANK=/cmd/u/yaosh/Data_Bank/aobdata/${YYYY}
#===================================================================#
  #  IOBSCHK=1            #== 0: No Aob QC Check ; 1: Aob QC Check and Using OIQC Check list
  #anex IOIQC=0              #== 0: Not Using OIQC  ; 1: Using OIQC
  #===== first guess fields =============
  FGFN="checkobs+000006+"${DATE}${TIME}
  echo " fgfn " ${FGFN}

  AOB="aob"${DATE1}${TIME1}".dat"
  AOBGZ="aob"${DATE1}${TIME1}".dat.gz"
  AOBN="aob"${DATE1}${TIME1}"n.dat"
  AOBO="aob_org"${DATE1}${TIME1}".dat"
  AOBOGZ="aob_org"${DATE1}${TIME1}".dat.gz"

  cd $RUNDIR
  rm -rf *

#------------------------------------------------------------------------------
if [ -s  ${MY_OBS_BANK}/${AOBOGZ} -o  -s  ${MY_OBS_BANK}/${AOBO} ] ; then
   echo "find obs dat in my obs bank directory "
   if [ -s ${MY_OBS_BANK}/${AOBO} ] ; then
       cp  ${MY_OBS_BANK}/${AOBO}  $RUNDIR/.
   elif [ -s ${MY_OBS_BANK}/${AOBOGZ} ] ; then
       cp  ${MY_OBS_BANK}/${AOBOGZ}  $RUNDIR/.
       gunzip ${AOBOGZ}
   fi
    
   mv $RUNDIR/${AOBO}   ${AOBDAT}/${AOB}

#------------------------------------------------------------------------------
else
      ls -l ${MY_OBS_BANK}/${AOBO}
      echo "NO GET AOB DATA "
      exit 0
#------------------------------------------------------------------------------
fi
#------------------------------------------------------------------------------


  cd ${AOBDAT}
#anex=  rcp  d34n01:$GSI_OBS_BANK/aob_org$DATE1$TIME1.dat    $AOBDAT/$AOB

#===============================================

   if [ -s ${AOBDAT}/${AOB} ]    ; then
      echo "FIND AOB exist "
   else
      echo "NO AOB Warning !!!!!!!!!!!!!!!!!!! "
      exit 1
   fi

   if [ -s ${CHECKDAT}/${FGFN} ]    ; then
      echo "First guess fields exist "
   else
      echo "NO first guess fields for AOB QC "
      exit 1
   fi

#===================================================================
  ulimit -d unlimited
  ulimit -m unlimited
  ulimit -s unlimited
 
#===================================================================
  cd $RUNDIR
  rm -rf *

#===================================================================
#== 1. First Guess Field Check
     echo " Using First Guess Field to check obs "

#anex=     cp -p $AOBDAT/${AOBGZ}  ${RUNDIR}/.
#anex=     gzip -d ${RUNDIR}/${AOBGZ}
     cp -p $AOBDAT/${AOB}  ${RUNDIR}/.

     chmod 750 ${RUNDIR}/${AOB}
     chmod 750 $CHECKDAT/${FGFN} 

   cd $RUNDIR
#==== Tao Shiwei 20041222 modified the error for fgs check
#====  for T213L60 model ============
   exe_fgschk=p-fgs-chk041222_new.x
#====  for T639L60_2012 model ============
   exe_fgschk=p-fgs-chk-639_20100720
   cp -p $EXEDIR/${exe_fgschk}    $RUNDIR/.
   #====== input files =========================
   cp -p $RUNDIR/${AOB}             $RUNDIR/AOB
   cp -p $CHECKDAT/${FGFN}           T213FGS
   #====== output files ========================
   ln -s $RUNDIR/ack.dat            fort.4

   timex $RUNDIR/${exe_fgschk}
   test  $? = 0  ||  { echo first-guess checking error ;  exit ;  }


#===================================================================
#==== 2.  Buddy Check
#     echo " ======= Buddy Check ======= "
#     rm -f $RUNDIR/fort.*
#
#     exe_buddychk=buddycheck_20100720
#     cp -p ${EXEDIR}/${exe_buddychk}     $RUNDIR/.
#
#   #====== input files =========================
#     ln -s $RUNDIR/ack.dat               fort.13
#   #====== output files ========================
#     ln -s $RUNDIR/ackn.dat              fort.15
#
#     timex $RUNDIR/${exe_buddychk}
#     test  $? = 0  ||  { echo buddycheck  error ; exit ; }
#
#===================================================================
#==== 3.  Recover aobdata
#     echo " =======Recover aobdata ======= "
#     rm -f fort.*
#
#     exe_recover=recover_20100720
#     cp -p ${EXEDIR}/${exe_recover}       $RUNDIR/.
#
   #====== input files =========================
#     ln -s $RUNDIR/${AOB}                 fort.2
#     ln -s $RUNDIR/ackn.dat               fort.4
#   #====== output files ========================
#     ln -s $RUNDIR/${AOBN}                fort.3

#     timex $RUNDIR/${exe_recover}
#     test  $? = 0  ||  { echo recover  error ;  exit ; }

#     rm -f $RUNDIR/fort.*
#
#     mv $RUNDIR/${AOBN}   ${AOBQCD}/${AOBN}

#======= Finished the OBQC part. ===============================#


#=================================================================
# Transfer aob format data to ssiaob format within Error-Info and Q-Info
##=================================================================
  cd $RUNDIR
  rm -rf ${RUNDIR}/*

  cp -p $AOBDAT/${AOB}  ${RUNDIR}/.
  #====== input files =========================
#    ln -s $AOBQCD/${AOBN}   ./AOBDAT
    ln -s $RUNDIR/${AOB}   ./AOBDAT
  #====== OUTPUT files = gsiaob${DATE1}${TIME1}.dat########################
    ln -s $OBSDAT/gsiaob${DATE1}${TIME1}.dat   ./ssiaob_lite

    cp -p  $EXEDIR/mkgsiaob_20090514    ./mkgsiaob.x

    timex ./mkgsiaob.x

    test $? = 0 || { echo mkgsiaob.x  error ; exit 1; }
    echo  mkgsiaob.x success $DATE1$TIME1

#== backup for add TC bogus data when restarting tc BDA job ========
    cp $OBSDAT/gsiaob${DATE1}${TIME1}.dat  $OBSDAT/gsiaob${DATE1}${TIME1}_noBDA.dat

#===============================================================================
#==== submit next job card for T639L60_2012_GSI   ==========
     llsubmit $SCRIPT/mkgsisst_639.ksh

#=============================================================================#
#  cp -p  $LOGDIR/mkgsiaob.out    $BAKLOG/mkgsiaob.out_$DATE1$TIME1 
#  cp -p  $LOGDIR/mkgsiaob.err    $BAKLOG/mkgsiaob.err_$DATE1$TIME1

#=============================================================================#
  exit 0
