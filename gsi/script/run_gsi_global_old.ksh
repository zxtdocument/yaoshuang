#!/bin/ksh
##   This is a job command file of ssi.
## Loadlevel Job Keywords Configuraton
# @ comment =  T639
# @ job_name = gsi 
# @ job_type = parallel
# @ input = /dev/null
# @ initialdir = /cmd/u/yaosh/T639L60_GSI3.3/logdir
# @ output = $(initialdir)/$(job_name).out
# @ error  = $(initialdir)/$(job_name).err
## @ notify_user = zhangtao@cmd01n02 
# @ notification = error
# @ checkpoint = no
# @ restart = yes
# @ node = 10
# @ tasks_per_node = 32
# @ node_usage = not_shared
# @ network.MPI = sn_single,not_shared,US
# @ wall_clock_limit = 00:50:00, 00:50:00
# @ class =  normal
## @ class =  largemem
# @ queue

#===================================================================#
  set -x
  set -e 
  set -u
#===================================================================#
 ulimit -d unlimited
 ulimit -m unlimited
 ulimit -s unlimited

#=====set env for running===========#
MBX_SIZE=64000000;export MBX_SIZE
export MP_RESD=yes
export MP_EAGER_LIMIT=65536
#export MP_BUFFER_MEM=32M
export MP_CSS_INTERRUPT=yes
export MP_INFOLEVEL=2
export AIX_THREAD_MNRATIO=1:1
export SPILLOOPTIME=500
export YIELDLOOPTIME=500
export OMP_DYNAMIC=FALSE,AIX_THREAD_SCOPE=S,MALLOCMULTIHEAP=TRUE
#export XLSMPOPTS="parthds=1:stack=50000000:schedule=affinity"
export XLSMPOPTS="parthds=1:stack=1000000000:schedule=affinity"
#
#export MP_LABELIO=yes
#export MP_RMPOOL=0
#export MP_HOSTFILE=host.list
#export MP_SHARED_MEMORY=yes
#
export MP_MSG_API=mpi
export MP_EUIDEVELOP=min
export MP_WAIT_MODE=poll
export MP_REXMIT_BUF_SIZE=66000
export MP_USE_ISFIFO=no
#
#===================================================================#
#== Set up running variables, such as path and directories
  export WORKDIR=/cmd/u/yaosh/T639L60_GSI3.3
  . $WORKDIR/script/envars.ksh
  DATE=`cat $LOGDIR/DATE`
  TIME=`cat $LOGDIR/TIME`
  DATE1=`zt_date +%Y%m%d -d "$DATE $TIME 6 hour"` 
  TIME1=`zt_date +%H -d "$DATE $TIME 6 hour"` 


#
#####################################################
# case set up (users should change this part)
#####################################################
#
# ANAL_TIME= analysis time  (YYYYMMDDHH)
# WORK_ROOT= working directory, where GSI runs
# PREPBURF = path of PreBUFR conventional obs
# BK_ROOT  = path of background files
# OBS_ROOT = path of observations files
# FIX_ROOT = path of fix files
# GSI_EXE  = path and name of the gsi executable 

  RUN_ROOT=${WORKDIR}/run/${DATE1}${TIME1}_T639
  BK_ROOT=${WORKDIR}/moddat
  OBS_ROOT=/cmd/g1/jianglp/DATA/GDAS/ncep/gdas.${DATE1}
  PREPBUFR=${OBS_ROOT}/gdas1.t${TIME1}z.prepbufr.nr
  FIX_ROOT=${WORKDIR}/fix
  CRTM_ROOT=${WORKDIR}/crtm_coeffs_2_1_3_Big_Endian

#  GSI_EXE=${RUN_ROOT}/release_V3.3_pgi13.10/run/gsi.exe
#  GSI_EXE=${RUN_ROOT}/release_V3.3_intel_12-12.0/run/gsi.exe
  GSI_EXE=${EXEDIR}/lin_gsi.exe

#------------------------------------------------
# if_clean = clean  : delete temperal files in working directory (default)
#            no     : leave running directory as is (this is for debug only)
  if_clean=clean

# Set the JCAP resolution which you want.
# All resolutions use LEVS=64
  JCAP=639
  JCAP_B=639
  LATA=640
  NLON=1280
  nsig=60
  DELTIM=116
export NLAT=$((${LATA}+2))
#export DELTIM=${DELTIM:-$((3600/($JCAP/20)))}
#
#
  mkdir -p $RUN_ROOT
  rm -rf $RUN_ROOT/*
 cd $RUN_ROOT



# Build the GSI namelist on-the-fly
cat << EOF > gsiparm.anl
&SETUP
   miter=2,niter(1)=50,niter(2)=50,
   niter_no_qc(1)=1,niter_no_qc(2)=0,
   write_diag(1)=.true.,write_diag(2)=.false.,write_diag(3)=.true.,
   gencode=82,qoption=2,
   factqmin=0.1,factqmax=0.1,deltim=$DELTIM,
   ndat=75,iguess=-1,
   oneobtest=.false.,retrieval=.false.,l_foto=.false.,
   use_pbl=.false.,use_compress=.true.,nsig_ext=13,gpstop=50.,
   use_gfs_nemsio=.false.,lrun_subdirs=.true.,
   crtm_coeffs_path='/cmd/u/linhj/data/crtm_coeffs_2_1_3_Big_Endian/',
 /
 &GRIDOPTS
   JCAP=$JCAP,JCAP_B=$JCAP_B,NLAT=$NLAT,NLON=$NLON,nsig=$nsig,
   regional=.false.,nlayers(59)=3,nlayers(60)=6,
   CMA_global = .true.
 /
 &BKGERR
   vs=0.7,
   hzscl=1.7,0.8,0.5,
   hswgt=0.45,0.3,0.25,
   bw=0.0,norsp=4,
   bkgv_flowdep=.true.,bkgv_rewgtfct=1.5,
 /
 &ANBKGERR
   anisotropic=.false.,
 /
 &JCOPTS
   ljcdfi=.false.,alphajc=0.0,ljcpdry=.true.,bamp_jcpdry=5.0e7,
 /
 &STRONGOPTS
   tlnmc_option=0,nstrong=1,nvmodes_keep=8,period_max=6.,period_width=1.5,
   baldiag_full=.true.,baldiag_inc=.true.,
 /
 &OBSQC
   dfact=0.75,dfact1=3.0,noiqc=.true.,oberrflg=.false.,c_varqc=0.02,
   use_poq7=.true.,
 /
 &OBS_INPUT
   dmesh(1)=180.0,dmesh(2)=145.0,dmesh(3)=240.0,dmesh(4)=160.0,time_window_max=3.0,
   dfile(01)='prepbufr',  dtype(01)='ps',        dplat(01)=' ',       dsis(01)='ps',              dval(01)=0.0,  dthin(01)=0,  dsfcalc(01)=0,
   dfile(02)='prepbufr'   dtype(02)='t',         dplat(02)=' ',       dsis(02)='t',               dval(02)=0.0,  dthin(02)=0,  dsfcalc(02)=0,
   dfile(03)='prepbufr',  dtype(03)='q',         dplat(03)=' ',       dsis(03)='q',               dval(03)=0.0,  dthin(03)=0,  dsfcalc(03)=0,
   dfile(04)='prepbufr',  dtype(04)='pw',        dplat(04)=' ',       dsis(04)='pw',              dval(04)=0.0,  dthin(04)=0,  dsfcalc(04)=0,
   dfile(05)='prepbufr',  dtype(05)='uv',        dplat(05)=' ',       dsis(05)='uv',              dval(05)=0.0,  dthin(05)=0,  dsfcalc(05)=0,
   dfile(06)='satwndbufr',dtype(06)='uv',        dplat(06)=' ',       dsis(06)='uv',              dval(06)=0.0,  dthin(06)=0,  dsfcalc(06)=0,
   dfile(07)='prepbufr',  dtype(07)='spd',       dplat(07)=' ',       dsis(07)='spd',             dval(07)=0.0,  dthin(07)=0,  dsfcalc(07)=0,
   dfile(08)='prepbufr',  dtype(08)='dw',        dplat(08)=' ',       dsis(08)='dw',              dval(08)=0.0,  dthin(08)=0,  dsfcalc(08)=0,
   dfile(09)='radarbufr', dtype(09)='rw',        dplat(09)=' ',       dsis(09)='rw',              dval(09)=0.0,  dthin(09)=0,  dsfcalc(09)=0,
   dfile(10)='prepbufr',  dtype(10)='sst',       dplat(10)=' ',       dsis(10)='sst',             dval(10)=0.0,  dthin(10)=0,  dsfcalc(10)=0,
   dfile(11)='gpsrobufr', dtype(11)='gps_bnd',   dplat(11)=' ',       dsis(11)='gps',             dval(11)=0.0,  dthin(11)=0,  dsfcalc(11)=0,
   dfile(12)='ssmirrbufr',dtype(12)='pcp_ssmi',  dplat(12)='dmsp',    dsis(12)='pcp_ssmi',        dval(12)=0.0,  dthin(12)=-1, dsfcalc(12)=0,
   dfile(13)='tmirrbufr', dtype(13)='pcp_tmi',   dplat(13)='trmm',    dsis(13)='pcp_tmi',         dval(13)=0.0,  dthin(13)=-1, dsfcalc(13)=0,
   dfile(14)='sbuvbufr',  dtype(14)='sbuv2',     dplat(14)='n16',     dsis(14)='sbuv8_n16',       dval(14)=0.0,  dthin(14)=0,  dsfcalc(14)=0,
   dfile(15)='sbuvbufr',  dtype(15)='sbuv2',     dplat(15)='n17',     dsis(15)='sbuv8_n17',       dval(15)=0.0,  dthin(15)=0,  dsfcalc(15)=0,
   dfile(16)='sbuvbufr',  dtype(16)='sbuv2',     dplat(16)='n18',     dsis(16)='sbuv8_n18',       dval(16)=0.0,  dthin(16)=0,  dsfcalc(16)=0,
   dfile(17)='hirs3bufr', dtype(17)='hirs3',     dplat(17)='n17',     dsis(17)='hirs3_n17',       dval(17)=0.0,  dthin(17)=1,  dsfcalc(17)=0,
   dfile(18)='hirs4bufr', dtype(18)='hirs4',     dplat(18)='metop-a', dsis(18)='hirs4_metop-a',   dval(18)=0.0,  dthin(18)=1,  dsfcalc(18)=0,
   dfile(19)='gimgrbufr', dtype(19)='goes_img',  dplat(19)='g11',     dsis(19)='imgr_g11',        dval(19)=0.0,  dthin(19)=1,  dsfcalc(19)=0,
   dfile(20)='gimgrbufr', dtype(20)='goes_img',  dplat(20)='g12',     dsis(20)='imgr_g12',        dval(20)=0.0,  dthin(20)=1,  dsfcalc(20)=0,
   dfile(21)='airsbufr',  dtype(21)='airs',      dplat(21)='aqua',    dsis(21)='airs281SUBSET_aqua',dval(21)=0.0,dthin(21)=1, dsfcalc(21)=0,
   dfile(22)='amsuabufr', dtype(22)='amsua',     dplat(22)='n15',     dsis(22)='amsua_n15',       dval(22)=0.0,  dthin(22)=1,  dsfcalc(22)=0,
   dfile(23)='amsuabufr', dtype(23)='amsua',     dplat(23)='n18',     dsis(23)='amsua_n18',       dval(23)=0.0,  dthin(23)=1,  dsfcalc(23)=0,
   dfile(24)='amsuabufr', dtype(24)='amsua',     dplat(24)='metop-a', dsis(24)='amsua_metop-a',   dval(24)=0.0,  dthin(24)=1,  dsfcalc(24)=0,
   dfile(25)='airsbufr',  dtype(25)='amsua',     dplat(25)='aqua',    dsis(25)='amsua_aqua',      dval(25)=0.0,  dthin(25)=1,  dsfcalc(25)=0,
   dfile(26)='amsubbufr', dtype(26)='amsub',     dplat(26)='n17',     dsis(26)='amsub_n17',       dval(26)=0.0,  dthin(26)=1,  dsfcalc(26)=0,
   dfile(27)='mhsbufr',   dtype(27)='mhs',       dplat(27)='n18',     dsis(27)='mhs_n18',         dval(27)=0.0,  dthin(27)=1,  dsfcalc(27)=0,
   dfile(28)='mhsbufr',   dtype(28)='mhs',       dplat(28)='metop-a', dsis(28)='mhs_metop-a',     dval(28)=0.0,  dthin(28)=1,  dsfcalc(28)=0,
   dfile(29)='ssmitbufr', dtype(29)='ssmi',      dplat(29)='f14',     dsis(29)='ssmi_f14',        dval(29)=0.0,  dthin(29)=1,  dsfcalc(29)=0,
   dfile(30)='ssmitbufr', dtype(30)='ssmi',      dplat(30)='f15',     dsis(30)='ssmi_f15',        dval(30)=0.0,  dthin(30)=1,  dsfcalc(30)=0,
   dfile(31)='amsrebufr', dtype(31)='amsre_low', dplat(31)='aqua',    dsis(31)='amsre_aqua',      dval(31)=0.0,  dthin(31)=1,  dsfcalc(31)=0,
   dfile(32)='amsrebufr', dtype(32)='amsre_mid', dplat(32)='aqua',    dsis(32)='amsre_aqua',      dval(32)=0.0,  dthin(32)=1,  dsfcalc(32)=0,
   dfile(33)='amsrebufr', dtype(33)='amsre_hig', dplat(33)='aqua',    dsis(33)='amsre_aqua',      dval(33)=0.0,  dthin(33)=1,  dsfcalc(33)=0,
   dfile(34)='ssmisbufr', dtype(34)='ssmis_las', dplat(34)='f16',     dsis(34)='ssmis_f16',       dval(34)=0.0,  dthin(34)=1,  dsfcalc(34)=0,
   dfile(35)='ssmisbufr', dtype(35)='ssmis_uas', dplat(35)='f16',     dsis(35)='ssmis_f16',       dval(35)=0.0,  dthin(35)=1,  dsfcalc(35)=0,
   dfile(36)='ssmisbufr', dtype(36)='ssmis_img', dplat(36)='f16',     dsis(36)='ssmis_f16',       dval(36)=0.0,  dthin(36)=1,  dsfcalc(36)=0,
   dfile(37)='ssmisbufr', dtype(37)='ssmis_env', dplat(37)='f16',     dsis(37)='ssmis_f16',       dval(37)=0.0,  dthin(37)=1,  dsfcalc(37)=0,
   dfile(38)='gsnd1bufr', dtype(38)='sndrd1',    dplat(38)='g12',     dsis(38)='sndrD1_g12',      dval(38)=0.0,  dthin(38)=1,  dsfcalc(38)=0,
   dfile(39)='gsnd1bufr', dtype(39)='sndrd2',    dplat(39)='g12',     dsis(39)='sndrD2_g12',      dval(39)=0.0,  dthin(39)=1,  dsfcalc(39)=0,
   dfile(40)='gsnd1bufr', dtype(40)='sndrd3',    dplat(40)='g12',     dsis(40)='sndrD3_g12',      dval(40)=0.0,  dthin(40)=1,  dsfcalc(40)=0,
   dfile(41)='gsnd1bufr', dtype(41)='sndrd4',    dplat(41)='g12',     dsis(41)='sndrD4_g12',      dval(41)=0.0,  dthin(41)=1,  dsfcalc(41)=0,
   dfile(42)='gsnd1bufr', dtype(42)='sndrd1',    dplat(42)='g11',     dsis(42)='sndrD1_g11',      dval(42)=0.0,  dthin(42)=1,  dsfcalc(42)=0,
   dfile(43)='gsnd1bufr', dtype(43)='sndrd2',    dplat(43)='g11',     dsis(43)='sndrD2_g11',      dval(43)=0.0,  dthin(43)=1,  dsfcalc(43)=0,
   dfile(44)='gsnd1bufr', dtype(44)='sndrd3',    dplat(44)='g11',     dsis(44)='sndrD3_g11',      dval(44)=0.0,  dthin(44)=1,  dsfcalc(44)=0,
   dfile(45)='gsnd1bufr', dtype(45)='sndrd4',    dplat(45)='g11',     dsis(45)='sndrD4_g11',      dval(45)=0.0,  dthin(45)=1,  dsfcalc(45)=0,
   dfile(46)='gsnd1bufr', dtype(46)='sndrd1',    dplat(46)='g13',     dsis(46)='sndrD1_g13',      dval(46)=0.0,  dthin(46)=1,  dsfcalc(46)=0,
   dfile(47)='gsnd1bufr', dtype(47)='sndrd2',    dplat(47)='g13',     dsis(47)='sndrD2_g13',      dval(47)=0.0,  dthin(47)=1,  dsfcalc(47)=0,
   dfile(48)='gsnd1bufr', dtype(48)='sndrd3',    dplat(48)='g13',     dsis(48)='sndrD3_g13',      dval(48)=0.0,  dthin(48)=1,  dsfcalc(48)=0,
   dfile(49)='gsnd1bufr', dtype(49)='sndrd4',    dplat(49)='g13',     dsis(49)='sndrD4_g13',      dval(49)=0.0,  dthin(49)=1,  dsfcalc(49)=0,
   dfile(50)='iasibufr',  dtype(50)='iasi',      dplat(50)='metop-a', dsis(50)='iasi616_metop-a', dval(50)=0.0,  dthin(50)=1,  dsfcalc(50)=0,
   dfile(51)='gomebufr',  dtype(51)='gome',      dplat(51)='metop-a', dsis(51)='gome_metop-a',    dval(51)=0.0,  dthin(51)=2,  dsfcalc(51)=0,
   dfile(52)='omibufr',   dtype(52)='omi',       dplat(52)='aura',    dsis(52)='omi_aura',        dval(52)=0.0,  dthin(52)=2,  dsfcalc(52)=0,
   dfile(53)='sbuvbufr',  dtype(53)='sbuv2',     dplat(53)='n19',     dsis(53)='sbuv8_n19',       dval(53)=0.0,  dthin(53)=0,  dsfcalc(53)=0,
   dfile(54)='hirs4bufr', dtype(54)='hirs4',     dplat(54)='n19',     dsis(54)='hirs4_n19',       dval(54)=0.0,  dthin(54)=1,  dsfcalc(54)=0,
   dfile(55)='amsuabufr', dtype(55)='amsua',     dplat(55)='n19',     dsis(55)='amsua_n19',       dval(55)=0.0,  dthin(55)=1,  dsfcalc(55)=0,
   dfile(56)='mhsbufr',   dtype(56)='mhs',       dplat(56)='n19',     dsis(56)='mhs_n19',         dval(56)=0.0,  dthin(56)=1,  dsfcalc(56)=0,
   dfile(57)='tcvitl'     dtype(57)='tcp',       dplat(57)=' ',       dsis(57)='tcp',             dval(57)=0.0,  dthin(57)=0,  dsfcalc(57)=0,
   dfile(58)='seviribufr',dtype(58)='seviri',    dplat(58)='m08',     dsis(58)='seviri_m08',      dval(58)=0.0,  dthin(58)=1,  dsfcalc(58)=0,
   dfile(59)='seviribufr',dtype(59)='seviri',    dplat(59)='m09',     dsis(59)='seviri_m09',      dval(59)=0.0,  dthin(59)=1,  dsfcalc(59)=0,
   dfile(60)='seviribufr',dtype(60)='seviri',    dplat(60)='m10',     dsis(60)='seviri_m10',      dval(60)=0.0,  dthin(60)=1,  dsfcalc(60)=0,
   dfile(61)='hirs4bufr', dtype(61)='hirs4',     dplat(61)='metop-b', dsis(61)='hirs4_metop-b',   dval(61)=0.0,  dthin(61)=1,  dsfcalc(61)=0,
   dfile(62)='amsuabufr', dtype(62)='amsua',     dplat(62)='metop-b', dsis(62)='amsua_metop-b',   dval(62)=0.0,  dthin(62)=1,  dsfcalc(62)=0,
   dfile(63)='mhsbufr',   dtype(63)='mhs',       dplat(63)='metop-b', dsis(63)='mhs_metop-b',     dval(63)=0.0,  dthin(63)=1,  dsfcalc(63)=0,
   dfile(64)='iasibufr',  dtype(64)='iasi',      dplat(64)='metop-b', dsis(64)='iasi616_metop-b', dval(64)=0.0,  dthin(64)=1,  dsfcalc(64)=0,
   dfile(65)='gomebufr',  dtype(65)='gome',      dplat(65)='metop-b', dsis(65)='gome_metop-b',    dval(65)=0.0,  dthin(65)=2,  dsfcalc(65)=0,
   dfile(66)='atmsbufr',  dtype(66)='atms',      dplat(66)='npp',     dsis(66)='atms_npp',        dval(66)=0.0,  dthin(66)=1,  dsfcalc(66)=0,
   dfile(67)='crisbufr',  dtype(67)='cris',      dplat(67)='npp',     dsis(67)='cris_npp',        dval(67)=0.0,  dthin(67)=1,  dsfcalc(67)=0,
   dfile(68)='gsnd1bufr', dtype(68)='sndrd1',    dplat(68)='g14',     dsis(68)='sndrD1_g14',      dval(68)=0.0,  dthin(68)=1,  dsfcalc(68)=0,
   dfile(69)='gsnd1bufr', dtype(69)='sndrd2',    dplat(69)='g14',     dsis(69)='sndrD2_g14',      dval(69)=0.0,  dthin(69)=1,  dsfcalc(69)=0,
   dfile(70)='gsnd1bufr', dtype(70)='sndrd3',    dplat(70)='g14',     dsis(70)='sndrD3_g14',      dval(70)=0.0,  dthin(70)=1,  dsfcalc(70)=0,
   dfile(71)='gsnd1bufr', dtype(71)='sndrd4',    dplat(71)='g14',     dsis(71)='sndrD4_g14',      dval(71)=0.0,  dthin(71)=1,  dsfcalc(71)=0,
   dfile(72)='gsnd1bufr', dtype(72)='sndrd1',    dplat(72)='g15',     dsis(72)='sndrD1_g15',      dval(72)=0.0,  dthin(72)=1,  dsfcalc(72)=0,
   dfile(73)='gsnd1bufr', dtype(73)='sndrd2',    dplat(73)='g15',     dsis(73)='sndrD2_g15',      dval(73)=0.0,  dthin(73)=1,  dsfcalc(73)=0,
   dfile(74)='gsnd1bufr', dtype(74)='sndrd3',    dplat(74)='g15',     dsis(74)='sndrD3_g15',      dval(74)=0.0,  dthin(74)=1,  dsfcalc(74)=0,
   dfile(75)='gsnd1bufr', dtype(75)='sndrd4',    dplat(75)='g15',     dsis(75)='sndrD4_g15',      dval(75)=0.0,  dthin(75)=1,  dsfcalc(75)=0,
 /
  &SUPEROB_RADAR
 /
 &LAG_DATA
 /
 &HYBRID_ENSEMBLE
   l_hyb_ens=.false.,
 /
 &RAPIDREFRESH_CLDSURF
   dfi_radar_latent_heat_time_period=30.0,
 /
 &CHEM
 /
 &SINGLEOB_TEST
   maginnov=0.1,magoberr=0.1,oneob_type='t',
   oblat=45.,oblon=180.,obpres=1000.,obdattim=${DATE1}${TIME1},
   obhourset=0.,
 /

EOF

##################################################################################

echo " Copy GSI executable, background file, and link observation bufr to working directory"

# Save a copy of the GSI executable in the RUN_ROOT
ln -sf ${GSI_EXE} gsi.exe

# Bring over background field (it's modified by GSI so we can't link to it)
# Copy bias correction, atmospheric and surface files

#ln -sf $OBS_ROOT/gdas1.t${TIME}z.abias                   ./satbias_in
#cp $OBS_ROOT/gdas1.t${TIME}z.satang                  ./satbias_angle

#cp $BK_ROOT/gdas${resol}.t${TIME}z.bf03                    ./sfcf03
#cp $BK_ROOT/gdas${resol}.t${TIME}z.bf06                    ./sfcf06
#cp $BK_ROOT/gdas${resol}.t${TIME}z.bf09                    ./sfcf09
#
#cp $BK_ROOT/gdas${resol}.t${TIME1}z.sgm3prep                ./sigf03
#cp $BK_ROOT/gdas${resol}.t${TIME1}z.sgesprep                ./sigf06
#cp $BK_ROOT/gdas${resol}.t${TIME1}z.sgp3prep                ./sigf09

ln -sf $GSIFIX/sfcf03_639            ./sfcf03
ln -sf $GSIFIX/sfcf06_639            ./sfcf06
ln -sf $GSIFIX/sfcf09_639            ./sfcf09

ln -sf $GSISFC/sfcanl.${NLON}x${LATA}.t${DATE}${TIME}z_03    ./sfcfnmc03
ln -sf $GSISFC/sfcanl.${NLON}x${LATA}.t${DATE}${TIME}z_06    ./sfcfnmc06
ln -sf $GSISFC/sfcanl.${NLON}x${LATA}.t${DATE}${TIME}z_09    ./sfcfnmc09

ln -sf $ANLDAT/xsp03.dat$DATE$TIME        ./sigf03
ln -sf $ANLDAT/xsp06.dat$DATE$TIME        ./sigf06
ln -sf $ANLDAT/xsp09.dat$DATE$TIME        ./sigf09
# Link to the prepbufr data
ln -sf ${PREPBUFR} ./prepbufr

# Link to the radiance data

ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.satwnd.tm00.bufr_d        ./satwnd
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.gpsro.tm00.bufr_d         ./gpsrobufr
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.spssmi.tm00.bufr_d        ./ssmirrbufr
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.sptrmm.tm00.bufr_d        ./tmirrbufr
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.osbuv8.tm00.bufr_d        ./sbuvbufr
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.goesfv.tm00.bufr_d        ./gsnd1bufr
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.1bamua.tm00.bufr_d        ./amsuabufr
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.1bamub.tm00.bufr_d        ./amsubbufr
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.1bhrs2.tm00.bufr_d        ./hirs2bufr
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.1bhrs3.tm00.bufr_d        ./hirs3bufr
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.1bhrs4.tm00.bufr_d        ./hirs4bufr
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.1bmhs.tm00.bufr_d         ./mhsbufr
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.1bmsu.tm00.bufr_d         ./msubufr
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.airsev.tm00.bufr_d        ./airsbufr
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.sevcsr.tm00.bufr_d        ./seviribufr
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.mtiasi.tm00.bufr_d        ./iasibufr
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.ssmit.tm00.bufr_d         ./ssmitbufr
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.amsre.tm00.bufr_d         ./amsrebufr
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.ssmis.tm00.bufr_d         ./ssmisbufr
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.gome.tm00.bufr_d          ./gomebufr
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.omi.tm00.bufr_d           ./omibufr
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.mlsbufr.tm00.bufr_d       ./mlsbufr
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.eshrs3.tm00.bufr_d        ./hirs3bufrears
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.esamua.tm00.bufr_d        ./amsuabufrears
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.esamub.tm00.bufr_d        ./amsubbufrears
ln -sf ${OBS_ROOT}/gdas1.t${TIME1}z.syndata.tcvitals.tm00     ./tcvitl


#
##################################################################################

echo " Copy fixed files and link CRTM coefficient files to working directory"

# Set fixed files
#   berror   = forecast model background error statistics
#   specoef  = CRTM spectral coefficients
#   trncoef  = CRTM transmittance coefficients
#   emiscoef = CRTM coefficients for IR sea surface emissivity model
#   aerocoef = CRTM coefficients for aerosol effects
#   cldcoef  = CRTM coefficients for cloud effects
#   satinfo  = text file with information about assimilation of brightness temperatures
#   satangl  = angle dependent bias correction file (fixed in time)
#   pcpinfo  = text file with information about assimilation of prepcipitation rates
#   ozinfo   = text file with information about assimilation of ozone data
#   errtable = text file with obs error for conventional data (regional only)
#   convinfo = text file with information about assimilation of conventional data
#   bufrtable= text file ONLY needed for single obs test (oneobstest=.true.)
#   bftab_sst= bufr table for sst ONLY needed for sst retrieval (retrieval=.true.)

ANAVINFO=${FIX_ROOT}/global_anavinfo.l64.txt
BERROR=${FIX_ROOT}/CMA_l60y642_berror_stats_gcv
SATINFO=${FIX_ROOT}/global_satinfo.txt
scaninfo=${FIX_ROOT}/global_scaninfo.txt
SATANGL=${FIX_ROOT}/global_satangbias.txt #satellite radiance angle bias correction coefficient
atmsbeamdat=${FIX_ROOT}/atms_beamwidth.txt
CONVINFO=${FIX_ROOT}/global_convinfo.txt
OZINFO=${FIX_ROOT}/global_ozinfo.txt
PCPINFO=${FIX_ROOT}/global_pcpinfo.txt
OBERROR=${FIX_ROOT}/prepobs_errtable.global


# Only need this file for single obs test
bufrtable=${FIX_ROOT}/prepobs_prep.bufrtable

# Only need this file for sst retrieval
bftab_sst=${FIX_ROOT}/bufrtab.012


#  copy Fixed fields to working directory
ln -sf $ANAVINFO anavinfo
ln -sf $BERROR   berror_stats
ln -sf $SATANGL  satbias_angle
ln -sf $atmsbeamdat  atms_beamwidth.txt
ln -sf $SATINFO  satinfo
ln -sf $scaninfo scaninfo
ln -sf $CONVINFO convinfo
ln -sf $OZINFO   ozinfo
ln -sf $PCPINFO  pcpinfo
ln -sf $OBERROR  errtable

ln -sf $bufrtable ./prepobs_prep.bufrtable
ln -sf $bftab_sst ./bftab_sstphr
# satellite radiance air bias correction coefficient
#if [ -s $GSIOUT/gdas1_update.satbias_in_${DATE}${TIME} ]; then
#    ln -sf  $GSIOUT/gdas1_update.satbias_in_${DATE}${TIME}  ./satbias_in
#else
#    ln -sf  $GSIFIX/gdas1.abias.new          ./satbias_in
#fi

ln -sf $OBS_ROOT/gdas1.t${TIME}z.abias                   ./satbias_in
#
# CRTM Spectral and Transmittance coefficients
emiscoef_IRwater=${CRTM_ROOT}/Nalli.IRwater.EmisCoeff.bin
emiscoef_IRice=${CRTM_ROOT}/NPOESS.IRice.EmisCoeff.bin
emiscoef_IRland=${CRTM_ROOT}/NPOESS.IRland.EmisCoeff.bin
emiscoef_IRsnow=${CRTM_ROOT}/NPOESS.IRsnow.EmisCoeff.bin
emiscoef_VISice=${CRTM_ROOT}/NPOESS.VISice.EmisCoeff.bin
emiscoef_VISland=${CRTM_ROOT}/NPOESS.VISland.EmisCoeff.bin
emiscoef_VISsnow=${CRTM_ROOT}/NPOESS.VISsnow.EmisCoeff.bin
emiscoef_VISwater=${CRTM_ROOT}/NPOESS.VISwater.EmisCoeff.bin
emiscoef_MWwater=${CRTM_ROOT}/FASTEM5.MWwater.EmisCoeff.bin
aercoef=${CRTM_ROOT}/AerosolCoeff.bin
cldcoef=${CRTM_ROOT}/CloudCoeff.bin

ln -sf $emiscoef_IRwater ./Nalli.IRwater.EmisCoeff.bin
ln -sf $emiscoef_IRice ./NPOESS.IRice.EmisCoeff.bin
ln -sf $emiscoef_IRsnow ./NPOESS.IRsnow.EmisCoeff.bin
ln -sf $emiscoef_IRland ./NPOESS.IRland.EmisCoeff.bin
ln -sf $emiscoef_VISice ./NPOESS.VISice.EmisCoeff.bin
ln -sf $emiscoef_VISland ./NPOESS.VISland.EmisCoeff.bin
ln -sf $emiscoef_VISsnow ./NPOESS.VISsnow.EmisCoeff.bin
ln -sf $emiscoef_VISwater ./NPOESS.VISwater.EmisCoeff.bin
ln -sf $emiscoef_MWwater ./FASTEM5.MWwater.EmisCoeff.bin
ln -sf $aercoef  ./AerosolCoeff.bin
ln -sf $cldcoef  ./CloudCoeff.bin
# Copy CRTM coefficient files based on entries in satinfo file
for file in `awk '{if($1!~"!"){print $1}}' ./satinfo | sort | uniq` ;do
   ln -sf ${CRTM_ROOT}/${file}.SpcCoeff.bin ./
   ln -sf ${CRTM_ROOT}/${file}.TauCoeff.bin ./
done

#
###################################################
#  run  GSI
###################################################
echo ' Run GSI with background'

./gsi.exe < gsiparm.anl # &>stdout 


##################################################################
#  run time error check
##################################################################
error=$?

if [ ${error} -ne 0 ]; then
  echo "ERROR: ${GSI} crashed  Exit status=${error}"
  exit ${error}
fi
#
##################################################################
#
# Copy the output to more understandable names
#ln -s stdout      stdout.anl.${DATE1}${TIME1}
#ln -s fort.201    fit_p1.${DATE1}${TIME1}
#ln -s fort.202    fit_w1.${DATE1}${TIME1}
#ln -s fort.203    fit_t1.${DATE1}${TIME1}
#ln -s fort.204    fit_q1.${DATE1}${TIME1}
#ln -s fort.207    fit_rad1.${DATE1}${TIME1}
#==== Save output ===============================
cp $RUN_ROOT/siganl          $ANLDAT/zsp$TIME1.dat$DATE1

#anex= cp satbias_out  $GSIFIX/gdas1.abias.new.change
cp $RUN_ROOT/satbias_out  $GSIOUT/gdas1_update.satbias_in_${DATE1}${TIME1}
cp $RUN_ROOT/fort.201     $GSIOUT/fit_p1.201_${DATE1}${TIME1}
cp $RUN_ROOT/fort.202     $GSIOUT/fit_w1.202_${DATE1}${TIME1}
cp $RUN_ROOT/fort.203     $GSIOUT/fit_t1.203_${DATE1}${TIME1}
cp $RUN_ROOT/fort.204     $GSIOUT/fit_q1.204_${DATE1}${TIME1}
cp $RUN_ROOT/fort.207     $GSIOUT/fit_rad1.207_${DATE1}${TIME1}
cp $RUN_ROOT/fort.220     $GSIOUT/fort.220_${DATE1}${TIME1}

# Loop over first and last outer loops to generate innovation
# diagnostic files for indicated observation types (groups)
#
# NOTE:  Since we set miter=2 in GSI namelist SETUP, outer
#        loop 03 will contain innovations with respect to
#        the analysis.  Creation of o-a innovation files
#        is triggered by write_diag(3)=.true.  The setting
#        write_diag(1)=.true. turns on creation of o-g
#        innovation files.
#

echo "Time before diagnostic loop is `date` "
loops="01 03"
for loop in $loops; do

case $loop in
  01) string=ges;;
  03) string=anl;;
   *) string=$loop;;
esac

#  Collect diagnostic files for obs types (groups) below
   listall="hirs2_n14 msu_n14 sndr_g08 sndr_g11 sndr_g11 sndr_g12 sndr_g13 sndr_g08_prep sndr_g11_prep sndr_g12_prep sndr_g13_prep sndrd1_g11 sndrd2_g11 sndrd3_g11 sndrd4_g11 sndrd1_g12 sndrd2_g12 sndrd3_g12 sndrd4_g12 sndrd1_g13 sndrd2_g13 sndrd3_g13 sndrd4_g13 hirs3_n15 hirs3_n16 hirs3_n17 amsua_n15 amsua_n16 amsua_n17 amsub_n15 amsub_n16 amsub_n17 hsb_aqua airs_aqua amsua_aqua imgr_g08 imgr_g11 imgr_g12 pcp_ssmi_dmsp pcp_tmi_trmm conv sbuv2_n16 sbuv2_n17 sbuv2_n18 sbuv2_n19 gome_metop-a omi_aura ssmi_f13 ssmi_f14 ssmi_f15 hirs4_n18 hirs4_metop-a amsua_n18 amsua_metop-a mhs_n18 mhs_metop-a amsre_low_aqua amsre_mid_aqua amsre_hig_aqua ssmis_las_f16 ssmis_uas_f16 ssmis_img_f16 ssmis_env_f16 iasi_metop-a hirs4_n19 amsua_n19 mhs_n19 seviri_m08 seviri_m09 seviri_m10"
   for type in $listall; do
      count=`ls ${RUN_ROOT}/dir.*/${type}_${loop}* | wc -l`
      if [[ $count -gt 0 ]]; then
         cat dir.*/${type}_${loop}* > diag_${type}_${string}.${DATE1}${TIME1}
         gzip diag_${type}_${string}.${DATE1}${TIME1}
      fi
   done
done
mv diag_*.${DATE1}${TIME1}.gz     $GSIOUT/
cp  $LOGDIR/gsi.out    $BAKLOG/gsi.out_$DATE1$TIME1 
cp  $LOGDIR/gsi.err    $BAKLOG/gsi.err_$DATE1$TIME1
#=================================================================
llsubmit   $SCRIPT/gridspec_639.ksh
#=================================================================
#=============================================================================#

echo "Time after diagnostic loop is `date` "

#  Clean working directory to save only important files 
if [ ${if_clean} = clean ]; then
  echo ' Clean working directory after GSI run'
  rm -f *Coeff.bin     # all CRTM coefficient files
  rm -fr dir.*         # diag files on each processor
  rm -f obs_input.*    # observation middle files
  rm -f sigf* sfcf*    # background  files
  rm -f fsize_*        # delete temperal file for bufr size
fi

exit 0
