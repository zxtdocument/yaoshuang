## This is a head file for loadleveler job#
#!/bin/ksh
# @ comment=T639
# @ job_type=serial
# @ job_name=gridspec
# @ input= /dev/null
# @ initialdir =/cmd/u/yaosh/T639L60_GSI3.3/logdir
# @ output = $(initialdir)/$(job_name).out
# @ error =  $(initialdir)/$(job_name).err
# 
# @ notification = complete
# @ checkpoint = no
# @ restart = yes
# @ class=  serial
# @ wall_clock_limit = 02:50:00, 02:50:00
# @ node_usage = shared
# @ queue

#===================================================================#
  set -x

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

  if [ ! -d $MODDAT ] ; then
     mkdir -p $MODDAT
#  else
#     rm -rf $MODDAT/*
  fi

  if [ ! -d $BAKDAT ] ; then
       mkdir -p $BAKDAT
  fi

  if [ ! -d $BAKLOG ] ; then
       mkdir -p $BAKLOG
  fi

#===================================================================#

#== to check date time information ===============
test -s $LOGDIR/DATE ||  { echo file DATE not exist ; exit 1; }
test -s $LOGDIR/TIME ||  { echo file TIME not exist ; exit 1; }

DATE=`cat $LOGDIR/DATE`
TIME=`cat $LOGDIR/TIME`
DATE1=`$EXEDIR/smsdate $DATE$TIME +06 | cut -c1-8`
TIME1=`$EXEDIR/smsdate $DATE$TIME +06 | cut -c9-10`
echo $DATE $TIME $DATE1 $TIME1


 test -d $SCRIPT ||  { echo $SCRIPT not a directory ; exit 1; }
 test -d $CLIDAT ||  { echo $CLIDAT not a directory ; exit 1; }
 test -d $MODDAT ||  { echo $MODDAT not a directory ; exit 1; }
 test -d $LOGDIR ||  { echo $LOGDIR not a directory ; exit 1; }
 test -d $RUNDIR ||  { echo $RUNDIR not a directory ; exit 1; }
 test -d $EXEDIR ||  { echo $EXEDIR not a directory ; exit 1; }



#==== encode session  ---> ICMSH0001INIT ==========
#==== It needs $CLIDAT/red_639 and $ANLDAT/zsp$TIME1.dat$DATE1 as input files, ==========
#==== output file is $MODDAT/ICMSH0001INIT+$DATE1$TIME1 . ==========
  cd $RUNDIR
  rm -rf $RUNDIR/*
#==== check input files ==========
  cp -p $CLIDAT/red_639    $RUNDIR/red_grid
  test -s $ANLDAT/zsp$TIME1.dat$DATE1 || { echo no file $ANLDAT/zsp$TIME1.dat$DATE1 ;   exit 1; }

#==== output file  ==========
  ln -s $MODDAT/ICMSH0001INIT+$DATE1$TIME1    $RUNDIR/ICMSH0001INIT

  cp ${EXEDIR}/oiencode.exe.63960.24  $RUNDIR/oiencode.exe

  ${RUNDIR}/oiencode.exe  $ANLDAT/zsp$TIME1.dat$DATE1 
  test $? = 0 || { echo oiencode.exe error ; \
                   exit 1; }
  echo oiencode.exe success $DATE1$TIME1

test -s $CLIDAT/sporog.init || { echo climat file $CLIDAT/sporog.init not found ; exit 1 ; }
cat $CLIDAT/sporog.init >>$MODDAT/ICMSH0001INIT+$DATE1$TIME1

#======================================================================
   llsubmit $SCRIPT/gridsurf_639.ksh
#=========================================================================#
##  cp -p  $LOGDIR/gridspec.out    $BAKLOG/gridspec.out_$DATE1$TIME1
#  cp -p  $LOGDIR/gridspec.err    $BAKLOG/gridspec.err_$DATE1$TIME1
#===================================================================#
  exit 0
 
