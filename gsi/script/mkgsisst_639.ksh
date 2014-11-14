## This is a head file for loadleveler job#
#!/bin/ksh
# @ comment=T639
# @ job_type=parallel
# @ job_name=mkgsisst
# @ input= /dev/null
# @ initialdir =/cmd/u/yaosh/T639L60_GSI3.3/logdir
# @ output = $(initialdir)/$(job_name).out
# @ error =  $(initialdir)/$(job_name).err
# 
# @ notification = complete
# @ checkpoint = no
# @ restart = yes
# @ node_usage = shared
# @ node = 1
# @ tasks_per_node = 4
# @ network.MPI = sn_single,not_shared,US
# @ class= normal
# @ environment= COPY_ALL
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
 
#===============================================================
#  Set for this job itself.  

  export MP_EUILIBPATH=${SSTDAT}:$MP_EUILIBPATH

#===================================================================#
  if [ ! -d $RUNDIR ] ; then
       mkdir -p $RUNDIR
  else 
      rm -rf $RUNDIR/*
  fi
  if [ ! -d $OBSDIR ] ; then
       mkdir -p $OBSDIR
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

#=================================================================
# Transfer SST data to INIT format 
##=================================================================
  cd $RUNDIR
  rm -rf $RUNDIR/*
#======================================================================
#== sst0.grib is used to provide grib head, sst.$DATE is real SST, sst$DATE.grib
#== is SST with GRIB format, which is the output of sst2grib.exe and input of
#==  insst.exe. 
# ==  to get SST data  ===============
YYYY=$(echo $DATE1 | cut -c1-4)
#zt SSTBANK=/cmd/u/yaosh/Data_Bank/sst_data/${YYYY}
LASTDATE=`$EXEDIR/smsdate -D ${DATE1} -1`
#SSTBANK=$SSTBANK/`echo ${LASTDATE} |cut -c1-4`
ls -l $SSTBANK/sst.${LASTDATE}*
if [ -s $SSTBANK/sst.${LASTDATE}.Z -o -s $SSTBANK/sst.${LASTDATE} ] ; then
   echo find sst file in my sst bank library
else

   echo "NO GET SST DATA "
   exit 0

fi


 cd $SSTDAT

if [ -s $SSTDAT/sst639r.dat ]; then                                                                             
    echo  old file $SSTDAT/sst639r.dat exist
    mv  $SSTDAT/sst639r.dat    $SSTDAT/sst639r.dat_old
else
    echo  old file $SSTDAT/sst639r.dat no exist
fi

 cp -p $CLIDAT/sst0_639.grib  $SSTDAT/sst0_639.grib
 cp -p $CLIDAT/lsm.639.grib  $SSTDAT/lsm


   thisday=$DATE1
   iday=0
   while [ $iday -le 15 ]
   do
     yester=`$EXEDIR/smsdate -D ${thisday} -1`
     echo Thisday is ${thisday} Yesterday is ${yester}
     if [ -s $SSTBANK/sst.${yester}.Z -o -s $SSTBANK/sst.$yester ] ; then
        if [ -s $SSTBANK/sst.${yester}.Z ] ; then
           echo 'Using compressed ${yester} SST  for ${DATE1} '
		   cp -p $SSTBANK/sst.${yester}.Z  $SSTDAT/
		   uncompress $SSTDAT/sst.${yester}.Z
		cp -p $SSTDAT/sst.${yester}  $SSTDAT/sst.$yester
        elif [ -s $SSTBANK/sst.$yester ] ; then
           echo 'Using ${yester} SST  for ${DATE1} '
           cp -p $SSTBANK/sst.$yester $SSTDAT/sst.$yester
        fi

	#==== cp sst file for draw typhoon track in post ========

        cd $SSTDAT

        export MP_EUILIBPATH=${SSTDAT}:$MP_EUILIBPATH

        cp $EXEDIR/sst2grib.exe  $SSTDAT/
        cp $EXEDIR/libmpi_r.a  $SSTDAT/

        $SSTDAT/sst2grib.exe  ./sst0_639.grib  sst.grib   sst.$yester
        cp $EXEDIR/intsst_639.exe    $SSTDAT/
        $SSTDAT/intsst_639.exe -i sst.grib -L lsm -o sst639r.grib
        cp $EXEDIR/decode_sst.exe    $SSTDAT/
        $SSTDAT/decode_sst.exe sst639r.grib  sst639r.dat


        if [ $? -eq 0 ] ; then
           echo ${yester} sst ready for ${DATE1} >$LOGDIR/realsst_ready.flag
           chmod 644 $SSTDAT/sst639r.dat
           break
        fi

     fi
     thisday=${yester}
     iday=` expr $iday + 1 `
   done

   if [ $iday -ge 15 ] ; then
      echo "sst from ${yester} to ${DATE1} not exist for $DATE1 " 
      exit 1
   fi

if [  -s $SSTDAT/sst639r.dat ]; then
    echo   file $SSTDAT/sst639_togrid.dat exist 
else
    echo   no find file $SSTDAT/sst639_togrid.dat exist 
    exit 1
fi

#===============================================================================
#==== submit next job card for gsi   ==========
llsubmit $SCRIPT/mkgsisat_639.ksh
#=============================================================================#
#anex=  cp -p  $LOGDIR/mkgsisst.out    $BAKLOG/mkgsisst.out_$DATE1$TIME1 
#anex=  cp -p  $LOGDIR/mkgsisst.err    $BAKLOG/mkgsisst.err_$DATE1$TIME1

#=============================================================================#
  exit 0
