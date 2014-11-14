#!/bin/ksh
##BSUB -P P64000420
#BSUB -P NMMM0006
#BSUB -n 1
#BSUB -J diag
#BSUB -o job.gsi_rad_diag
#BSUB -e job.gsi_rad_diag
#BSUB -q caldera
#BSUB -W 00:30
#########################################################################
# Script: da_rad_diags.ksh  (radiance time-series diagnostics)
# 
# Purpose: run inv*/oma* data processing program to generate files in 
# netcdf format and use NCL plotting script
# (plot_rad_diags.ncl and utils_hclin.ncl) to make plots.
#
# Description:
#
### Data processing for WRF-Var:
#
# input files: (1)  namelist.da_rad_diags
#                   &record1
#                    nproc = 16   (the proc numbers WRF-Var used)
#                    instid = 'noaa-17-amsub', 'dmsp-16-ssmis'  (inst names)
#                    file_prefix = "inv"       (either "inv", or "oma")
#                    start_date = '2005082000'
#                    end_date   = '2005083018'
#                    cycle_period  = 6
#                   /
#              (2) inv_* or oma_* from WRF-Var
#                  (note: da_rad_diags.f90 expects the files to be in the date directory
#                   in the program working directory, therefore, it's necessary to link
#                   or copy inv_* or oma_* to the required dirctory structure.)
#
### Data processing for GSI:
#
# input files: (1)  namelist.gsi_rad_diags
#                   &record1
#                    diag_type = 2  (1: only obs-ges, 2: obs-ges and obs-anl), 0: sensitivity)
#                    instid = 'amsua_n15', 'amsua_n16',  (inst names)
#                    start_date = '2007081506'
#                    end_date   = '2007081512'
#                    cycle_period = 6
#                   /
#               (2) diag_${instid}_ges and/or diag_${instid}_anl from GSI
#                   (note: gsi_rad_diags.f90 expects the files to be in the date directory
#                    in the program working directory, therefore, it's necessary to link
#                    or copy diag_* to the required dirctory structure.)
#
### plotting                   
#
# plot_rad_diags.ncl is the main NCL script.
# A date advancing NCL script, utils_hclin.ncl, is loaded in plot_rad_diags.ncl.
#
#set -x
#---------------------------------------------------------------------
# user-defined options
#---------------------------------------------------------------------
#
export START_DATE1=20140601
export START_TIME1=06
export START_DATE=2014060106

export END_DATE1=20140601
export END_TIME1=06
export END_DATE=2014060106

export CYCLE_PERIOD=06
export type=gsi_3dvar
export EXPT=CRAS

export GSI_UTIL_DIR=$HOME/ys_GSI_DIAG  #  /glade/p/work/hclin/code_intel/GSI/misc
export DIAG_RUN_DIR=$HOME/ys_GSI_DIAG/rad   # ${EXP_DIR}/diag_rad_ref${ADJ_REF}
export PLOTDIR=$DIAG_RUN_DIR/PLOT/

   #set -A INSTIDS amsua_n15 amsua_n16 amsua_n17 amsub_n15 amsub_n16 amsub_n17 airs_aqua amsua_aqua amsua_n18 amsua_metop-a mhs_n18 mhs_metop-a
   set -A INSTIDS amsua_n15 amsua_n18 amsua_n19 amsua_metop-a mhs_n18 mhs_n19 mhs_metop-a
   #set -A INSTIDS atms_npp cris_npp
   #set -A INSTIDS amsua_metop-a amsua_n18 hirs4_metop-a mhs_metop-a mhs_n18 amsua_n19 hirs4_n19 mhs_n19 atms_npp cris_npp iasi_metop-a airs_aqua
   #set -A INSTIDS mhs_n18
#
export LINK_DATA=true   # link inv* or oma* files in wrfvar/working directory to be in $DIAG_RUN_DIR/$DATE
export PROC_DATA=true   # collect and convert ascii files to netcdf files
export PROC_PLOT=true   # make plots
#
# environment variables to be passed to the plotting NCL script
#
export OUT_TYPE=pdf            # ncgm, pdf (pdf will be much slower than ncgm and 
                                #            generate huge output if plots are not splitted)
                                # pdf will generated plots in higher resolution
export PLOT_STATS_ONLY=false
export PLOT_OPT=all             # all, sea_only, land_only
export PLOT_QCED=true           # true, false.
export PLOT_COVER=true          # true, false. switch for coverage plot
export PLOT_HISTO=true         # true, false. switch for histogram plot
export PLOT_SCATT=true          # true, false. switch for scatter plot
export PLOT_EMISS=false         # true, false. switch for emissivity plot
export PLOT_SPLIT=false         # true, false. Set true to plot one frame in one file.
export PLOT_CLOUDY=false        # true, false. If plotting cloudy points.
                                # cloudy points are defined by the following 
                                # PLOT_CLOUDY_OPT, CLWP_VALUE, SI_VALUE settings.
export DATDIR=$PLOTDIR    # the tailing / is necessary
#
# set up mapping info for plotting
#
# for typical application, just set the following
# 3 variables to let the scripts extract mapping info
# from the first-guess file used in WRF-Var

export MAPINFO_FROM_FILE=false   # true, false
export SUBDOMAIN=false          # true, false

if ! $MAPINFO_FROM_FILE; then   # MAPINFO_FROM_FILE=false
#
# manually set the plotting area here
#
   if ! $SUBDOMAIN; then  # SUBDOMAIN=false, the map is bounded by corner points
      export MAP_PROJ=3     # for now, only 1 (lambert) or 3 (mercator)
      if [[ $MAP_PROJ == 1 ]]; then
         export TRUELAT1=30.
         export TRUELAT2=60.
         export STAND_LON=-98.
      fi
      export LAT_LL=-90.0   # Lower-Left corner latitude
      export LON_LL=-180.0    # Lower-Left corner longitude
      export LAT_UR=90.0    # Upper-Right corner latitude
      export LON_UR=180.0    # Upper-Right corner longitude
   else   # SUBDOMAIN = True, map is defined by lat/lon box 
      export MAXLAT=28.0
      export MINLAT=20.5
      export MAXLON=-81.0
      export MINLON=-89.0
   fi
else   # MAPINFO_FROM_FILE = true
   #export MAP_PROJ=$(ncdump -h $FGFILE | grep "MAP_PROJ =" | awk '{print $3}')
   if $SUBDOMAIN; then
      if [[ $MAP_PROJ == 1 ]]; then
         export MAPINFO_FROM_FILE=false # subdomain has to be a latlon box
                                        # Lambert projection (MAP_PROJ=1)
                                        # can not be used to set a subdomain.
                                        # MAXLAT, MINLAT, MAXLON, MINLON have
                                        # to be set.
         export MAXLAT=28.0
         export MINLAT=20.5
         export MAXLON=-81.0
         export MINLON=-89.0
      fi
   fi
fi
#
#---------------------------------------------------------------------
# linking inv/oma data to be in the form required by the data processing program
# for example, 2005082700/inv*
#---------------------------------------------------------------------
#
if $LINK_DATA; then
   DATE1=${START_DATE1}
   TIME1=${START_TIME1}
   DATE=${DATE1}${TIME1}
   echo $DATE
   while [[ $DATE -le ${END_DATE1}${END_TIME1} ]]; do
      if [[ ! -d $DATDIR/$DATE ]]; then
         mkdir -p $DATDIR/$DATE
      fi
      cd $DATDIR/$DATE

      cp $DIAG_RUN_DIR/DIAG/diag_amsua_n15_ges.$DATE ./diag_amsua_n15_ges
      cp $DIAG_RUN_DIR/DIAG/diag_amsua_n18_ges.$DATE ./diag_amsua_n18_ges
      cp $DIAG_RUN_DIR/DIAG/diag_amsua_n19_ges.$DATE ./diag_amsua_n19_ges
      cp $DIAG_RUN_DIR/DIAG/diag_amsua_metop-a_ges.$DATE ./diag_amsua_metop-a_ges
      cp $DIAG_RUN_DIR/DIAG/diag_mhs_n18_ges.$DATE ./diag_mhs_n18_ges
      cp $DIAG_RUN_DIR/DIAG/diag_mhs_n19_ges.$DATE ./diag_mhs_n19_ges
      cp $DIAG_RUN_DIR/DIAG/diag_mhs_metop-a_ges.$DATE ./diag_mhs_metop-a_ges

      cp $DIAG_RUN_DIR/DIAG/diag_amsua_n15_anl.$DATE ./diag_amsua_n15_anl
      cp $DIAG_RUN_DIR/DIAG/diag_amsua_n18_anl.$DATE ./diag_amsua_n18_anl
      cp $DIAG_RUN_DIR/DIAG/diag_amsua_n19_anl.$DATE ./diag_amsua_n19_anl
      cp $DIAG_RUN_DIR/DIAG/diag_amsua_metop-a_anl.$DATE ./diag_amsua_metop-a_anl
      cp $DIAG_RUN_DIR/DIAG/diag_mhs_n18_anl.$DATE ./diag_mhs_n18_anl
      cp $DIAG_RUN_DIR/DIAG/diag_mhs_n19_anl.$DATE ./diag_mhs_n19_anl
      cp $DIAG_RUN_DIR/DIAG/diag_mhs_metop-a_anl.$DATE ./diag_mhs_metop-a_anl

      DATE1=`zt_date +%Y%m%d -d "$DATE1 $TIME1 6 hour"`
      TIME1=`zt_date +%H -d "$DATE1 $TIME1 6 hour"`
      DATE=${DATE1}${TIME1}
      echo $DATE
   done
fi

cd $DIAG_RUN_DIR/PLOT
#
#---------------------------------------------------------------------
# inv/oma data processing section
#---------------------------------------------------------------------
#
if $PROC_DATA; then
      ln -sf ${GSI_UTIL_DIR}/rad/gsi_diag_rad.exe ./gsi_diag_rad.exe
#
# create namelist
#
   n=0
   INSTID=''
   for instID in ${INSTIDS[*]}; do
      let n=$n+1
      INSTID=" ${INSTID} '${instID}', "
   done

      if [[ -e namelist.gsi_diag_rad ]]; then
         rm -f namelist.gsi_diag_rad
      fi
      cat > namelist.gsi_diag_rad << EOF
&record1
diag_type = 2 
instid = ${INSTID}
start_date = '${START_DATE}${START_TIME}'
end_date   = '${END_DATE}${END_TIME}'
cycle_period  = $CYCLE_PERIOD
/
EOF
#
# run the format convertor
#
      ./gsi_diag_rad.exe

fi
#
#---------------------------------------------------------------------
# plot
#---------------------------------------------------------------------
#
if $PROC_PLOT; then
   ln -sf ${GSI_UTIL_DIR}/utils_hclin.ncl ./utils_hclin.ncl
   cp -p ${GSI_UTIL_DIR}/rad/plot_rad_diags.ncl ./plot_rad_diags.ncl

   if $MAPINFO_FROM_FILE; then
      export MAP_PROJ=$(ncdump -h $FGFILE | grep "MAP_PROJ =" | awk '{print $3}')
      export TRUELAT1=$(ncdump -h $FGFILE | grep "TRUELAT1 =" | awk '{print $3}')
      export TRUELAT2=$(ncdump -h $FGFILE | grep "TRUELAT2 =" | awk '{print $3}')
      export STAND_LON=$(ncdump -h $FGFILE | grep "STAND_LON =" | awk '{print $3}')
      export CEN_LON=$(ncdump -h $FGFILE | grep "CEN_LON =" | awk '{print $3}')
      export CEN_LAT=$(ncdump -h $FGFILE | grep "CEN_LAT =" | awk '{print $3}')
echo "$CEN_LON"
echo $CEN_LON

   fi
   for instID in ${INSTIDS[*]}; do    # loop for instruments
      export INSTRUMENT=$instID
      export LIBPATH=/cma/u/app/ncl/bin:$LIBPATH
      ncl ./plot_rad_diags.ncl
   done
fi

exit
