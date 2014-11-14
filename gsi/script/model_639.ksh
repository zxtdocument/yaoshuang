## This is a head file for loadleveler job#
##   This is a job command file of model.
#!/bin/ksh
# @ comment = T639
# @ job_name = model
# @ job_type = parallel
# @ initialdir =/cmd/u/yaosh/T639L60_GSI3.3/logdir
# @ input = /dev/null
# @ output = $(initialdir)/$(job_name).out
# @ error  = $(initialdir)/$(job_name).err
#
# @ notification = error
# @ checkpoint = no
# @ restart = yes
# @ node = 10
# @ tasks_per_node = 32
# @ node_usage = not_shared
# @ network.MPI = sn_single,not_shared,US
# @ wall_clock_limit = 00:25:00, 00:25:00
# @ class = normal
# @ queue

#===================================================================#
  set -x
  set -a
#===================================================================#
# Set up running variables, such as path and directories

  export WORKDIR=/cmd/u/yaosh/T639L60_GSI3.3
       . $WORKDIR/script/envars.ksh

#=====set env for running===========#
#==== Parallel enviroment Configuration #
MBX_SIZE=160000000;export MBX_SIZE
export MP_RESD=yes
export MP_EAGER_LIMIT=65536
export MP_BUFFER_MEM=32M
export MP_CSS_INTERRUPT=yes
export MP_INFOLEVEL=2
export AIX_THREAD_MNRATIO=1:1
export SPILLOOPTIME=500
export YIELDLOOPTIME=500
export OMP_DYNAMIC=FALSE,AIX_THREAD_SCOPE=S,MALLOCMULTIHEAP=TRUE
#export XLSMPOPTS="parthds=1:stack=50000000:schedule=affinity"
export XLSMPOPTS="parthds=1:stack=100000000:schedule=affinity"

#export MP_LABELIO=yes
#export MP_RMPOOL=0
#export MP_HOSTFILE=host.list
#export MP_SHARED_MEMORY=yes

export MP_MSG_API=mpi
export MP_EUIDEVELOP=min
export MP_WAIT_MODE=poll
export MP_REXMIT_BUF_SIZE=66000
export MP_USE_ISFIFO=no


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

  test -d $LOGDIR ||  { echo $LOGDIR not a directory, NO DATE/TIME ; exit 1; }
  test -f $LOGDIR/DATE ||  { echo file DATE not exist ; \
                        exit 1; }
  test -f $LOGDIR/TIME ||  { echo file TIME not exist ; \
                        exit 1; }

  test -d $EXEDIR ||  { echo $EXEDIR not a directory ; exit 1; }

  echo 'IFS Model start date: ' $(date)
#==================================================================#
#==================================================================#
  DATE=`cat $LOGDIR/DATE`
  TIME=`cat $LOGDIR/TIME`
  DATE1=`${EXEDIR}/smsdate $DATE$TIME +06 | cut -c1-8`
  TIME1=`${EXEDIR}/smsdate $DATE$TIME +06 | cut -c9-10`
  echo $DATE $TIME $DATE1 $TIME1


#==============running model==============
  cd $RUNDIR
  rm -rf $RUNDIR/*
  echo $LOADL_PROCESSOR_LIST > tmpfile
  echo $LOADL_PROCESSOR_LIST > $LOGDIR/model_runnode.list
  NODE=` wc tmpfile | cut -c10-16 `
  test $NODE = 64 && { NPROCA=8 ; NPROCB=8 ; }
  test $NODE = 80 && { NPROCA=10 ; NPROCB=8 ; }
#anex  NPROCA=20
#anex  NPROCB=16
  NPROCA=20
  NPROCB=16
  echo $NODE $NPROCA $NPROCB

#=========  Time step is 10 mins.  for t639  ===================
#=========  NSTOP = 18 --> 3hours Forecast.============ 
#=========  NSTOP = 36 --> 6hours Forecast.============
#=========  NSTOP = 54 --> 9hours Forecast.============
#=========  NSTOP = 1440 --> 10 days Forecast.============

  NSTOP=54

#===== check input files
  for I in $MODDAT/ICMGG0001INIT+$DATE1$TIME1 $MODDAT/ICMSH0001INIT+$DATE1$TIME1
  do
    test -s $I || { echo no file $I ; exit 1 ; }
  done


#=========== link files ======================================================
  ln -s $MODDAT/ICMGG0001INIT+$DATE1$TIME1  $RUNDIR/ICMGG0001INIT
  ln -s $MODDAT/ICMSH0001INIT+$DATE1$TIME1  $RUNDIR/ICMSH0001INIT

#================================================================================
## generate fort.4 for namelist  ## 
cat > fort.4 << EOF
 &NAMPAR0
  LMESSP=true,
  NPROCA=$NPROCA,
  NPROCB=$NPROCB,
  NOUTPUT=2,
 /   
 &NAMCT0
 LREFOUT=true,
 LCOMTIM=true,
 N3DINI=0,
 NSTOP=$NSTOP,
 NFRHIS=1,
 NFRPOS=1,
 NHISTS=9,0,18,36,54,72,90,108,126,144
 NHISTS=39,0,18,36,54,72,90,108,126,144,162,180,198,216,234,252,270,288,306,324,342,360,378,396,414,432,504,576,648,720,792,864,936,1008,1080,1152,1224,1296,1368,1440
 NHISTS=14,0,18,36,54,144,288,432,576,720,864,1008,1152,1296,1440
 NHISTS=20,0,18,36,54,72,144,216,288,360,432,504,576,648,720,792,864,1008,1152,1296,1440
 NHISTS=34,0,18,36,54,72,90,108,126,144,162,180,198,216,234,252,270,288,306,324,342,360,432,504,576,648,720,792,864,936,1008,1080,1152,1296,1440
 NPOSTS=9,0,18,36,54,72,90,108,126,144
 NPOSTS=39,0,18,36,54,72,90,108,126,144,162,180,198,216,234,252,270,288,306,324,342,360,378,396,414,432,504,576,648,720,792,864,936,1008,1080,1152,1224,1296,1368,1440
 NPOSTS=14,0,18,36,54,144,288,432,576,720,864,1008,1152,1296,1440
 NPOSTS=20,0,18,36,54,72,144,216,288,360,432,504,576,648,720,792,864,1008,1152,1296,1440
 NPOSTS=34,0,18,36,54,72,90,108,126,144,162,180,198,216,234,252,270,288,306,324,342,360,432,504,576,648,720,792,864,936,1008,1080,1152,1296,1440



 NFRSDI=1,
 LSLAG=true,
 LGPOROG=false,
 /    
 &NAMPAR1
  LSPLIT=false,
  NFLDIN=0,
  NFLDOUT=0,
  NSTRIN=1,
  NSTROUT=0,
  NINTYPE=1,
  NOUTTYPE=1,
  LPPTSF=true,
  NPPBUFLEN=600000,
  NCOMBFLEN=7200000,
 /   
 &NAMRIP
  NINDAT=19960215,
  NSSSSS=43200,
 /   
 &NAMDYN
 VMAX1=220.
 VMAX2=280.,
 TSTEP=600.000000,
 /   
 &NAEPHY
 LEPHYS=true,
 /   
 &NAERAD
 LERAD6H=false,
 NRPROMA=50,
 /   
 &NAMGEM
  NHTYP=2,
 /   
 &NEMINI
 /   
 &NAMDPHY
 /   
 &NAMDIM
 NDLON=1280,
 NDGL=640,
 NPROMA=50,
 NFLEVG=60,
 NSMAX=639,
 LGPQIN=false,
 LCLDPIN=false,
 /   
  &NAMNUD
  /   
 &NAMDDH
 /   
 &NAMPPC
 NO3DSP=6,
 NOPLEV=17,
 NO2DGG=9,
 NO2DGG=48,
 NO3DGGM=4,
 NO3DSPM=7,
 NO3DGGP=1,
 NO3DGGEX=0,
LRPLP=true,
M3DSPP=129,130,135,138,155,157,
M3DSPM=130,133,135,138,152,155,157,
MPLEV=100000,92500,85000,70000,60000,50000,40000,30000,25000,20000,15000,10000,7000,5000,3000,2000,1000,
M3DGGP=133,
LRMLP=true,
M3DGGM=133, 
M3DGGM=133, 246, 247, 248,
LRSUP=true,
M2DGGP=129,136,137,139,140,141,142,143,144,145,146,147,151,164,165,166,167,168,170,171,172,173,174,176,177,178,179,180,181,182,183,184,185,186,187,188,195,196,197,198,201,202,205,233,234,235,236,237,243,244,245,
M2DGGP=142,143,144,235,151,165,166,167,168,
M2DGGP=129,136,137,139,140,141,142,143,144,145,146,147,151,164,165,166,167,168,170,171,172,173,174,176,177,178,179,180,181,182,183,184,185,186,187,188,195,196,197,198,201,202,205,233,234,235,236,237,243,244,245,
 /   
 &NAMNMI
 LNMIRQ=true,
 LASSI=false,
 /   
 &NAMPHYDS
 /   
 &NAMMCC
 /   
 &NAMVFP
 /    
 &NAMGRIB
 /   
 &NAMMUL
 /   
 &NEMCHK
 /   
 &NAMSENS
 /   
 &NAMLEG
 /   
 &NAMIOMI
 /   
 &NAMCFU
 /   
 &NAMTOPH
 /   
 &NAMCT1
 /   
 &NAMPHY
 /   
 &NAMPHY0
 /   
 &NAMPHY3
 /   
 &NAMPHY2
 /   
 &NAMPHY1
 /   
 &NAMZDI
 /   
 &NAMVAR
 /   
 &NAMFFT
 /   
 &NAMOPH
 /   
 &NAMANA
 /   
 &NAMJO
 /   
 &NAMOBS
 /   
 &NAMCVA
 /   
 &NAMJG
 /   
 &NAMCOS
 /   
 &NALBAR
 /   
 &NAV1IS
 /   
 &NAMXFU
 /   
 &NAMDIF
 /   
 &NAMGERCO
 /   
 &NAMMTT
 /   
 &NALAN1
 /   
 &NAMLCZ
 /   
 &NAMRINC
 /   
 &NAMKHP
 /   
 &NAPHLC
 /   
 &NAMLCZ
 /   
 &NAMVRTL
 /   
 &NAMAFN
 /   
 &NAMFPC
 /   
 &NAMFPG
 /   
 &NAMFPIOS
 /   
 &NAMFPSC2
 /   
 &NAMFPD
 /   
 &NAMIOS
 /   
 &NAMVWRK
 /   
 &NAMRES
  NFRRES=9999,
 /   
 &NAMRGRI
 /   
  &NAMVV1
  /   
  &NAMNUD
  /   
  &NAM_DISTRIBUTED_VECTORS
  /
  &NAMINI
  NEINI=1,
  /
  &NAMRAD15
  /
  &NAMSIMPHL
  /
  &NAMVDOZ
  /
  &NAMCHK
  /
  &NAMTRAJP
  /
EOF


##============ start model========================= ##
 cp -p ${EXEDIR}/MASTER.orig.settls    $RUNDIR/MASTER

 $RUNDIR/MASTER -v ecmwf -e 0001

 test $? = 0 || { echo ifs-model gf run error ; exit 1 ; }


#===================== Move output =======================#
#== rm -f ICMSH0001+000[1-9]* ICMSH0001+0000[4-9]*
#== rm -f ICMGG0001+000[1-9]* ICMSH0001+0000[4-9]*

  for i in ICMPL*+* ICMGG*+* ICMSH*+*
  do
    mv $i $i+$DATE1$TIME1
  done

  for i in ICM*+* 
  do 
    mv $i $MODDAT/$i
  done

#=========================================================

echo model.run success $DATE1$TIME1

#cp $RUNDIR/ifs.disp $LOGDIR/ifs.disp${DATE1}${TIME1}
#anex cp $RUNDIR/ifs.stat $LOGDIR/ifs.stat${DATE1}${TIME1}
#cp $RUNDIR/tmpfile $LOGDIR/tmpfile${DATE1}${TIME1}
#anex cp $RUNDIR/NODE.001_01 $LOGDIR/NODE.001_01.${DATE1}${TIME1}

 cp $RUNDIR/ifs.stat $LOGDIR/ifs.stat
 cp $RUNDIR/NODE.001_01 $LOGDIR/NODE.001_01

#=========================================================
  echo $DATE1 >$LOGDIR/DATE
  echo $TIME1 >$LOGDIR/TIME

# ==== submit next step job card =========
#anex=============================================================
  llsubmit $SCRIPT/fcstpost_to_vortexrelocat_639.ksh
#===================================================================#
#===================================================================#
  exit 0
