## This is a head file for loadleveler job#
#!/bin/ksh
# @ comment=T639
# @ job_type=serial
# @ job_name=gridsurf
# @ input= /dev/null
# @ initialdir =/cmd/u/yaosh/T639L60_GSI3.3/logdir
# @ output = $(initialdir)/$(job_name).out
# @ error =  $(initialdir)/$(job_name).err
# 
# @ notification = complete
# @ checkpoint = no
# @ restart = yes
# @ class= serial
# @ node_usage = shared
## @ node = 1
## @ tasks_per_node = 16
## @ network.MPI = sn_single,not_shared,US
# @ wall_clock_limit = 00:50:00, 00:50:00
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


#========= grid session  ---> ICMGG0001INIT
  rm -f $RUNDIR/*
  cd $RUNDIR
#======== input file ===================================================================
# it needs LSM_639_RED,climat_XX,red_639 as input fix files. (The realtime sst is optional.)
# command format: grid.exe input_grib_file  ( sst )  output_grib_file
#== treat soil tempature and moisture,asq,src# 
  test -s $CLIDAT/LSM_639_RED || { echo climat file $CLIDAT/LSM_639_RED not found ;  exit 1 ; }
  test -s $CLIDAT/suborog.init || { echo climat file $CLIDAT/suborog.init not found ; exit 1 ; }
  test -s $ANLDAT/ICMGG0001+000036+$DATE$TIME || { echo no file $ANLDAT/ICMGG0001+000036+$DATE$TIME ; exit 1 ; }

  cp -p $ANLDAT/ICMGG0001+000036+$DATE$TIME   $RUNDIR/input

cp -p  $CLIDAT/LSM_639_RED   $RUNDIR/
cp -p  $CLIDAT/red_639      $RUNDIR/red_grid

cp -p  $SSTDAT/sst639r.dat   $RUNDIR/sst639r.dat

for i in 01 02 03 04 05 06 07 08 09 10 11 12
do
cp -p  $CLIDAT/climat.$i.dat $RUNDIR/
done

 cp ${EXEDIR}/grid_639.exe.free    $RUNDIR/grid_639.exe
 $RUNDIR/grid_639.exe input sst639r.dat output 

 test $? = 0 || { echo grid.exe error;  exit 1; }

mv $RUNDIR/output $MODDAT/ICMGG0001INIT+$DATE1$TIME1
cat $CLIDAT/suborog.init >>$MODDAT/ICMGG0001INIT+$DATE1$TIME1

#======================================================================
#============= add by anex chan for backup the init data=================================#
  cp -p  $MODDAT/ICMGG0001INIT+$DATE1$TIME1  $BAKDAT/data/ICMGG0001INIT+$DATE1$TIME1
  cp -p  $MODDAT/ICMSH0001INIT+$DATE1$TIME1  $BAKDAT/data/ICMSH0001INIT+$DATE1$TIME1 
#======================================================================
#=anex= llsubmit $SCRIPT/reanal_639.ksh
 llsubmit $SCRIPT/model_639.ksh
#=========================================================================#
#  cp -p  $LOGDIR/gridsurf.out    $BAKLOG/gridsurf.out_$DATE1$TIME1
#  cp -p  $LOGDIR/gridsurf.err    $BAKLOG/gridsurf.err_$DATE1$TIME1
#===================================================================#
  exit 0
 
