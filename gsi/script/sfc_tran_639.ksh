#!/bin/ksh
# Loadlevel Job Keywords Configuraton
# @ comment = T639
# @ job_name = sfc_tran
# @ job_type = serial
# @ initialdir =/cmd/u/yaosh/T639L60_GSI3.3/logdir
# @ output = $(initialdir)/$(job_name).out
# @ error  = $(initialdir)/$(job_name).err
#
# @ notification = error
# @ checkpoint = no
# @ restart = yes
# @ node_usage = shared
# @ wall_clock_limit = 01:20:00
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
  else 
      rm -rf $RUNDIR/*
  fi

  if [ ! -d $GSIDIR ] ; then
       mkdir -p $GSIDIR
  fi

  if [ ! -d $GSISFC ] ; then
       mkdir -p $GSISFC
  else 
      rm -rf $GSISFC/*
  fi

  if [ ! -d $BAKDAT ] ; then
       mkdir -p $BAKDAT
  fi
  if [ ! -d $BAKLOG ] ; then
       mkdir -p $BAKLOG
  fi

##+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 test -d $EXEDIR ||  { echo $EXEDIR not a directory ; exit 1; }
 test -d $SCRIPT ||  { echo $SCRDIR not a directory ; exit 1; }
 test -d $RUNDIR ||  { echo $RUNDIR not a directory ; exit 1; }
 test -d $LOGDIR ||  { echo $LOGDIR not a directory ; exit 1; }
 test -d $SFCDAT ||  { echo $SFCDAT not a directory ; exit 1; }
 test -d $GSISFC ||  { echo $GSISFC not a directory ; exit 1; }

#====================================
  cd $RUNDIR 
  rm -rf $RUNDIR/*

#========set model resolution and gsi resolution 
  lat1=640
  lon1=1280
#=====================================
#==== set time
  test -f $LOGDIR/DATE ||  { echo file DATE not exist ; \
                        exit 1; }
  test -f $LOGDIR/TIME ||  { echo file TIME not exist ; \
                        exit 1; }
  DATE=`cat $LOGDIR/DATE`
  TIME=`cat $LOGDIR/TIME`
  DATE1=`${EXEDIR}/smsdate ${DATE}${TIME} +06 | cut -c1-8`
  TIME1=`${EXEDIR}/smsdate ${DATE}${TIME} +06 | cut -c9-10`
  echo $DATE $TIME $DATE1 $TIME1

  YEAR=`echo $DATE | cut -c1-4`
  MONTH=`echo $DATE | cut -c5-6`
  DAY=`echo $DATE | cut -c7-8`

  ISFCUSE=1
  if [ $ISFCUSE -eq 1 ] ; then
      echo "    Using 6 hours forecast sfcdata                              "
      echo "=============================SFC_REGRID========================="

#=====================================
    cd $RUNDIR

    for NSTEP in 1 2 3
    do
    rm -f $RUNDIR/*
    case "$NSTEP" in
         1) STEP=03 ;;
         2) STEP=06 ;;
         3) STEP=09 ;;
    esac

#==== make sfc date namelist for head information
 cat << EOF > sfcname.anl
 &NAMANAL
   idate(1)=$TIME,idate(2)=$MONTH,idate(3)=$DAY,idate(4)=$YEAR,
   fhour4=$STEP
/
EOF

#======================================================================
  test -f $GSIFIX/LSM+VEG_CLIMATE_639 ||  { echo file LSM+VEG_CLIMATE_639 not exist ; \
                        exit 1; }
  ln -sf $GSIFIX/LSM+VEG_CLIMATE_639                    ./VEG_CLIMATE 
#======================================================================
  ln -sf $SFCDAT/mod_uv_bottom0000${STEP}.t${DATE}${TIME}z.gg1280*640   ./model_uv
  ln -sf $SFCDAT/Tsoil+0000${STEP}+${DATE}${TIME}             ./Tsoil
  ln -sf $SFCDAT/Wsoil+0000${STEP}+${DATE}${TIME}             ./Wsoil
  ln -sf $SFCDAT/SKT+10W+0000${STEP}+${DATE}${TIME}           ./SKT+10W

  cp -p  $EXEDIR/t639togsi_new.exe          $RUNDIR/t639togsi_new.exe

  echo ' Read 6hrs surface field '

  ${RUNDIR}/t639togsi_new.exe < sfcname.anl

  if [ $? -ne 0 ] ; then
       echo t639togsi.exe error
       exit 1
  fi
 
  echo  mksfcdata success for $DATE1$TIME1

  mv sfcanl_t639     $GSISFC/sfcanl.${lon1}x${lat1}.t${DATE}${TIME}z_${STEP}

   done

  else
	  echo Not Using 6hrs fcst sfcdata.
  fi

#===============add by anex chan ==============================

#===================================================================
#if [ ${DATE}${TIME} -lt 2013080800 ] ; 	then
  llsubmit $SCRIPT/mkgsiaob_639.ksh
#fi
#===============================================================================

#===============================================================================
  exit 0
