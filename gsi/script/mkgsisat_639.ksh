# This is a job command file of cbsat
#!/bin/ksh
# Loadlevel Job Keywords Configuration
# @ comment = T639
# @ job_name = mkgsisat
# @ job_type = serial
# @ initialdir= /cmd/u/yaosh/T639L60_GSI3.3/logdir
# @ output = $(initialdir)/$(job_name).out
# @ error  = $(initialdir)/$(job_name).err
#
# @ notification = error
# @ checkpoint = no
# @ restart = no
# @ node_usage = shared
# @ wall_clock_limit = 00:35:00
# @ class = serial
# @ queue



#===================================================================#
# Set up running variables, such as path and directories
set -x
  export WORKDIR=/cmd/u/yaosh/T639L60_GSI3.3
       . $WORKDIR/script/envars.ksh

#================================================================
#=====  Set for this job itself.===========================   ##
export ORACLE_BASE=/space/app/oracle
export ORACLE_HOME=/space/app/oracle/product/9.2
export PATH=$ORACLE_HOME/bin:$PATH

#================================================================
  if [ ! -d $RUNDIR ] ; then
       mkdir -p $RUNDIR
  else 
      rm -rf $RUNDIR/*
  fi

  if [ ! -d $OBSDIR ] ; then
       mkdir -p $OBSDIR
  fi

  if [ ! -d $SATDAT ] ; then
    mkdir $SATDAT
  else 
    rm -rf $SATDAT/*
  fi

  if [ ! -d $BAKDAT ] ; then
       mkdir -p $BAKDAT
  fi
  if [ ! -d $BAKLOG ] ; then
       mkdir -p $BAKLOG
  fi

#===================================================================#
  test -f $LOGDIR/DATE ||  { echo file DATE not exist ; exit 1; }
  test -f $LOGDIR/TIME ||  { echo file TIME not exist ; exit 1; }

  DATE=`cat $LOGDIR/DATE`
  TIME=`cat $LOGDIR/TIME`
  DATE1=`${EXEDIR}/smsdate $DATE$TIME +06 | cut -c1-8`
  TIME1=`${EXEDIR}/smsdate $DATE$TIME +06 | cut -c9-10`
  DATE2=`${EXEDIR}/smsdate $DATE1$TIME1 +06 | cut -c1-8`
  TIME2=`${EXEDIR}/smsdate $DATE1$TIME1 +06 | cut -c9-10`

  echo $DATE $TIME $DATE1 $TIME1 $DATE2 $TIME2 

  MMMM='0000'
  DATEB3=`${EXEDIR}/smsdate $DATE1$TIME1 -03 | cut -c5-10`
  DATEA3=`${EXEDIR}/smsdate $DATE1$TIME1 +03 | cut -c5-10`
  DATEB3=${DATEB3}${MMMM}
  DATEA3=${DATEA3}${MMMM}

  echo $DATEB3 $DATEA3

#===========================================================================#
#==!!!!!!!!!!!!!! Pay More Attention to 00 UTC !!!!!!!!!!!!==#
#--------------------------------------------------------------
#   get NSMC data from ...*.bin 
#--------------------------------------------------------------
  cd $RUNDIR

  cp $EXEDIR/obs_atov.x    $RUNDIR/.

#anex=  $RUNDIR/obs_atov.x $DATE1 $TIME1   
#anex=  $RUNDIR/obs_atov.x $DATE $TIME   

#----------------------------------------------------------------
#   end of file download, put it in gsi,SATDATA,satadata
#----------------------------------------------------------------
#===========================================================================#

 cd $RUNDIR

#anex cp  $EXEDIR/combin_NSMC_ama_bin_sec_new.x ./
#anex cp  $EXEDIR/combin_NSMC_amb_bin_sec_new.x ./
#anex cp  $EXEDIR/NSMC-NMC-ama.x  ./
#anex cp  $EXEDIR/NSMC-NMC-amb.x  ./

 cp  $EXEDIR/combin_NSMC_AMA_bin_sec_new.x ./
 cp  $EXEDIR/combin_NSMC_AMB_bin_sec_new.x ./
 cp  $EXEDIR/NSMC-NMC-AMA.x  ./
 cp  $EXEDIR/NSMC-NMC-AMB.x  ./


#anexfor satn in na15 na16 na17 
#anex do
#anex  for sensor in ama amb
for satn in NA15 NA16 NA17
 do
  for sensor in AMA AMB
   do
     echo "===================" $satn $sensor "=========================="
#anex     if [ -s Z*${satn}*${sensor}*.bin ] ; then
#anex        eval ls Z*${satn}*${sensor}*.bin >${satn}_${sensor}_${DATE1}${TIME1}.txt 
#anex     fi
     if [ -s Z*${satn}*${sensor}*.BIN ] ; then
        eval ls Z*${satn}*${sensor}*.BIN >${satn}_${sensor}_${DATE1}${TIME1}.txt 
     fi

#==============================  combine data  ============================#   
       if [ -f ${satn}_${sensor}_${DATE1}${TIME1}.txt ] ; then
         while read line
         do

           PWDP=`pwd`
           echo $PWD
           filename=`echo $line`
           echo $filename

           echo  combin_NSMC_${sensor}_bin_sec_new.x
           echo combin_NSMC_${sensor}_bin_sec_new.x $filename  ${DATE1} ${TIME1} ${satn} $DATEB3 $DATEA3
           set +e
     #anex=      combin_NSMC_${sensor}_bin_sec_new.x $filename  ${DATE1} ${TIME1} ${satn} $DATEB3 $DATEA3
           set -e

         done<${satn}_${sensor}_${DATE1}${TIME1}.txt

         set +e
#anex=         NSMC-NMC-${sensor}.x NSMC.${satn}.1c${sensor}.${DATE1}.t${TIME1}.bin NSMC.${satn}.1c${sensor}.${DATE1}.t${TIME1}
         echo $?
         set -e

       fi
   done
 done
#==========================================================================
 test -s NSMC.NA15.1cAMA.${DATE1}.t${TIME1} && mv NSMC.NA15.1cAMA.${DATE1}.t${TIME1} NSMC.na15.1cama.${DATE1}.t${TIME1}
 test -s NSMC.NA16.1cAMA.${DATE1}.t${TIME1} && mv NSMC.NA16.1cAMA.${DATE1}.t${TIME1} NSMC.na16.1cama.${DATE1}.t${TIME1}
 test -s NSMC.NA17.1cAMA.${DATE1}.t${TIME1} && mv NSMC.NA17.1cAMA.${DATE1}.t${TIME1} NSMC.na17.1cama.${DATE1}.t${TIME1}
 test -s NSMC.NA15.1cAMB.${DATE1}.t${TIME1} && mv NSMC.NA15.1cAMB.${DATE1}.t${TIME1} NSMC.na15.1camb.${DATE1}.t${TIME1}
 test -s NSMC.NA16.1cAMB.${DATE1}.t${TIME1} && mv NSMC.NA16.1cAMB.${DATE1}.t${TIME1} NSMC.na16.1camb.${DATE1}.t${TIME1}
 test -s NSMC.NA17.1cAMB.${DATE1}.t${TIME1} && mv NSMC.NA17.1cAMB.${DATE1}.t${TIME1} NSMC.na17.1camb.${DATE1}.t${TIME1}
#==========================================================================
  if [ -s $RUNDIR/NSMC.*.1c*.${DATE1}.t${TIME1} ] ; then
     echo sat combine successfully
     echo satellite data ${DATE1}${TIME1} ready > $LOGDIR/satdata.flag
     cp -p  ${RUNDIR}/NSMC*$DATE1.t$TIME1   ${SATDAT}/
     cp -p  ${RUNDIR}/NA*$DATE1$TIME1.txt   ${SATDAT}/

#zt     SATLIB=/pgpfs/fs4/typh_qu/Data_Bank/satdata
#anex     cp -p  ${RUNDIR}/NSMC*$DATE1.t$TIME1   ${SATLIB}/
#anex     cp -p  ${RUNDIR}/NA*$DATE1$TIME1.txt   ${SATLIB}/
  else
     echo no sat file wrong !!!!!!!!!!!!!!!!!!!!!!!!!!!
  fi

# ===============to get historical satellite data  add by anex nian ===========#
YYYYMM=$(echo $DATE1 | cut -c1-6)
YYYY=$(echo $DATE1 | cut -c1-4)

#== my obs bank =====================================
#zt MY_SAT_BANK=/cmd/u/yaosh/Data_Bank/satdata/${YYYY}

#--------------------------------------------------------------------------------
if [ -s ${MY_SAT_BANK}/NSMC*.${DATE1}.t${TIME1} ]; then
#--------------------------------------------------------------------------------

   echo "GET SAT DATA "
   cp    ${MY_SAT_BANK}/NSMC*.${DATE1}.t${TIME1}   ${SATDAT}/.


else
   echo  "no find satellite data"
#   exit 0
#--------------------------------------------------------------------------------
fi
#--------------------------------------------------------------------------------
# ==============================================================================

#=============================================================================#
YYYY=$(echo $DATE1 | cut -c1-4)
#zt TCMESSBANK=/cmd/u/yaosh/Data_Bank/tcmess_data/${YYYY}
 if [ -s ${TCMESSBANK}/tc_report_${DATE1}${TIME1} ]; then
     test -d ${TCMESS} || mkdir ${TCMESS}     
     rm -rf ${TCMESS}/*
     cp ${TCMESSBANK}/tc_report_${DATE1}${TIME1}  ${TCMESS}/.
     if [ -s ${TCMESSBANK}/tc_report_${DATE}${TIME} ]; then
         cp ${TCMESSBANK}/tc_report_${DATE}${TIME}  ${TCMESS}/
     fi
     llsubmit  $SCRIPT/vortex_relocat_639.ksh
 else
    echo  no real time tc_report_${DATE1}${TIME1}
#      llsubmit  $SCRIPT/gsi_639.ksh 
llsubmit  $SCRIPT/run_gsi_global.ksh
 fi

#=============================================================================#
#anex=  cp -p  $LOGDIR/mkgsisat.out    $BAKLOG/mkgsisat.out_$DATE1$TIME1 
#anex=  cp -p  $LOGDIR/mkgsisat.err    $BAKLOG/mkgsisat.err_$DATE1$TIME1
#=============================================================================#
exit 0
