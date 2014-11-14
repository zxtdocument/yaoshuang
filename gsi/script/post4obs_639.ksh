#   This is a job command file of post4obs.
#!/bin/ksh
# Loadlevel Job Keywords Configuraton
# @ comment = T639
# @ job_name = post4obs
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
# @ wall_clock_limit = 00:15:00
# @ class = serial
# @ queue

  set -x
#===================================================================#
# Set up running variables, such as path and directories

  export WORKDIR=/cmd/u/yaosh/T639L60_GSI3.3
       . $WORKDIR/script/envars.ksh

#===================================================================#
  if [ ! -d $RUNDIR ] ; then
       mkdir -p $RUNDIR
  fi
  if [ ! -d $CHECKDAT ] ; then
       mkdir -p $CHECKDAT
  else 
      rm -rf $CHECKDAT/*
  fi

  if [ ! -d $BAKDAT ] ; then
       mkdir -p $BAKDAT
  fi
  if [ ! -d $BAKLOG ] ; then
       mkdir -p $BAKLOG
  fi


  test -f $LOGDIR/DATE ||  { echo file DATE not exist ; exit 1; }
  test -f $LOGDIR/TIME ||  { echo file TIME not exist ; exit 1; }
  test -d $EXEDIR ||  { echo $EXEDIR not a directory ; exit 1; }
#==================================================================#
  DATE=`cat $LOGDIR/DATE`
  TIME=`cat $LOGDIR/TIME`
  DATE1=`${EXEDIR}/smsdate $DATE$TIME +06 | cut -c1-8`
  TIME1=`${EXEDIR}/smsdate $DATE$TIME +06 | cut -c9-10`
  echo $DATE $TIME $DATE1 $TIME1

  test -f $MODDAT/ICMPL0001+000036+$DATE$TIME ||  { echo file ICMPL0001+000018+$DATE$TIME not exist ; exit 1; }

  cd  $RUNDIR
  rm -rf $RUNDIR/*
#===================================================================#
#==== longitude and latitude grid ==================================
  cp   $EXEDIR/wgrib     $RUNDIR/.

  wgrib -s $MODDAT/ICMPL0001+000036+$DATE$TIME | grep ':Z:' > list
  wgrib -s $MODDAT/ICMPL0001+000036+$DATE$TIME | grep ':T:' >> list
  wgrib -s $MODDAT/ICMPL0001+000036+$DATE$TIME | grep ':VO:' >> list
  wgrib -s $MODDAT/ICMPL0001+000036+$DATE$TIME | grep ':D:' >> list
  wgrib -s $MODDAT/ICMPL0001+000036+$DATE$TIME | grep ':R:' >> list
  wgrib -i -grib -append -o ./tmp+000036+$DATE$TIME $MODDAT/ICMPL0001+000036+$DATE$TIME < list

#====  lonlatuv.exe read pnm in clidat
#anex  ln -sf $ANLFIX/t639_pnm ./pnm
  cp -p $ANLFIX/t639_pnm        $RUNDIR/pnm
  cp -p $EXEDIR/lonlatuv_t639.exe         $RUNDIR/.

  $RUNDIR/lonlatuv_t639.exe ./tmp+000036+$DATE$TIME $CHECKDAT/checkobs+000006+$DATE$TIME 
  test -f $CHECKDAT/checkobs+000006+$DATE$TIME || { echo checkobs dat file not existing ;  }
#============================================================================#
#===============================================================================
#==== Model Post surface variables for GSI anlysis. =========================
    llsubmit $SCRIPT/post4sfc_639.ksh

#===============================================================================
#  cp -p  $LOGDIR/post4obs.out    $BAKLOG/post4obs.out_$DATE$TIME 
#  cp -p  $LOGDIR/post4obs.err    $BAKLOG/post4obs.err_$DATE$TIME

#============================================================================#
  exit 0
