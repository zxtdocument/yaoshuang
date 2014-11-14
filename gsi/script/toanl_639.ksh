#!/bin/ksh
##   This is a job command file of toanl.
## Loadlevel Job Keywords Configuraton
# @ comment = T639
# @ job_name = toanl
# @ job_type = serial
# @ initialdir =/cmd/u/yaosh/T639L60_GSI3.3/logdir
##@ input = /dev/null
# @ output = $(initialdir)/$(job_name).out
# @ error  = $(initialdir)/$(job_name).err
#
# @ notification = error
# @ checkpoint = no
# @ restart = yes
# @ node_usage = shared
# @ wall_clock_limit = 01:40:00
# @ class = serial
# @ queue

  set -x
  set -a
#===================================================================#
# Set up running variables, such as path and directories

  export WORKDIR=/cmd/u/yaosh/T639L60_GSI3.3
       . $WORKDIR/script/envars.ksh

#===================================================================#
  if [ ! -d $RUNDIR ] ; then
       mkdir -p $RUNDIR
  else
       rm -rf $RUNDIR/*
  fi
  if [ ! -d $ANLDAT ] ; then
       mkdir -p $ANLDAT
  else
       rm -rf ${ANLDAT}/*
  fi
  if [ ! -d $GSIFGS ] ; then
       mkdir -p $GSIFGS
  else
       rm -rf ${GSIFGS}/*
  fi
  if [ ! -d $BAKDAT ] ; then
       mkdir -p $BAKDAT
  fi
  if [ ! -d $BAKLOG ] ; then
       mkdir -p $BAKLOG
  fi
#===================================================================#
  test -d $MODDAT ||  { echo $MODDAT not a directory ; exit 1; }
  test -d $EXEDIR ||  { echo $EXEDIR not a directory ; exit 1; }
  test -f $LOGDIR/DATE ||  { echo file DATE not exist ; exit 1; }
  test -f $LOGDIR/TIME ||  { echo file TIME not exist ; exit 1; }

#==================================================================#
  DATE=`cat $LOGDIR/DATE`
  TIME=`cat $LOGDIR/TIME`
  DATE1=`${EXEDIR}/smsdate $DATE$TIME +06 | cut -c1-8`
  TIME1=`${EXEDIR}/smsdate $DATE$TIME +06 | cut -c9-10`
  echo $DATE $TIME $DATE1 $TIME1

#====== toanl sesson ============================
#====== command format toanl.exe input_spec_grib_file input_GG_grib_file
  rm -rf $RUNDIR/*
  cd $RUNDIR

#============ Time Step is 10 mins, 000018-->3hrs, 
#============ Time Step is 10 mins, 000036-->6hrs, 
#============ Time Step is 10 mins, 000054-->9hrs, 

  for NSTEP in 1 2 3
  do
    rm -rf *
    case "$NSTEP" in
         1) STEP=000018 ;;
         2) STEP=000036 ;;
         3) STEP=000054 ;;
    esac
    FCHR=`expr $STEP / 6 `
    if [ $FCHR -lt "10" ] ; then
          FCHR=0$FCHR
    fi


#====== check input files   
 test -s $ANLFIX/terrain_cof.dat_639 || { echo no file $CLIDAT/terrain_cof.dat_639; exit 1; }
 test -s $ANLFIX/sigio_head_sample || { echo no file $CLIDAT/sigio_head_sample; exit 1; }
 test -s $MODDAT/ICMSH0001+${STEP}+$DATE$TIME || { echo no file $MODDAT/ICMSH0001+${STEP}+$DATE$TIME; exit 1; }
 test -s $MODDAT/ICMGG0001+${STEP}+$DATE$TIME || { echo no file $MODDAT/ICMGG0001+${STEP}+$DATE$TIME; exit 1; }

#====== input files
#anex ln -sf $ANLFIX/terrain_cof.dat_639      .
#anex ln -sf $ANLFIX/sigio_head_sample        .
#anex ln -s  $ANLFIX/t639_fort.31             fort.31
#anex ln -s  $ANLFIX/t639_fort.32             fort.32
 cp -p  $ANLFIX/terrain_cof.dat_639      .
 cp -p  $ANLFIX/sigio_head_sample        .
 cp -p  $ANLFIX/t639_fort.31             fort.31
 cp -p  $ANLFIX/t639_fort.32             fort.32

#====== output file
ln -s $ANLDAT/xsp${FCHR}.dat$DATE$TIME   fort.18

cp $EXEDIR/toanlt639l60.exe     $RUNDIR/toanlt639l60.exe

$RUNDIR/toanlt639l60.exe $MODDAT/ICMSH0001+${STEP}+$DATE$TIME $MODDAT/ICMGG0001+${STEP}+$DATE$TIME 

test $? = 0 || { echo toanl.exe error; exit 1; }
test -s  $ANLDAT/xsp${FCHR}.dat$DATE$TIME || { echo file $ANLDAT/xsp${FCHR}.dat$DATE$TIME not created ;  exit 1; }
cp $ANLDAT/xsp${FCHR}.dat$DATE$TIME  $GSIFGS/


# if [ ${FCHR} -eq "06" ]; then
#    if [ -d $WORKDIR/diagnosis/data ]; then
#      cp $ANLDAT/xsp${FCHR}.dat$DATE$TIME  $WORKDIR/diagnosis/data/xsp${FCHR}.dat$DATE$TIME  
#    fi
# fi

echo toanl.exe success $DATE$TIME $STEP

rm -rf fort.31 fort.32 fort.18

done

##========= Toanl Session Finished ======================================
  echo "toanl finished for 3 times "


#==========Save 000036 forecast data for next time grid.  ==========================
  test -s $MODDAT/ICMGG0001+000036+$DATE$TIME || { echo no file $MODDAT/ICMGG0001+000036+$DATE$TIME; exit 1; }
  cp   -p $MODDAT/ICMGG0001+000036+$DATE$TIME    $ANLDAT/.

#===================================================================#
#==== Model Post 3-D fields variables for Observation First guess check.
  if [  -f ${MODDAT}/ICMPL0001+000036+$DATE$TIME ] ; then
      echo  Making post-fileds for obs. check.
      llsubmit   $SCRIPT/post4obs_639.ksh
  else
      echo no file ${MODDAT}/ICMPL0001+000036+$DATE$TIME
      echo Not Making post-fileds for obs. check.
      exit 1
  fi

#===============================================================================
#===================================================================#
  exit 0
