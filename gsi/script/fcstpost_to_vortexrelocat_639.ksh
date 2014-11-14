#!/bin/ksh
##Loadlevel Job Keywords Configuraton
# @ comment = T639
# @ job_name = fcstpost_vortexrelocat
## @ job_type = serial
# @ job_type = parallel
# @ initialdir =/cmd/u/yaosh/T639L60_GSI3.3/logdir
##@ input = /dev/null
# @ output = $(initialdir)/$(job_name).out
# @ error  = $(initialdir)/$(job_name).err
#
# @ notification = error
# @ checkpoint = no
# @ restart = yes
# @ node = 1
# @ tasks_per_node = 8
# @ node_usage = shared
# @ wall_clock_limit = 03:00:00
# @ class = normal
## @ class = serial
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

  if [ ! -d $POSTDAT ] ; then
       mkdir -p $POSTDAT
#  else 
#      rm -rf $POSTDAT/*
  fi


  if [ ! -d $BAKDAT ] ; then
       mkdir -p $BAKDAT
  fi

  if [ ! -d $BAKLOG ] ; then
       mkdir -p $BAKLOG
  fi

#==================================================================
  test -d $LOGDIR ||  { echo $LOGDIR not a directory, NO DATE/TIME ; exit 1; }
  test -f $LOGDIR/DATE ||  { echo file DATEGL not exist ; \
                        exit 1; }
  test -f $LOGDIR/TIME ||  { echo file TIMEGL not exist ; \
                        exit 1; }

  DATE=`cat $LOGDIR/DATE`
  TIME=`cat $LOGDIR/TIME`
  echo $DATE $TIME
#==================================================================
  cd $POSTDAT
#  rm -rf $POSTDAT/*
#===================================================================#
# ICMGG ---- Gaussian Grid Fieldsa(2D)
# ICMSH ---- Spectral Coef Fields(3D, on Eta-Level,i.e. Hybrid Coordinate.)
# ICMPL ---- Spectral Coef Fields(3D, on P-Level,Post-processed by IFS-Model)
#===================================================================#
#==== . Post Processing   Part =================
  echo 'Post-processing Step '

  cp -p $ANLFIX/t639_pnm         $POSTDAT/pnm
  cp -p $CLIDAT/gauss.639   $POSTDAT/

#==================! 2:  llsubmit postp_sel*.cmd---================#
for j in  0 3 6 9
do
  starttime=`date +%H:%M`
  echo $starttime

  cd $POSTDAT

  FFFF="$j"
  let i=FFFF*6
  FTIME=` $EXEDIR/i6 $i `
  FTIMEH=` expr $i \/ 6 `
  FTIMEH=` $EXEDIR/i6 $FTIMEH `

 test -s $MODDAT/ICMPL0001+$FTIME+$DATE$TIME || { echo no file $MODDAT/ICMPL0001+$FTIME+$DATE$TIME; exit 1; }
 test -s $MODDAT/ICMSH0001+$FTIME+$DATE$TIME || { echo no file $MODDAT/ICMSH0001+$FTIME+$DATE$TIME; exit 1; }
 test -s $MODDAT/ICMGG0001+$FTIME+$DATE$TIME || { echo no file $MODDAT/ICMGG0001+$FTIME+$DATE$TIME; exit 1; }

 #======== longitude and latitude grid

 cp  $MODDAT/ICMPL0001+$FTIME+$DATE$TIME  $POSTDAT/ICMPL0001.grb_$FTIMEH

 $EXEDIR/wgrib -s $MODDAT/ICMSH0001+$FTIME+$DATE$TIME | grep ':LNSP:' > list_$FTIMEH
 $EXEDIR/wgrib -i -grib -append -o ICMPL0001.grb_$FTIMEH $MODDAT/ICMSH0001+$FTIME+$DATE$TIME < list_$FTIMEH
 #===== lonlat.exe read pnm  ==========================
 test -s $POSTDAT/pnm || cp $CLIDAT/t639_pnm  $POSTDAT/pnm

 #===== serial execute ==========================
 #=anex= $EXEDIR/lonlat_t639.exe ICMPL0001.grb_$FTIMEH $POSTDAT/ICMPL0001+$FTIMEH+$DATE$TIME 
 #===== mpi execute ==========================
 $EXEDIR/lonlat_mpi_t639.exe ICMPL0001.grb_$FTIMEH $POSTDAT/ICMPL0001+$FTIMEH+$DATE$TIME 

 echo ICMPL0001+$FTIMEH+$DATE$TIME
 chmod 755 ICMPL0001+$FTIMEH+$DATE$TIME

 $EXEDIR/wgrib -s $MODDAT/ICMGG0001+$FTIME+$DATE$TIME | grep ':MSL:' > list2_$FTIMEH
 $EXEDIR/wgrib -s $MODDAT/ICMGG0001+$FTIME+$DATE$TIME | grep ':Q:'| grep 'mb' >> list2_$FTIMEH
 $EXEDIR/wgrib -i -grib -o mslq.dat_$FTIMEH $MODDAT/ICMGG0001+$FTIME+$DATE$TIME < list2_$FTIMEH

 test -s $POSTDAT/gauss.639 || cp $CLIDAT/gauss.639  $POSTDAT/

 $EXEDIR/decode_red2full.exe mslq.dat_$FTIMEH mslqg.dat_$FTIMEH

 #=anex= $EXEDIR/intgl_639.exe mslqg.dat_$FTIMEH mslq+$FTIMEH+$DATE$TIME
 $EXEDIR/pos_intgl_t639.x mslqg.dat_$FTIMEH mslq+$FTIMEH+$DATE$TIME
 chmod 755 mslq+$FTIMEH+$DATE$TIME

 #anex $EXEDIR/pos_diag_925_36_v2.x $DATE$TIME$FTIMEH

 #===NO.3===gauss grid====#
 $EXEDIR/wgrib -s ${MODDAT}/ICMGG0001+$FTIME+$DATE$TIME | grep ':SKT:' > list3_$FTIMEH
 $EXEDIR/wgrib -s ${MODDAT}/ICMGG0001+$FTIME+$DATE$TIME | grep ':10U:' >> list3_$FTIMEH
 $EXEDIR/wgrib -s ${MODDAT}/ICMGG0001+$FTIME+$DATE$TIME | grep ':10V:' >> list3_$FTIMEH
 $EXEDIR/wgrib -s ${MODDAT}/ICMGG0001+$FTIME+$DATE$TIME | grep ':2T:' >> list3_$FTIMEH
 $EXEDIR/wgrib -s ${MODDAT}/ICMGG0001+$FTIME+$DATE$TIME | grep ':SSW:' >> list3_$FTIMEH
 $EXEDIR/wgrib -s ${MODDAT}/ICMGG0001+$FTIME+$DATE$TIME | grep ':DSW:' >> list3_$FTIMEH
 $EXEDIR/wgrib -s ${MODDAT}/ICMGG0001+$FTIME+$DATE$TIME | grep ':CDSW:' >> list3_$FTIMEH
 $EXEDIR/wgrib -s ${MODDAT}/ICMGG0001+$FTIME+$DATE$TIME | grep ':SWL4:' >> list3_$FTIMEH
 $EXEDIR/wgrib -s ${MODDAT}/ICMGG0001+$FTIME+$DATE$TIME | grep ':ST:' >> list3_$FTIMEH
 $EXEDIR/wgrib -s ${MODDAT}/ICMGG0001+$FTIME+$DATE$TIME | grep ':DST:' >> list3_$FTIMEH
 $EXEDIR/wgrib -s ${MODDAT}/ICMGG0001+$FTIME+$DATE$TIME | grep ':CDST:' >> list3_$FTIMEH
 $EXEDIR/wgrib -s ${MODDAT}/ICMGG0001+$FTIME+$DATE$TIME | grep ':STL4:' >> list3_$FTIMEH

 $EXEDIR/wgrib -i -grib -o pl.grb_$FTIMEH $MODDAT/ICMGG0001+$FTIME+$DATE$TIME <list3_$FTIMEH
 $EXEDIR/wgrib -s pl.grb_$FTIMEH >list4_$FTIMEH

 $EXEDIR/decode_red2full.exe pl.grb_$FTIMEH pl1.grb_$FTIMEH
 #=anex= $EXEDIR/intgl_639.exe pl1.grb_$FTIMEH ICMGG0001+$FTIMEH+$DATE$TIME
 $EXEDIR/pos_intgl_t639.x pl1.grb_$FTIMEH ICMGG0001+$FTIMEH+$DATE$TIME
 echo ICMGG0001+$FTIMEH+$DATE$TIME
 chmod 755 ICMGG0001+$FTIMEH+$DATE$TIME

 #====No.4===rh2m============#
 $EXEDIR/wgrib -s $MODDAT/ICMGG0001+$FTIME+$DATE$TIME | grep ':2T:' > list3_$FTIMEH
 $EXEDIR/wgrib -s $MODDAT/ICMGG0001+$FTIME+$DATE$TIME | grep ':2D:' >> list3_$FTIMEH
 $EXEDIR/wgrib -i -grib -o prh.grb_$FTIMEH $MODDAT/ICMGG0001+$FTIME+$DATE$TIME <list3_$FTIMEH
 
 $EXEDIR/decode_red2full.exe prh.grb_$FTIMEH rhgg.dat_$FTIMEH

 $EXEDIR/pos_rh2m.x rhgg.dat_$FTIMEH ICMPL0001+$FTIMEH+$DATE$TIME rh2mg.dat_$FTIMEH
 #=anex= $EXEDIR/intgl_639.exe rh2mg.dat_$FTIMEH rh2m+$FTIMEH+$DATE$TIME
 $EXEDIR/pos_intgl_t639.x rh2mg.dat_$FTIMEH rh2m+$FTIMEH+$DATE$TIME

 chmod 755 rh2m+$FTIMEH+$DATE$TIME

 #=========== to gen files as follows: ===================
 echo ICMPL0001+$FTIMEH+$DATE$TIME
 echo mslq+$FTIMEH+$DATE$TIME
 # echo diag+$FTIMEH+$DATE$TIME
 echo ICMGG0001+$FTIMEH+$DATE$TIME
 echo rh2m+$FTIMEH+$DATE$TIME
 #========================================================


 #anex echo $DATE$TIME$FTIMEH | $EXEDIR/readpost.exe


 rm $POSTDAT/*_$FTIMEH



#================================================================
#========END LOOP FOR FCST POST TIMES ------------
done
#================================================================

#===================================================================#
# ==== submit next step job card =========
  llsubmit $SCRIPT/vortex_post_relocat_639.ksh
#===================================================================#
  sleep 40
  llsubmit $SCRIPT/toanl_639.ksh
#===================================================================#

#===================================================================#
#===================================================================#
#===================================================================#
  exit 0

