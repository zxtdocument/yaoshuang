#!/bin/ksh
# Loadlevel Job Keywords Configuraton
# @ comment = T639
# @ job_name = post4sfc
# @ job_type = serial
# @ initialdir =/cmd/u/yaosh/T639L60_GSI3.3/logdir
# @ output = $(initialdir)/$(job_name).out
# @ error  = $(initialdir)/$(job_name).err
#
# @ notification = error
# @ checkpoint = no
# @ restart = yes
# @ node_usage = shared
# @ wall_clock_limit = 00:10:00
# @ class = serial
# @ queue

  set -x
#===================================================================#
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

  if [ ! -d $SFCDAT ] ; then
       mkdir -p $SFCDAT
  else
      rm -rf $SFCDAT/*
  fi

  if [ ! -d $BAKDAT ] ; then
       mkdir -p $BAKDAT
  fi
  if [ ! -d $BAKLOG ] ; then
       mkdir -p $BAKLOG
  fi

#==============================================#
  test -f $LOGDIR/DATE ||  { echo file DATE not exist ; exit 1; }
  test -f $LOGDIR/TIME ||  { echo file TIME not exist ; exit 1; }
#==============================================#

  DATE=`cat $LOGDIR/DATE`
  TIME=`cat $LOGDIR/TIME`
  DATE1=`$EXEDIR/smsdate $DATE$TIME +06 | cut -c1-8`
  TIME1=`$EXEDIR/smsdate $DATE$TIME +06 | cut -c9-10`
  echo $DATE $TIME $DATE1 $TIME1

#====================================================================#
# 1. post-processing the 6hrs-forecast surface fields. (200507)
#   (Based on Yao Mingming's job file -- post/SURFACE/sfc_6h.ksh)
  echo  post-processing sfc-fileds 6hrs-forecast from $DATE$TIME
#===================================================================#
  cd $RUNDIR
  rm -rf *

#===================================================================#
  for j in 3 6 9
  do

    i=`expr $j \* 6`   

    FTIME=` $EXEDIR/i6 $i `
    FTIMEH=` $EXEDIR/i6 $j `

    test -s $MODDAT/ICMGG0001+$FTIME+$DATE$TIME || { echo no file $MODDAT/ICMGG0001+$FTIME+$DATE$TIME; exit 1; }

#==== a. gauss grid 4 layers  soil Temp
    echo 'Decode gauss grid 4 layers  soil Temp '

    $EXEDIR/wgrib -s $MODDAT/ICMGG0001+$FTIME+$DATE$TIME | grep ':ST:' > list1_$FTIMEH
#   $EXEDIR/wgrib -s $MODDAT/ICMGG0001+$FTIME+$DATE$TIME | grep ':DST:' >> list1_$FTIMEH
#   $EXEDIR/wgrib -s $MODDAT/ICMGG0001+$FTIME+$DATE$TIME | grep ':CDST:' >> list1_$FTIMEH
#   $EXEDIR/wgrib -s $MODDAT/ICMGG0001+$FTIME+$DATE$TIME | grep ':STL4:' >> list1_$FTIMEH
    $EXEDIR/wgrib -i -grib -o pl.grb_$FTIMEH $MODDAT/ICMGG0001+$FTIME+$DATE$TIME < list1_$FTIMEH
    $EXEDIR/wgrib -s pl.grb_$FTIMEH > list2_$FTIMEH
    $EXEDIR/decode_red2full.exe pl.grb_$FTIMEH $SFCDAT/Tsoil+$FTIMEH+$DATE$TIME 
    test $? = 0 || { echo get soil temp  error ; exit 1; }
    echo Tsoil+$FTIMEH+$DATE$TIME
    
    rm -rf $RUNDIR/list*FTIMEH

#==== b. gauss grid 3 layers  soil water conent (m)
    echo 'Decode gauss grid 3 layers  soil water conent (m)'

    $EXEDIR/wgrib -s $MODDAT/ICMGG0001+$FTIME+$DATE$TIME | grep ':SSW:'  > list3_$FTIMEH
#   $EXEDIR/wgrib -s $MODDAT/ICMGG0001+$FTIME+$DATE$TIME | grep ':DSW:' >> list3_$FTIMEH
#   $EXEDIR/wgrib -s $MODDAT/ICMGG0001+$FTIME+$DATE$TIME | grep ':CDSW:'>> list3_$FTIMEH
    $EXEDIR/wgrib -i -grib -o pl.grb_$FTIMEH $MODDAT/ICMGG0001+$FTIME+$DATE$TIME < list3_$FTIMEH
    $EXEDIR/wgrib -s pl.grb_$FTIMEH > list4_$FTIMEH
    $EXEDIR/decode_red2full.exe pl.grb_$FTIMEH $SFCDAT/Wsoil+$FTIMEH+$DATE$TIME 
    test $? = 0 || { echo get soil water  error ; exit 1; }
    echo Wsoil+$FTIMEH+$DATE$TIME

    rm -rf $RUNDIR/list*FTIMEH

# c. gauss grid 1 layer  snow depth
#    echo 'Decode gauss grid 1 layer  snow depth'
#    $EXEDIR/wgrib -s $MODDAT/ICMGG0001+$FTIME+$DATE$TIME | grep ':SD:' > list5_$FTIMEH
#    $EXEDIR/wgrib -i -grib -o pl.grb_$FTIMEH $MODDAT/ICMGG0001+$FTIME+$DATE$TIME < list5_$FTIMEH
#    $EXEDIR/wgrib -s pl.grb_$FTIMEH > list6_$FTIMEH
#    $EXEDIR/decode_red2full.exe pl.grb_$FTIMEH Dsnow+$FTIMEH+$DATE$TIME
#    echo Dsnow+$FTIMEH+$DATE$TIME
#    rm -rf $RUNDIR/list*FTIMEH

#==== d. gauss grid 1 layer Tskin(K) & 10m UV(m/s)
    echo 'Decode gauss grid 1 layer Tskin(K) & 10m UV(m/s)'
	
   $EXEDIR/wgrib -s $MODDAT/ICMGG0001+$FTIME+$DATE$TIME | grep ':SKT:' > list7_$FTIMEH
   $EXEDIR/wgrib -s $MODDAT/ICMGG0001+$FTIME+$DATE$TIME | grep ':10U:' >> list7_$FTIMEH
   $EXEDIR/wgrib -s $MODDAT/ICMGG0001+$FTIME+$DATE$TIME | grep ':10V:' >> list7_$FTIMEH
   $EXEDIR/wgrib -i -grib -o pl.grb_$FTIMEH $MODDAT/ICMGG0001+$FTIME+$DATE$TIME < list7_$FTIMEH
   $EXEDIR/wgrib -s pl.grb_$FTIMEH > list8_$FTIMEH

    $EXEDIR/decode_red2full.exe pl.grb_$FTIMEH $SFCDAT/SKT+10W+$FTIMEH+$DATE$TIME
    test $? = 0 || { echo get Tskin and UV-wind at 10m  error ; exit 1; }
    echo SKT+10W+$FTIMEH+$DATE$TIME

    rm -rf $RUNDIR/list*FTIMEH

#==== e. calculate model bottom uv   
  $EXEDIR/wgrib -s $MODDAT/ICMSH0001+$FTIME+$DATE$TIME | grep ':VO:hybrid lev 60:' > list9_$FTIMEH
  $EXEDIR/wgrib -s $MODDAT/ICMSH0001+$FTIME+$DATE$TIME | grep ':D:hybrid lev 60:' >> list9_$FTIMEH
  $EXEDIR/wgrib -i -grib -o pl.grb_$FTIMEH $MODDAT/ICMSH0001+$FTIME+$DATE$TIME < list9_$FTIMEH

#====  lonlatuv.exe read pnm in clidat
  ln -sf $ANLFIX/t639_pnm      $RUNDIR/pnm.gauss

  ln -s $SFCDAT/mod_uv_bottom${FTIMEH}.t${DATE}${TIME}z.gg1280*640  $RUNDIR/fort.${FTIMEH}
  $EXEDIR/gaussuv_t639.exe pl.grb_$FTIMEH $RUNDIR/fort.${FTIMEH} #$SFCDAT/mod_uv_bottom${FTIMEH}.t${DATE}${TIME}z.gg1280*640 
  echo $SFCDAT/mod_uv_bottom${FTIMEH}.t${DATE}${TIME}z.gg1280*640 
  test $? = 0 || { echo calculate model bottom uv error ; exit 1; }

  rm -rf $RUNDIR/list*FTIMEH
#====================================================================#

  test -s $SFCDAT/Tsoil+${FTIMEH}+${DATE}${TIME}   || { echo Tsoil not exit ; exit 2; }
  test -s $SFCDAT/Wsoil+${FTIMEH}+${DATE}${TIME}   || { echo Wsoil not exit ; exit 2; }
  test -s $SFCDAT/SKT+10W+${FTIMEH}+${DATE}${TIME} || { echo SKT+T10W not exit ; exit 2; }
  test -s $SFCDAT/mod_uv_bottom${FTIMEH}.t${DATE}${TIME}z.gg1280*640 || { echo mod_uv_bottom${FTIMEH}.t${DATE}${TIME}z.gg1280*640 not exit ; exit 2; }

  echo ' post4sfc success for $DATE1$TIME1 (${FTIMEH}hrs-forecast from $DATE$TIME) '

  done

#===============================================================================
#==== Preparation of tracers for GSI First-Guess fields.(Such as Ozone) ==========
     llsubmit $SCRIPT/sfc_tran_639.ksh

#===============================================================================
#  cp -p  $LOGDIR/post4sfc.out    $BAKLOG/post4sfc.out_$DATE$TIME 
#  cp -p  $LOGDIR/post4sfc.err    $BAKLOG/post4sfc.err_$DATE$TIME


#====================================================================#
  exit 0
