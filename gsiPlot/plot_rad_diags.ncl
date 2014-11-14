;
; Author: Hui-Chuan Lin
;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "./utils_hclin.ncl"

begin

;*******************************************************************************
; plot options
;*******************************************************************************
 
   plot_cover = True
   plot_histo = True
   plot_scatt = True
   plot_emiss = False
   plot_sflag = False 
   write_txt  = False

   plot_stats_only = False

   plot_ch_all = True                ; True to plot all channels
   ;   plot_ch_all = False                 ; False to plot user-selected plot_ch channels
   if ( .not. plot_ch_all ) then
      plot_ch  = (/ 5, 6/)          ; edit this line to set the channels to plot
   end if

   plot_opt = "all"
   ;   plot_opt = "land_only"
   ;   plot_opt = "sea_only"

   plot_cloudy = False
   ;   plot_cloudy = True

   plot_cloudy_opt = "clwp"
   ;   plot_cloudy_opt = "si"
   ;   plot_cloudy_opt = "si_clwp"

   clwp_value = 0.
   si_value   = 3.

   plot_qced = True        ; True to plot qc=good data
   ;   plot_qced = False

   ;   plot_split = True
   plot_split = False

   out_type = "ncgm"
   ;   out_type = "pdf"   ; pdf not recommended since the file size will be way too large
                       ; and it will take much much longer to make plots
   ;   instrument = "eos-2-airs"
   instrument = "amsua_n18"
   datdir = "./"
   plotdir = "./"
   expt = ""

   start_date   = "2007081506"
   end_date     = "2007081512"
   cycle_period = 06

   ; rc_dir       = "/Volumes/sausage2/hclin/exps/t44_45km/rc/"
   ; fname = rc_dir+"/"+start_date+"/"+"/wrfinput_d01"
   fname = "/glade/p/mmm/schwartz/afwa_fy_2013/3dvar_cycled_bc/2013102012/gsi_3dvar/d01/wrf_inout_orig" ; "/ptmp/hclin/t44_45km/rc/2007081500/wrfinput_d01"

   ;   colormap = "rainbow"
   colormap = "gui_default"

   ; subdomain = True
   subdomain = False
   mapinfo_from_file = True

   if ( mapinfo_from_file .and. isfilepresent(fname) ) then
      wrf_file=addfile(fname+".nc","r")
      if ( wrf_file@MAP_PROJ .eq. 1 ) then
         mapproj = "LambertConformal"
         truelat1 = wrf_file@TRUELAT1
         truelat2 = wrf_file@TRUELAT2
         clon     = wrf_file@STAND_LON
      end if
      if ( wrf_file@MAP_PROJ .eq. 2 ) then
         mapproj = "Stereographic"
         truelat1 = wrf_file@TRUELAT1
         truelat2 = wrf_file@TRUELAT2
         clon     = wrf_file@CEN_LON
         clat     = wrf_file@CEN_LAT
      end if
      if ( wrf_file@MAP_PROJ .eq. 3 ) then
         mapproj = "Mercator"
      end if
      dsizes = getfiledimsizes(wrf_file)
      nx = dsizes(2)
      ny = dsizes(3)
      xlat=wrf_file->XLAT
      xlon=wrf_file->XLONG
      lat_ll  = xlat(0,0,0)
      lat_ur  = xlat(0,ny-1,nx-1)
      lon_ll  = xlon(0,0,0)
      lon_ur  = xlon(0,ny-1,nx-1)
      if ( subdomain .and. wrf_file@MAP_PROJ .eq. 3 ) then
         maxlat = lat_ur
         minlat = lat_ll
         maxlon = lon_ur
         minlon = lon_ll
      else
         maxlat = 25.
         minlat =  5.
         maxlon = 80.
         minlon = 60.
      end if
   else
      if ( .not. subdomain ) then
         ; mapproj = "LambertConformal"
         mapproj = "Mercator"
         if ( mapproj .eq. "LambertConformal" ) then
            truelat1 = 30.
            truelat2 = 60.
            clon     = -98.
         end if
         lat_ll = -90.0
         lon_ll = -180.0
         lat_ur = 90.0
         lon_ur = 180.0
      end if
      if ( subdomain ) then
         maxlat = 25.
         minlat =  5.
         maxlon = 80.
         minlon = 60.
      end if
   end if


   ;*******************************************************************************
   ; end of plot options
   ;*******************************************************************************

   ; if running this ncl script from a csh script
   ; replace the following settings with the ones in the script
   if ( .not. ismissing(getenv("INSTRUMENT")) ) then
      if ( .not. plot_ch_all ) then
         delete(plot_ch)
      end if
      ; string
      plot_opt    = getenv("PLOT_OPT")
      if ( getenv("PLOT_CLOUDY").eq."true" .or. getenv("PLOT_CLOUDY").eq."True" ) then
         plot_cloudy = True
      else
         plot_cloudy = False
      end if
      if ( plot_cloudy ) then
         plot_cloudy_opt = getenv("PLOT_CLOUDY_OPT")
         clwp_value      = stringtofloat(getenv("CLWP_VALUE"))
         si_value        = stringtofloat(getenv("SI_VALUE"))
      end if
      out_type    = getenv("OUT_TYPE")
      instrument  = getenv("INSTRUMENT")
      expt        = getenv("EXPT")
      start_date  = getenv("START_DATE")
      end_date    = getenv("END_DATE")
      cycle_period= stringtointeger(getenv("CYCLE_PERIOD"))
      datdir      = getenv("DATDIR")
      plotdir     = getenv("PLOTDIR")
      if ( getenv("SUBDOMAIN").eq."true" .or. getenv("SUBDOMAIN").eq."True" ) then
         subdomain = True
      else
         subdomain = False
      end if
      if ( getenv("MAPINFO_FROM_FILE").eq."true" .or. getenv("MAPINFO_FROM_FILE").eq."True" ) then
         mapinfo_from_file = True
      else
         mapinfo_from_file = False
      end if
      if ( .not. subdomain ) then
         mproj     = stringtointeger(getenv("MAP_PROJ"))
         if ( mproj .eq. 1 ) then
            mapproj = "LambertConformal"
            truelat1    = stringtofloat(getenv("TRUELAT1"))
            truelat2    = stringtofloat(getenv("TRUELAT2"))
            clon        = stringtofloat(getenv("STAND_LON"))
         end if
         if ( mproj .eq. 2 ) then
            mapproj = "Stereographic"
            truelat1    = stringtofloat(getenv("TRUELAT1"))
            truelat2    = stringtofloat(getenv("TRUELAT2"))
            clon        = stringtofloat(getenv("CEN_LON"))
            clat        = stringtofloat(getenv("CEN_LAT"))
         end if
         if ( mproj .eq. 3 ) then
            mapproj = "Mercator"
         end if
      end if
      if ( mapinfo_from_file ) then
         if ( isfilepresent(fname) ) then
            delete(dsizes)
            delete(xlat)
            delete(xlon)
         end if
         fname = getenv("FGFILE")
         wrf_file=addfile(fname+".nc","r")
         dsizes = getfiledimsizes(wrf_file)
         nx = dsizes(2)
         ny = dsizes(3)
         xlat=wrf_file->XLAT
         xlon=wrf_file->XLONG
         lat_ll  = xlat(0,0,0)
         lat_ur  = xlat(0,ny-1,nx-1)
         lon_ll  = xlon(0,0,0)
         lon_ur  = xlon(0,ny-1,nx-1)
         if ( subdomain ) then
            maxlat = lat_ur
            minlat = lat_ll
            maxlon = lon_ur
            minlon = lon_ll
         end if
      else
         if ( .not. subdomain ) then
            lat_ll      = stringtofloat(getenv("LAT_LL"))
            lon_ll      = stringtofloat(getenv("LON_LL"))
            lat_ur      = stringtofloat(getenv("LAT_UR"))
            lon_ur      = stringtofloat(getenv("LON_UR"))
         end if
         if ( subdomain ) then
            maxlat      = stringtofloat(getenv("MAXLAT"))
            minlat      = stringtofloat(getenv("MINLAT"))
            maxlon      = stringtofloat(getenv("MAXLON"))
            minlon      = stringtofloat(getenv("MINLON"))
         end if
      end if
      ; logical
      plot_ch_all = True
      if ( getenv("PLOT_SPLIT").eq."true" .or. getenv("PLOT_SPLIT").eq."True" ) then
         plot_split = True
      else
         plot_split = False
      end if
      if ( getenv("PLOT_QCED").eq."true" .or. getenv("PLOT_QCED").eq."True" ) then
         plot_qced = True
      else
         plot_qced = False
      end if
      if ( getenv("PLOT_STATS_ONLY").eq."true" .or. getenv("PLOT_STATS_ONLY").eq."True" ) then
         plot_stats_only = True
      else
         plot_stats_only = False
      end if
      if ( getenv("PLOT_COVER").eq."true" .or. getenv("PLOT_COVER").eq."True" ) then
         plot_cover = True
      else
         plot_cover = False
      end if
      if ( getenv("PLOT_SCATT").eq."true" .or. getenv("PLOT_SCATT").eq."True" ) then
         plot_scatt = True
      else
         plot_scatt = False
      end if
      if ( getenv("PLOT_HISTO").eq."true" .or. getenv("PLOT_HISTO").eq."True" ) then
         plot_histo = True
      else
         plot_histo = False
      end if
      if ( getenv("PLOT_EMISS").eq."true" .or. getenv("PLOT_EMISS").eq."True" ) then
         plot_emiss = True
      else
         plot_emiss = False
      end if
   end if

   inst = systemfunc("echo "+instrument+" | cut -f3 -d-")

   if ( .not. (inst.eq."amsua" .or. inst.eq."amsub" .or. inst.eq."mhs") ) then
      if ( plot_cloudy .and. plot_cloudy_opt.eq."si" ) then
         print("si (scatter index) is calculated only from amsua, amsub, and mhs")
         print("Please reset PLOT_CLOUDY_OPT=clwp")
         print("stop")
         exit
      end if
   end if

if ( instrument .eq. "eos-2-airs" .or. instrument .eq. "airs_aqua" ) then
plot_ch_all = False
plot_ch = (/ 310, 1382, 1694 /)
;plot_ch = (/ 190,192,198,201,204,207,210,215,216,221,226,227,232,252,253,256,257,261,262,267,272,295,299, \
;             305,310,321,325,333,338,355,362,375,475,484,497,528,587,672,787,791,870,914,950, \
;             1301,1304,1329,1371,1382,1415,1424,1449,1455,1477,1500,1519,1565,1574,1627,1669,1694,1766,1800,\
;             1826,1865,1866,1868,1869,1872,1873,1876,1881,1882,1911,1917,1918,1924,1928 /)  ; set the channels to plot
end if

   ;*******************************************************************************
   ; real end of plot options
   ;*******************************************************************************
   
   ; define and setup the lablebar colors
   ; only needs to be done once
   
   xlabels = get_xb_labels(start_date, end_date, cycle_period)
   xvalues = get_xb_values(start_date, end_date, cycle_period)

   wks = gsn_open_wks(out_type,plotdir+"tmp")
   gsn_define_colormap(wks,colormap)                 ; define colormap
   cmap = gsn_retrieve_colormap(wks)                 ; retreive colormap
   if ( colormap .eq. "rainbow" ) then
      num_bins = 175      ; rainbow colormap has 190 colors, use 15-189
      colors = new(num_bins,integer)
      colors(0) = 15
      colors(num_bins-1) = 189
      do i = 1, num_bins-2
          colors(i) = colors(0) + i
      end do
   end if
   if ( colormap .eq. "gui_default" ) then
      num_bins = 22       ; gui_default colormap has 24 colors, use 2-23
      colors = new(num_bins,integer)
      colors(0) = 2
      colors(num_bins-1) = 22
      do i = 1, num_bins-2
         colors(i) = colors(0) + i
      end do
   end if
   ; set label bar RGB color triplets
   labelbarcolors        = new((/num_bins,3/),float)
   do n = 0, num_bins-1
      labelbarcolors(n,:) = cmap(colors(n),:)
   end do
   destroy(wks)
   dummy = systemfunc("\rm -f "+plotdir+"tmp."+out_type)

   ; find out how many dates to process

   ntime = 0
   valid_date = start_date
   do while ( valid_date .le. end_date )
      ntime = ntime + 1
      valid_date = advance_cymdh(valid_date,cycle_period)
   end do
   date = new(ntime,string)
   mmddhh = new(ntime,string)
   date(0) = start_date
   cdate = stringtochar(date(0))
   mmddhh(0) = chartostring(cdate(4:9))
   do i = 1, ntime-1
      date(i) = advance_cymdh(date(i-1),cycle_period)
      cdate = stringtochar(date(i))
      mmddhh(i) = chartostring(cdate(4:9))
   end do
   print(date)
   xc = ispan(1,ntime,1)   ; set the x-axis values for statistics time-series plot

   ; begin the big ntime loop

   doneit = False   ; to check if the variables for statistics are already defined
   got_wn = False

   do itime = 0, ntime-1   ; this is ntime_loop

      filename = "diags_" + instrument + "_" + date(itime)

      if ( .not. isfilepresent(datdir+filename+".nc") ) then
         print("Can not find the file "+datdir+filename+".nc"+"  Will skip it")
         itproc = False    ; do not process this instrument for this time
      else
         itproc = True
         infile = addfile(datdir+filename+".nc","r")
         print("Processing date: "+date(itime))
         ;
         ; set the number (nchan) and indexes (plot_ch) of channels to be processed
         ;
         ichan = infile->ichan
         if ( plot_ch_all ) then
            nchan = dimsizes(ichan)
            plot_ch = ichan
         end if
         if ( .not. plot_ch_all ) then
            nchan = dimsizes(plot_ch)
         end if
         if ( instrument.eq."eos-2-airs" .or. instrument.eq."airs_aqua" ) then
            if ( .not. got_wn ) then
               wavenumber = infile->wavenumber
               wavenumber!0 = "chan"
               wavenumber&chan = ichan
               got_wn = True
            end if
         end if
         ;
         ; read in data
         ;
         gsi_diag = False
         if ( isfilevar(infile, "tb_qc_anl") ) then
            gsi_diag = True
         end if
         lat   = infile->lat
         lon   = infile->lon
         isflg = infile->isflg
         ; elev  = infile->elev
         clwp  = infile->clwp
         ems   = infile->ems
         obs   = infile->tb_obs
         bak   = infile->tb_bak
         oma   = infile->tb_oma
         omb_bc   = infile->tb_inv    ; omb with bias correction
         ems@_FillValue = ems@missing_value
         obs@_FillValue = obs@missing_value
         bak@_FillValue = bak@missing_value
         oma@_FillValue = oma@missing_value
         omb_bc@_FillValue = omb_bc@missing_value
         omb_nobc = where(.not.ismissing(obs) .and. .not.ismissing(bak), obs-bak, obs@_FillValue)
         obs_bc = where(.not.ismissing(bak) .and. .not.ismissing(omb_bc), bak+omb_bc, obs@_FillValue)
         ana = where(.not.ismissing(obs_bc) .and. .not.ismissing(oma), obs_bc-oma, obs@_FillValue)
         qc    = infile->tb_qc
         if ( gsi_diag ) then
            qc_anl    = infile->tb_qc_anl
         end if
         if ( num(.not.ismissing(oma)) .gt. 0 ) then
            got_oma = True
            np = 6   ; number of distribution plots
            ns = 3   ; number of scatter plots
            nh = 3   ; number of histogram plots
         else
            got_oma = False
            np = 5   ; number of distribution plots
            ns = 2   ; number of scatter plots
            nh = 2   ; number of histogram plots
         end if
         ;
         ; define named dimensions
         ;
         ems!0     = "pixel"
         ems!1     = "chan"
         ems&chan = ichan
         obs!0     = "pixel"
         obs!1     = "chan"
         obs&chan = ichan
         bak!0     = "pixel"
         bak!1     = "chan"
         bak&chan = ichan
         ana!0     = "pixel"
         ana!1     = "chan"
         ana&chan = ichan
         oma!0     = "pixel"
         oma!1     = "chan"
         oma&chan = ichan
         omb_bc!0     = "pixel"
         omb_bc!1     = "chan"
         omb_bc&chan = ichan
         omb_nobc!0     = "pixel"
         omb_nobc!1     = "chan"
         omb_nobc&chan = ichan
         obs_bc!0     = "pixel"
         obs_bc!1     = "chan"
         obs_bc&chan = ichan
         qc!0     = "pixel"
         qc!1     = "chan"
         qc&chan = ichan
         if ( gsi_diag ) then
            qc_anl!0     = "pixel"
            qc_anl!1     = "chan"
            qc_anl&chan  = ichan
         end if
      end if

      if ( (.not. plot_stats_only) .and. (.not. plot_split) .and. itproc ) then
         outname = instrument + "_" + date(itime)
         wks = gsn_open_wks(out_type,plotdir+outname)
         gsn_define_colormap(wks,colormap)
         setvalues wks
           "wkForegroundColor" : (/0.,0.,0./)
           "wkBackgroundColor" : (/1.,1.,1./)
         end setvalues
         nc1 = NhlNewColor(wks,.8,.8,.8)        ; Add light gray to colormap,
                                                ; for continents.
         navyblue = NhlNewColor(wks,0,0,.5)                   ; Add navyblue to colormap
      end if
      if ( itproc .and. (.not. doneit) ) then
         ;
         ; declare the arrays for OMB and OMA number, mean and rms
         ;
         xnum  = new((/3,nchan,ntime/),integer)    ; for omb_nb, omb_wb, and oma
         xnum!1 = "channel"                        ; name the dimension
         xnum!2 = "date"
         xnum&channel = (/ plot_ch /)              ; define coordinate variable
         xnum&date = (/ stringtointeger(date) /)
         xmean = new((/3,nchan,ntime/),float)
         xmean!1 = "channel"
         xmean!2 = "date"
         xmean&channel = (/ plot_ch /)
         xmean&date = (/ stringtointeger(date) /)
         xrms = xmean
         xstd = xmean
         ;
         ; declare the arrays for number of points before qc/selection and after qc/selection
         ;
         npts = new((/nchan,ntime/),integer)
         npts!0 = "channel"                        ; name the dimension
         npts!1 = "date"
         npts&channel = (/ plot_ch /)              ; define coordinate variable
         npts&date = (/ stringtointeger(date) /)
         npts_sele = npts
         npts_qc = npts
         if ( gsi_diag ) then
            npts_qc_anl = npts
         end if
         npts_land = npts
         npts_sea  = npts

         doneit = True
      end if

      if ( itproc ) then    ; this is itproc_if

         maxval = new(nchan,float)
         minval = new(nchan,float)

         if ( inst .eq. "amsua" ) then
            si = obs(pixel|:,{chan|1}) - obs(pixel|:,{chan|15})
         end if
         if ( inst .eq. "amsub" .or. inst .eq. "mhs" ) then
            si = obs(pixel|:,{chan|1}) - obs(pixel|:,{chan|2})
         end if

         do ich = 0, nchan-1    ; loop for channels, this is nchan_loop1

            stats_info = new(np+1, string)
            stats_info = " "

            maxval(ich) = max((/max(obs(pixel|:, {chan|plot_ch(ich)})), max(bak(pixel|:, {chan|plot_ch(ich)}))/))
            minval(ich) = min((/min(obs(pixel|:, {chan|plot_ch(ich)})), min(bak(pixel|:, {chan|plot_ch(ich)}))/))

            do ip = 1, np   ; loop for plotting ems, obs, bak, omb_nobc, omb_bc, oma, this is ip_loop

               if ( ip .eq. 1 ) then
                  if ( .not. plot_emiss ) then
                     continue
                  end if
                  subname = "ems"
                  data = ems(pixel|:, {chan|plot_ch(ich)})
               end if
               if ( ip .eq. 2 ) then
                  subname = "obs"
                  data = obs(pixel|:, {chan|plot_ch(ich)})
               end if
               if ( ip .eq. 3 ) then
                  subname = "bak"
                  data = bak(pixel|:, {chan|plot_ch(ich)})
               end if
               if ( ip .eq. 4 ) then
                  subname = "omb_nobc"
                  data = omb_nobc(pixel|:, {chan|plot_ch(ich)})
               end if
               if ( ip .eq. 5 ) then
                  subname = "omb_bc"
                  data = omb_bc(pixel|:, {chan|plot_ch(ich)})
               end if
               if ( ip .eq. 6 ) then
                  subname = "oma"
                  data = oma(pixel|:, {chan|plot_ch(ich)})
               end if

               if ( subdomain ) then
                  data = mask(data,lon(:).ge.minlon.and.lon(:).le.maxlon.and.lat(:).ge.minlat.and.lat(:).le.maxlat,True)
               end if

               info = instrument+"_ch"+sprinti("%0.4i",plot_ch(ich))
               if ( plot_cover .and. .not. plot_stats_only ) then
                  print("Plotting "+subname+" data distribution of "+info)
               end if
        
               npts(ich,itime) = num(.not.ismissing(data))
               npts_land(ich,itime) = num(.not.ismissing(mask(data, isflg, 2)))
               npts_sea(ich,itime)  = num(.not.ismissing(mask(data, isflg, 0)))
               npts_qc(ich,itime)  = num(.not.ismissing(mask(data, qc(pixel|:, {chan|plot_ch(ich)}), 1)))
               if ( gsi_diag ) then
                  npts_qc_anl(ich,itime)  = num(.not.ismissing(mask(data, qc_anl(pixel|:, {chan|plot_ch(ich)}), 1)))
               end if

               ;  Mask out data according to the isflg type:
               if ( plot_opt .eq. "land_only" ) then
                  data = mask(data, isflg, 2)
               end if
               if ( plot_opt .eq. "sea_only" ) then
                  data = mask(data, isflg, 0)
               end if
               if ( plot_cloudy ) then
                  if ( plot_cloudy_opt .eq. "clwp" ) then
                     if ( clwp_value .eq. 0. ) then
                        data = mask(data, clwp.gt.clwp_value, True)
                     else
                       data = mask(data, clwp.ge.clwp_value, True)
                     end if
                  end if
                  if ( plot_cloudy_opt .eq. "si" ) then
                     data = mask(data, si.ge.si_value, True)
                  end if
                  if ( plot_cloudy_opt .eq. "si_clwp" ) then
                     if ( clwp_value .eq. 0. ) then
                        data = mask(data, si.ge.si_value.and.clwp.gt.clwp_value, True)
                     else
                        data = mask(data, si.ge.si_value.and.clwp.ge.clwp_value, True)
                     end if
                  end if
               end if

               if ( plot_qced ) then
                  if ( gsi_diag .and. ip .eq. 6 ) then
                     data = mask(data, qc_anl(pixel|:, {chan|plot_ch(ich)}), 1)
                  else
                     data = mask(data, qc(pixel|:, {chan|plot_ch(ich)}), 1)
                  end if
               end if

               npts_sele(ich,itime) = num(.not.ismissing(data))

               if ( npts_sele(ich,itime) .gt. 0 ) then

               if ( plot_cover .and. plot_split ) then
                  outname = info + "_" + date(itime) + "_" + subname
                  wks = gsn_open_wks(out_type,plotdir+outname)
                  gsn_define_colormap(wks,colormap)                 ; define colormap
                  setvalues wks
                     "wkForegroundColor" : (/0.,0.,0./)
                     "wkBackgroundColor" : (/1.,1.,1./)
                  end setvalues
                  nc1 = NhlNewColor(wks,.8,.8,.8)        ; Add light gray to colormap,
                                                         ; for continents.
                  navyblue = NhlNewColor(wks,0,0,.5)     ; Add navyblue to colormap
               end if

               if ( ip .eq. 1 ) then
                  title = info + "  Emissivity  " + npts_sele(ich,itime) + " / " + npts(ich,itime)
                  ; stats_info = " "
               end if
               if ( ip .eq. 2 ) then
                  title = info + "  OBS  " + npts_sele(ich,itime) + " / " + npts(ich,itime)
                  ; stats_info = " "
               end if
               if ( ip .eq. 3 ) then
                  title = info + "  BAK  " + npts_sele(ich,itime) + " / " + npts(ich,itime)
                  ; stats_info = " "
               end if
               if ( ip .eq. 4 ) then
                  title = info + "  OMB  no  BC " + npts_sele(ich,itime) + " / " + npts(ich,itime)
                  if ( npts_sele(ich,itime) .gt. 0 ) then
                     xnum(0,ich,itime) = (/ npts_sele(ich,itime) /)
                     xmean(0,ich,itime) = sum(data)/tofloat(npts_sele(ich,itime))
                     xrms(0,ich,itime) = sqrt(sum(data*data)/tofloat(npts_sele(ich,itime)))
                     xstd(0,ich,itime) = sqrt(sum((data-xmean(0,ich,itime))*(data-xmean(0,ich,itime)))/tofloat(npts_sele(ich,itime)))
                     stats_info(ip) = "mean: "+sprintf("%8.2f",xmean(0,ich,itime))+ \
                                      "   stdv: "+sprintf("%8.2f",xstd(0,ich,itime))
                  ; else
                  ;    stats_info = " "
                  end if
               end if
               if ( ip .eq. 5 ) then
                  title = info + "  OMB with BC " + npts_sele(ich,itime) + " / " + npts(ich,itime)
                  if ( npts_sele(ich,itime) .gt. 0 ) then
                     xnum(1,ich,itime) = (/ npts_sele(ich,itime) /)
                     xmean(1,ich,itime) = sum(data)/tofloat(npts_sele(ich,itime))
                     xrms(1,ich,itime) = sqrt(sum(data*data)/tofloat(npts_sele(ich,itime)))
                     xstd(1,ich,itime) = sqrt(sum((data-xmean(1,ich,itime))*(data-xmean(1,ich,itime)))/tofloat(npts_sele(ich,itime)))
                     stats_info(ip) = "mean: "+sprintf("%8.2f",xmean(1,ich,itime))+ \
                                      "   stdv: "+sprintf("%8.2f",xstd(1,ich,itime))
                  ; else
                  ;    stats_info = " "
                  end if
               end if
               if ( ip .eq. 6 ) then
                  title = info + "  OMA with BC " + npts_sele(ich,itime) + " / " + npts(ich,itime)
                  if ( npts_sele(ich,itime) .gt. 0 ) then
                     xnum(2,ich,itime) = (/ npts_sele(ich,itime) /)
                     xmean(2,ich,itime) = sum(data)/tofloat(npts_sele(ich,itime))
                     xrms(2,ich,itime) = sqrt(sum(data*data)/tofloat(npts_sele(ich,itime)))
                     xstd(2,ich,itime) = sqrt(sum((data-xmean(2,ich,itime))*(data-xmean(2,ich,itime)))/tofloat(npts_sele(ich,itime)))
                     stats_info(ip) = "mean: "+sprintf("%8.2f",xmean(2,ich,itime))+ \
                                      "   stdv: "+sprintf("%8.2f",xstd(2,ich,itime))
                  ; else
                  ;   stats_info = " "
                  end if
               end if

if ( .not. plot_stats_only ) then

               if ( ip .eq. 2 .or. ip .eq. 3 ) then
                  plot_min_val = minval(ich)
                  plot_max_val = maxval(ich)
               else
                  plot_min_val = min(data)
                  plot_max_val = max(data)
               end if
               if ( ip .eq. 1 ) then
                  plot_min_val = 0.0
                  plot_max_val = 1.0
               end if
  
               data_range = plot_max_val - plot_min_val

               bin_width_data = data_range / tofloat(num_bins)
               arr = new(num_bins+1,float) 
               do i = 0, num_bins
                  arr(i) = plot_min_val + i * bin_width_data 
               end do

               labels = new(dimsizes(arr),string)  ; Labels for legend.

               ; Create X and Y arrays to hold the points for each range and initialize
               ; them to missing values.  We want to use num_bins different colors, 
               ; so we need num_bins sets of X and Y points.

               lat_new = new((/num_bins,dimsizes(data)/),float,-999)
               lon_new = new((/num_bins,dimsizes(data)/),float,-999)

               ; Group the points according to which range they fall in. At the
               ; same time, create the label that we will use later in the legend.
        
               do i = 0, num_bins-1
                  if ( i .eq. num_bins-1 ) then
                     indexes = ind(data.ge.arr(i).and.data.le.(arr(i+1)+0.5*bin_width_data))
                  else
                     indexes = ind(data.ge.arr(i).and.data.lt.arr(i+1))
                  end if
                  labels(i) = arr(i) + " <= x < " + arr(i+1)
 
                  ; Now that we have the set of indexes whose values fall within 
                  ; the given range, take the corresponding lat/lon values and store
                  ; them, so later we can color this set of markers with the appropriate
                  ; color.
 
                  if (.not.any(ismissing(indexes))) then 
                     npts_range = dimsizes(indexes)   ; # of points in this range.
                     lat_new(i,0:npts_range-1) = lat(indexes)
                     lon_new(i,0:npts_range-1) = lon(indexes)
                  end if
                  delete(indexes)            ; Necessary b/c "indexes" may be a different
                                             ; size next time.
               end do
 
               font_height = 0.015
 
               ; add custom label bar
               lbres = True
               lbres@lbPerimOn            = False               ; no label bar box
               lbres@lbOrientation        = "Horizontal"        ; orientation
               lbres@vpWidthF             = 0.85                ; size
               lbres@vpHeightF            = 0.1 
               lbres@lbLabelFontHeightF   = font_height         ; label font height default 0.02
               lbres@lbLabelAlignment     = "InteriorEdges"     ; where to label
               lbres@lbLabelAutoStride    = True                ; Auto stride
               lbres@lbMonoFillPattern    = True                ; fill sold
               lbres@lbFillColors         = labelbarcolors      ; must be RGB triplets
               lbres@lbBoxLinesOn         = False

             if ( plot_cover ) then
               xndc = 0.08
               yndc = 0.18
               if ( max(arr) .le. 10. ) then
                  gsn_labelbar_ndc (wks,num_bins,sprintf("%5.2f",arr),xndc,yndc,lbres)
               else
                  if ( max(arr) .le. 100. ) then
                     gsn_labelbar_ndc (wks,num_bins,sprintf("%4.1f",arr),xndc,yndc,lbres)
                  else
                     gsn_labelbar_ndc (wks,num_bins,""+tointeger(arr),xndc,yndc,lbres)
                  end if
               end if
             end if
 
               ; Set up some map resources.
               mpres                         = True
               mpres@gsnMaximize             = False             ; Maximize plot in frame.
               mpres@gsnFrame                = False            ; Don't advance the frame

               ; if ( mpres@gsnMaximize ) then
                  ; mpres@vpHeightF               = 0.5
                  ; mpres@vpYF                    = 0.9
               ; end if

               if ( subdomain ) then
                  mpres@mpProjection         = "CylindricalEquidistant"
                  mpres@mpLimitMode          = "LatLon"
                  mpres@mpMinLatF            = minlat
                  mpres@mpMaxLatF            = maxlat
                  mpres@mpMinLonF            = minlon
                  mpres@mpMaxLonF            = maxlon
               else
                  ;mpres@mpProjection            = mapproj          ; choose projection
                  mpres@mpProjection         = "CylindricalEquidistant"
                  if ( mapproj .eq. "LambertConformal" ) then
                     mpres@mpLambertParallel1F     = truelat1      ; two parallels
                     mpres@mpLambertParallel2F     = truelat2
                     mpres@mpLambertMeridianF      = clon          ; central meridian
                  end if
                  if ( mapproj .eq. "Stereographic" ) then
                     mpres@mpCenterLatF         = clat
                     mpres@mpCenterLonF         = clon
                  end if
                  mpres@mpLimitMode             = "Corners"
                  mpres@mpLeftCornerLatF        = lat_ll
                  mpres@mpLeftCornerLonF        = lon_ll
                  mpres@mpRightCornerLatF       = lat_ur
                  mpres@mpRightCornerLonF       = lon_ur
               end if

               mpres@pmTickMarkDisplayMode   = "Always"
               ; mpres@tmYROn                  = False
               ; mpres@tmXBOn                  = False
               mpres@tmXTMajorLengthF        = 0
               mpres@tmYLMajorLengthF        = 0
               mpres@tmXBMajorLengthF        = 0
               mpres@tmYRMajorLengthF        = 0
               mpres@mpOutlineBoundarySets   = "GeophysicalAndUSStates" ; state boundaries
               mpres@tfDoNDCOverlay          = True

               mpres@mpGeophysicalLineColor  = "Navy"
               mpres@mpGridAndLimbOn         = True
               mpres@mpGridLineDashPattern   = 2
               mpres@mpGridLineDashSegLenF   = 0.06               ; default 0.15

               mpres@mpFillOn               = False
               mpres@mpFillColors = (/-1,-1,nc1,-1/)  ; (no data, ocean, land, inlandwater, )
               mpres@mpDataBaseVersion       = "MediumRes"

   mpres@mpUSStateLineColor      = "black"
   mpres@mpNationalLineColor     = "black"
   mpres@mpGeophysicalLineColor  = "black"
   mpres@mpGridAndLimbOn         = True
   mpres@mpGridSpacingF          = 10.0
   mpres@mpGridLineColor         = "white"
   mpres@mpGeophysicalLineThicknessF = 2.0
   mpres@mpNationalLineThicknessF = 3.0
   mpres@mpUSStateLineThicknessF = 1.0

               ; gsn resources:
               mpres@gsnStringFontHeightF    = font_height
               mpres@gsnLeftString           = stats_info(ip)     ; add left string
               mpres@gsnRightString          = date(itime)        ; add right string

               ; Title resources:
               mpres@tiMainString            = title
               mpres@tiMainOffsetYF          = 0.0           ; Move the title down.
               mpres@tiMainFontHeightF       = font_height

            if ( plot_cover ) then
               map = gsn_csm_map(wks,mpres)
 
               ; Loop through each grouping of markers, and draw them one set at
               ; a time, assigning the proper color and size with gsn_marker.
 
               gsres               = True
               gsres@gsMarkerIndex = 16                    ; Use filled dots for markers.
               do i = 0, num_bins-1
                  if (.not.ismissing(lat_new(i,0)))
                     gsres@gsMarkerColor  = colors(i)
                     gsres@gsMarkerSizeF  = 0.003          ; default 0.007
                     gsn_polymarker(wks,map,lon_new(i,:),lat_new(i,:),gsres)
                  end if
               end do

               frame(wks)    ; Advance the frame.

               if ( plot_split ) then
                  destroy(wks)
               end if
            end if
               delete(lat_new)
               delete(lon_new)
               end if

end if

            end do  ; end loop for plotting obs, bak, omb_nobc, omb_bc, oma, end do ip_loop

            if ( (.not. plot_stats_only) .and. npts(ich,itime) .gt. 1 .and. npts_sele(ich,itime) .gt. 1 ) then
             if ( plot_scatt ) then
               ;
               ; scatter plot (BAK vs OBS)
               ;
               print("Plotting scatter plot of "+info)
               if ( plot_split ) then
                  outname = info + "_" + date(itime) + "_sca"
                  wks = gsn_open_wks(out_type,plotdir+outname)
                  setvalues wks
                     "wkForegroundColor" : (/0.,0.,0./)
                     "wkBackgroundColor" : (/1.,1.,1./)
                  end setvalues
               end if
               do is = 1, ns
                  if ( is .eq. 1 ) then
                     xlabel = "OBS Tb (no BC)"
                     ylabel = "BAK Tb"
                     data1 = obs(pixel|:, {chan|plot_ch(ich)})
                     data2 = bak(pixel|:, {chan|plot_ch(ich)})
                     ip = 4
                  end if
                  if ( is .eq. 2 ) then
                     xlabel = "OBS Tb (with BC)"
                     ylabel = "BAK Tb"
                     data1 = obs_bc(pixel|:, {chan|plot_ch(ich)})
                     data2 = bak(pixel|:, {chan|plot_ch(ich)})
                     ip = 5
                  end if
                  if ( is .eq. 3 ) then
                     xlabel = "OBS Tb (with BC)"
                     ylabel = "ANA Tb"
                     data1 = obs_bc(pixel|:, {chan|plot_ch(ich)})
                     data2 = ana(pixel|:, {chan|plot_ch(ich)})
                     ip = 6
                  end if

                  if ( subdomain ) then
                     data1 = mask(data1,lon(:).ge.minlon.and.lon(:).le.maxlon.and.lat(:).ge.minlat.and.lat(:).le.maxlat,True)
                     data2 = mask(data2,lon(:).ge.minlon.and.lon(:).le.maxlon.and.lat(:).ge.minlat.and.lat(:).le.maxlat,True)
                  end if

                  ;  Mask out data according to the isflg type:
                  if ( plot_opt .eq. "land_only" ) then
                     data1 = mask(data1, isflg, 2)
                     data2 = mask(data2, isflg, 2)
                  end if
                  if ( plot_opt .eq. "sea_only" ) then
                     data1 = mask(data1, isflg, 0)
                     data2 = mask(data2, isflg, 0)
                  end if
                  if ( plot_cloudy ) then
                     if ( plot_cloudy_opt .eq. "clwp" ) then
                        if ( clwp_value .eq. 0. ) then
                           data1 = mask(data1, clwp.gt.clwp_value, True)
                           data2 = mask(data2, clwp.gt.clwp_value, True)
                        else
                           data1 = mask(data1, clwp.ge.clwp_value, True)
                           data2 = mask(data2, clwp.ge.clwp_value, True)
                        end if
                     end if
                     if ( plot_cloudy_opt .eq. "si" ) then
                        data1 = mask(data1, si.ge.si_value, True)
                        data2 = mask(data2, si.ge.si_value, True)
                     end if
                     if ( plot_cloudy_opt .eq. "si_clwp" ) then
                        if ( clwp_value .eq. 0. ) then
                           data1 = mask(data1, si.ge.si_value.and.clwp.gt.clwp_value, True)
                           data2 = mask(data2, si.ge.si_value.and.clwp.gt.clwp_value, True)
                        else
                           data1 = mask(data1, si.ge.si_value.and.clwp.ge.clwp_value, True)
                           data2 = mask(data2, si.ge.si_value.and.clwp.ge.clwp_value, True)
                        end if
                     end if
                  end if

                  if ( plot_qced ) then
                     if ( gsi_diag .and. is .eq. 3 ) then
                        data1 = mask(data1, qc_anl(pixel|:, {chan|plot_ch(ich)}), 1)
                        data2 = mask(data2, qc_anl(pixel|:, {chan|plot_ch(ich)}), 1)
                     else
                        data1 = mask(data1, qc(pixel|:, {chan|plot_ch(ich)}), 1)
                        data2 = mask(data2, qc(pixel|:, {chan|plot_ch(ich)}), 1)
                     end if
                  end if

                if ( num(.not.ismissing(data1)) .gt. 1 ) then
                  title = info + "    " + num(.not.ismissing(data1))

                  minXY   = min( (/ min(data1), min(data2) /) )
                  maxXY   = max( (/ max(data1), max(data2) /) )
                  xy = (/ minXY, maxXY /)

                  res_scat                     = True
                  res_scat@gsnMaximize         = False
                  res_scat@gsnLeftString       = stats_info(ip)     ; add left string
                  res_scat@gsnRightString      = date(itime)
                  res_scat@tmYROn              = False 
                  res_scat@tmXTOn              = False
                  res_scat@tmYRBorderOn        = False
                  res_scat@tmXTBorderOn        = False
                  res_scat@tmYLMinorOn         = False
                  res_scat@tmXBMinorOn         = False
                  res_scat@gsnDraw             = False                 ; don't draw yet
                  res_scat@gsnFrame            = False                 ; don't advance frame yet
                  res_scat@tiMainString        = title
                  res_scat@tiXAxisString       = xlabel                ; xaxis string
                  res_scat@tiYAxisString       = ylabel                ; yaxis string
                  res_scat@tmLabelAutoStride   = True                  ; nice tick mark labels
                  res_scat@tmYLMajorThicknessF = 1.0                   ; default 2.0
                  res_scat@tmXBMajorThicknessF = 1.0                   ; default 2.0
                  res_scat@xyLineColor         = "red"                 ; line color
                  res_scat@xyDashPattern       = 0                     ; default 0 solid line
                  res_scat@xyLineThicknessF    = 1.0                   ; line thicker

                  plot  = gsn_csm_xy (wks,xy,xy,res_scat)              ; plot the line

                  res_mark                     = True
                  res_mark@gsMarkerIndex       = 0                     ; choose type of marker  
                  res_mark@gsMarkerColor       = "blue"                ; Marker color
                  ; res_mark@gsMarkerColor       = 3                     ; Marker color
                  res_mark@gsMarkerSizeF       = 0.003                 ; Marker size (default 0.01)

                  gsn_polymarker(wks,plot,data1,data2,res_mark)        ; add the markers

                  draw(plot)
                  frame(wks)
                end if
                  delete(data1)
                  delete(data2)
               end do
               if ( plot_split ) then
                  destroy(wks)
               end if
               delete(plot)
             end if  ; end of if plot_scatt
             if ( plot_histo ) then
               ;
               ; histogram
               ;
               print("Plotting histogram of "+info)
               if ( plot_split ) then
                  outname = info + "_" + date(itime) + "_his"
                  wks = gsn_open_wks(out_type,plotdir+outname)
                  setvalues wks
                     "wkForegroundColor" : (/0.,0.,0./)
                     "wkBackgroundColor" : (/1.,1.,1./)
                  end setvalues
               end if

               do ih = 1, nh
                  if ( ih .eq. 1 ) then
                     xlabel = "OMB Bins (K)"
                     title = info + " no BC  " + npts_sele(ich,itime) + "   " + date(itime)
                     data3 = omb_nobc(pixel|:, {chan|plot_ch(ich)})
                  end if
                  if ( ih .eq. 2 ) then
                     xlabel = "OMB Bins (K)"
                     title = info + " with BC  " + npts_sele(ich,itime) + "   " + date(itime)
                     data3 = omb_bc(pixel|:, {chan|plot_ch(ich)})
                  end if
                  if ( ih .eq. 3 ) then
                     xlabel = "OMA Bins (K)"
                     title = info + " with BC  " + npts_sele(ich,itime) + "   " + date(itime)
                     data3 = oma(pixel|:, {chan|plot_ch(ich)})
                  end if

                  if ( subdomain ) then
                     data3 = mask(data3,lon(:).ge.minlon.and.lon(:).le.maxlon.and.lat(:).ge.minlat.and.lat(:).le.maxlat,True)
                  end if

                  ;  Mask out data according to the isflg type:
                  if ( plot_opt .eq. "land_only" ) then
                     data3 = mask(data3, isflg, 2)
                  end if
                  if ( plot_opt .eq. "sea_only" ) then
                     data3 = mask(data3, isflg, 0)
                  end if
                  if ( plot_cloudy ) then
                     if ( plot_cloudy_opt .eq. "clwp" ) then
                        if ( clwp_value .eq. 0. ) then
                           data3 = mask(data3, clwp.gt.clwp_value, True)
                        else
                           data3 = mask(data3, clwp.ge.clwp_value, True)
                        end if
                     end if
                     if ( plot_cloudy_opt .eq. "si" ) then
                        data3 = mask(data3, si.ge.si_value, True)
                     end if
                     if ( plot_cloudy_opt .eq. "si_clwp" ) then
                        if ( clwp_value .eq. 0. ) then
                           data3 = mask(data3, si.ge.si_value.and.clwp.gt.clwp_value, True)
                        else
                           data3 = mask(data3, si.ge.si_value.and.clwp.ge.clwp_value, True)
                        end if
                     end if
                  end if

                  if ( plot_qced ) then
                     if ( gsi_diag .and. ih .eq. 3 ) then
                        data3 = mask(data3, qc_anl(pixel|:, {chan|plot_ch(ich)}), 1)
                     else
                        data3 = mask(data3, qc(pixel|:, {chan|plot_ch(ich)}), 1)
                     end if
                  end if

                  res_hist                                 = True
                  res_hist@gsnMaximize                     = False
                  res_hist@tmYLMinorOn                     = False
                  res_hist@tmXBMinorOn                     = False
                  res_hist@tmLabelAutoStride               = True                 ; nice tick mark labels
                  res_hist@tiMainString                    = title
                  res_hist@gsFillColor                     = "navyblue"
                  ; res_hist@gsnHistogramBinWidth            = 1
                  if ( plot_qced .or. subdomain ) then
                     res_hist@gsnHistogramNumberOfBins        = 25
                  else
                     res_hist@gsnHistogramNumberOfBins        = 100
                  end if
                  ; res_hist@gsnHistogramSelectNiceIntervals = False
                  res_hist@tiXAxisString                   = xlabel               ; xaxis string
                  res_hist@tiYAxisString                   = "Number of Bins"     ; yaxis string
                  res_hist@tmYLMajorThicknessF             = 1.0                  ; default 2.0
                  res_hist@tmXBMajorThicknessF             = 1.0                  ; default 2.0

                  if ( num(.not.ismissing(data3)) .gt. 1 ) then
                     if ( sum(data3) .ne. 0 ) then
                        plot = gsn_histogram(wks,data3,res_hist)
                     end if
                  end if

                  delete(data3)
               end do

               if ( plot_split ) then
                  destroy(wks)
               end if

               delete(plot)
             end if  ; end of if plot_histo

            end if   ; end of npts and npts_sele if check for scatter plot and histogram

            if ( plot_sflag .and. (.not. plot_stats_only) .and. ich .eq. (nchan-1) .and. npts_sele(ich,itime) .gt. 0 ) then
               ;
               ; surface type isflg plot
               ;
               if ( plot_split ) then
                  outname = instrument + "_" + date(itime) + "_sflg"
                  wks = gsn_open_wks(out_type,plotdir+outname)
               end if

               print("Plotting surface type flag of "+instrument)

               gsn_define_colormap(wks,"hlu_default")    ; use a different colormap for surface flag plot 
               setvalues wks
                  "wkForegroundColor" : (/0.,0.,0./)
                  "wkBackgroundColor" : (/1.,1.,1./)
               end setvalues
               nc1 = NhlNewColor(wks,.8,.8,.8)        ; Add light gray to colormap,
                                                      ; for continents.
               mpres@mpFillColors  = (/-1,-1,nc1,-1/)  ; (no data, ocean, land, inlandwater, )

               mpres@tiMainString  = "surface type"
               mpres@gsnLeftString = instrument               ; add left string

               map = gsn_csm_map(wks,mpres)

               colors_isflg = (/ 6, 3, 30, 5, 4, 7, 2, 12 /)
               labels_isflg = (/ "sea", "ice", "land", "snow", "msea", "mice", "mlnd", "msno" /)

               xleg = (/0.22,0.22,0.42,0.42,0.62,0.62,0.82,0.82/)   ; Location of
               xtxt = (/0.26,0.26,0.46,0.46,0.66,0.66,0.86,0.86/)   ; legend markers
               yleg = (/0.06,0.04,0.06,0.04,0.06,0.04,0.06,0.04/)   ; and text
               ytxt = (/0.06,0.04,0.06,0.04,0.06,0.04,0.06,0.04/)   ; strings.

               gsres               = True
               gsres@gsMarkerIndex = 16                    ; Use filled dots for markers.
               txres               = True
               txres@txFontHeightF = 0.015

               do i = 0, 7    ; there are 8 surface types
                  data_lon = mask(lon, isflg, i)
                  data_lat = mask(lat, isflg, i)
                  gsres@gsMarkerColor  = colors_isflg(i)
                  gsres@gsMarkerSizeF  = 0.003          ; default 0.007
                  if ( num(.not.ismissing(data_lon)) .gt. 0 ) then
                     gsn_polymarker(wks,map,data_lon,data_lat,gsres)
                  end if
                  ;
                  ; Add marker and text for the legend.
                  ;
                  gsres@gsMarkerSizeF  = 0.010          ; default 0.007
                  gsn_polymarker_ndc(wks, xleg(i),yleg(i),gsres)
                  ; txres@txFontColor = colors_isflg(i)
                  gsn_text_ndc(wks,labels_isflg(i),xtxt(i),ytxt(i),txres)
               end do

               frame(wks)    ; Advance the frame.
               delete(data_lon)
               delete(data_lat)
               if ( plot_split ) then
                  destroy(wks)
               end if

            end if   ; end of if plot surface flag 

         end do  ; end loop for channels, end do nchan_loop1

         delete(ichan)
         delete(lat)
         delete(lon)
         delete(ems)
         delete(obs)
         delete(bak)
         delete(oma)
         delete(ana)
         delete(omb_bc)
         delete(omb_nobc)
         delete(obs_bc)
         delete(qc)
         if ( gsi_diag ) then
            delete(qc_anl)
         end if
         ; delete(elev)
         delete(clwp)
         if ( inst .eq. "amsua" .or. inst .eq. "amsub" .or. inst .eq. "mhs" ) then
            delete(si)
         end if
         delete(isflg)
         delete(data)

         if ( nchan .gt. 1 .and. num(.not.ismissing(xmean)) .gt. 0) then
            ;
            ; plot OMB/OMA (number/mean/rms) vs channels
            ;
            if ( plot_stats_only .or. plot_split ) then
               outname = instrument + "_" + date(itime) + "_stats"
               wks = gsn_open_wks(out_type,plotdir+outname)
               setvalues wks
                  "wkForegroundColor" : (/0.,0.,0./)
                  "wkBackgroundColor" : (/1.,1.,1./)
               end setvalues
            end if
            plot = new(3,graphic)
            res_stats                        = True
            res_stats@gsnPaperOrientation    = "portrait"
            res_stats@gsnMaximize            = False               ; Maximize plot in frame.
            res_stats@gsnFrame               = False               ; Don't advance the frame
            res_stats@gsnDraw                = False
            res_stats@vpHeightF              = 0.25                ; change aspect ratio of plot
            res_stats@vpWidthF               = 0.90
            res_stats@tmYROn                 = False
            res_stats@tmXTOn                 = False
            res_stats@tmYLMinorOn            = False
            res_stats@tmXBMinorOn            = False
            res_stats@tmYLMajorThicknessF    = 1.0                 ; default 2.0
            res_stats@tmXBMajorThicknessF    = 1.0                 ; default 2.0
            if ( instrument .eq. "eos-2-airs" .or. instrument .eq. "airs_aqua" ) then
               res_stats@xyMarkLineMode         = "Markers"
            else
               res_stats@xyMarkLineMode         = "MarkLines"
            end if
            res_stats@xyMarkers              = (/ 1, 1, 1 /)
            ;res_stats@xyMarkerColors         = (/ "magenta", "red", "blue" /)
            res_stats@xyMarkerColors         = (/ "green", "red", "blue" /)
            res_stats@xyMarkerSizes          = (/ 0.02, 0.02, 0.02 /)   ; default 0.01
            ;res_stats@xyMarkerSizes          = (/ 0.03, 0.03, 0.03 /)   ; default 0.01
            res_stats@xyDashPatterns         = (/ 1, 0, 0 /)
            res_stats@xyLineThicknesses      = (/ 2.0, 2.0, 2.0 /)      ; default 1.0
            ;res_stats@xyLineColors           = (/ "magenta", "red", "blue" /)
            res_stats@xyLineColors           = (/ "green", "red", "blue" /)
            res_stats@gsnYRefLine            = 0.0
            if ( instrument.eq."eos-2-airs" .or. instrument.eq."airs_aqua" ) then
               res_stats@tmXBMode               = "Automatic"
            else
               res_stats@tmXBMode               = "Explicit"
               res_stats@tmXBLabels             = (/ plot_ch+"" /)
               res_stats@tmXBValues             = xnum&channel
            end if
            ;if ( dimsizes(plot_ch) .le. 255 ) then
            ;   res_stats@tmXBMode               = "Explicit"
            ;   res_stats@tmXBLabels             = (/ plot_ch+"" /)
            ;   res_stats@tmXBValues             = xnum&channel
            ;else
            ;   res_stats@tmXBMode               = "Automatic"
            ;end if
            res_stats@tmLabelAutoStride      = True                ; Auto stride
            res_stats@pmLegendDisplayMode    = "Always"            ; turn on legend
            res_stats@pmLegendSide           = "Right"             ; Change location of
            res_stats@pmLegendWidthF         = 0.1                 ; Change width and default 0.55
            res_stats@pmLegendHeightF        = 0.1                 ; height of legend. default 0.18
            res_stats@lgLabelFontHeightF     = .015                ; change font height default 0.02
            res_stats@xyExplicitLegendLabels = (/"OMB_nb", "OMB_wb", "OMA"/)    ; explicit labels

            res_stats@tiYAxisString = "Number"
            if ( instrument.eq."eos-2-airs" .or. instrument.eq."airs_aqua" ) then
               plot(0)  = gsn_csm_xy (wks,wavenumber({chan|plot_ch(:)}),xnum(:,:,itime),res_stats)
            else
               plot(0)  = gsn_csm_xy (wks,xnum&channel,xnum(:,:,itime),res_stats)
            end if
            res_stats@tiYAxisString = "Mean (K)"
            if ( instrument.eq."eos-2-airs" .or. instrument.eq."airs_aqua" ) then
               plot(1)  = gsn_csm_xy (wks,wavenumber({chan|plot_ch(:)}),xmean(:,:,itime),res_stats)
            else
               plot(1)  = gsn_csm_xy (wks,xmean&channel,xmean(:,:,itime),res_stats)
            end if
            res_stats@tiYAxisString = "Stdv (K)"
            if ( instrument.eq."eos-2-airs" .or. instrument.eq."airs_aqua" ) then
               res_stats@tiXAxisString = "Wavenumber (cm~S~-1~N~)"
               plot(2)  = gsn_csm_xy (wks,wavenumber({chan|plot_ch(:)}),xstd(:,:,itime),res_stats)
            else
               res_stats@tiXAxisString = "Channel Number"
               plot(2)  = gsn_csm_xy (wks,xstd&channel,xstd(:,:,itime),res_stats)
            end if
            pres                = True              ; mod panel plot
            pres@gsnPanelBottom = 0.03              ; add some space at bottom 
            pres@txString = expt + "  " + instrument + "   OMB/OMA   " + date(itime)
            gsn_panel(wks,plot,(/3,1/),pres)

            delete(res_stats)
            delete(plot)
            if ( plot_stats_only .or. plot_split ) then
               destroy(wks)
            end if

         end if

         delete(maxval)
         delete(minval)

      end if   ; end of itproc_if block

      if ( (.not. plot_stats_only) .and. (.not. plot_split) .and. itproc ) then
         destroy(wks)
      end if

   end do  ; end loop for ntime, end do ntime_loop

   if ( ntime .gt. 1 .and. num(.not.ismissing(xmean)) .gt. 0 ) then
      ;
      ; OMB/OMA (number/mean/rms) vs time
      ;
      outname = instrument + "_ts_" + start_date + "_" + end_date
      wks = gsn_open_wks(out_type,plotdir+outname)
      setvalues wks
         "wkForegroundColor" : (/0.,0.,0./)
         "wkBackgroundColor" : (/1.,1.,1./)
      end setvalues

      do ich = 0, nchan-1  ; this is nchan_loop2

         if ( num(.not.ismissing(xmean(0,ich,:))) .gt. 0 ) then

            if ( write_txt ) then
               asciiwrite ("./"+instrument+"_omb_nb_"+sprinti("%0.4i",ich+1)+".txt" , date(:)+"  "+sprinti("%8.0i",xnum(0,ich,:))+"  "+sprintf("%8.3f", xmean(0,ich,:))+"  "+sprintf("%8.3f",xstd(0,ich,:))+"  "+sprintf("%8.3f",xrms(0,ich,:)))
               asciiwrite ("./"+instrument+"_omb_wb_"+sprinti("%0.4i",ich+1)+".txt" , date(:)+"  "+sprinti("%8.0i",xnum(1,ich,:))+"  "+sprintf("%8.3f", xmean(1,ich,:))+"  "+sprintf("%8.3f",xstd(1,ich,:))+"  "+sprintf("%8.3f",xrms(1,ich,:)))
               asciiwrite ("./"+instrument+"_oma_"+sprinti("%0.4i",ich+1)+".txt" , date(:)+"  "+sprinti("%8.0i",xnum(2,ich,:))+"  "+sprintf("%8.3f", xmean(2,ich,:))+"  "+sprintf("%8.3f",xstd(2,ich,:))+"  "+sprintf("%8.3f",xrms(2,ich,:)))
            end if

            plot = new(3,graphic)
            res_stats                        = True
            res_stats@gsnPaperOrientation    = "portrait"
            res_stats@gsnMaximize            = False               ; Maximize plot in frame.
            res_stats@gsnFrame               = False               ; Don't advance the frame
            res_stats@gsnDraw                = False
            res_stats@vpHeightF              = 0.25                ; change aspect ratio of plot
            res_stats@vpWidthF               = 0.90
            res_stats@tmYROn                 = False
            res_stats@tmXTOn                 = False
            res_stats@tmYLMinorOn            = False
            res_stats@tmXBMinorOn            = False
            res_stats@tmYLMajorThicknessF    = 1.0                 ; default 2.0
            res_stats@tmXBMajorThicknessF    = 1.0                 ; default 2.0
            ;res_stats@tmXBMajorLengthF       = 0.005
            res_stats@xyMarkLineMode         = "MarkLines"
            res_stats@xyMarkers              = (/ 1, 1, 1 /)
            ;res_stats@xyMarkerColors         = (/ "magenta", "red", "blue" /)
            res_stats@xyMarkerColors         = (/ "green", "red", "blue" /)
            ;res_stats@xyMarkerSizes          = (/ 0.02, 0.02, 0.02 /)   ; default 0.01
            res_stats@xyMarkerSizes          = (/ 0.03, 0.03, 0.03 /)   ; default 0.01
            res_stats@xyDashPatterns         = (/ 1, 0, 0 /)
            res_stats@xyLineThicknesses      = (/ 2.0, 2.0, 2.0 /)      ; default 1.0
            ;res_stats@xyLineColors           = (/ "magenta", "red", "blue" /)
            res_stats@xyLineColors           = (/ "green", "red", "blue" /)
            res_stats@gsnYRefLine            = 0.0
            res_stats@tmXBMode               = "Explicit"
            res_stats@tmXBLabels             = xlabels ;mmddhh
            res_stats@tmXBValues             = xvalues ;xc
            res_stats@tmLabelAutoStride      = True                ; Auto stride
            ;res_stats@tmXBLabelAngleF        = 15.
            res_stats@pmLegendDisplayMode    = "Always"            ; turn on legend
            res_stats@pmLegendSide           = "Right"             ; Change location of
            res_stats@pmLegendWidthF         = 0.1                 ; Change width and default 0.55
            res_stats@pmLegendHeightF        = 0.1                 ; height of legend. default 0.18
            res_stats@lgLabelFontHeightF     = .015                ; change font height default 0.02
            res_stats@xyExplicitLegendLabels = (/"OMB_nb", "OMB_wb","OMA"/)    ; explicit labels

            res_stats@tiYAxisString = "Number"
            plot(0)  = gsn_csm_xy (wks,xc,xnum(:,ich,:),res_stats)
            res_stats@tiYAxisString = "Mean (K)"
            plot(1)  = gsn_csm_xy (wks,xc,xmean(:,ich,:),res_stats)
            res_stats@tiYAxisString = "Stdv (K)"
            ;res_stats@tiXAxisString = "DATE"
            res_stats@tiXAxisString = date(0)+" - "+date(ntime-1)+"  every "+cycle_period+" h"
            plot(2)  = gsn_csm_xy (wks,xc,xstd(:,ich,:),res_stats)
            pres                = True              ; mod panel plot
            pres@gsnPanelBottom = 0.03              ; add some space at bottom 
            if ( got_wn ) then
               pres@txString = expt+"  "+instrument+"_ch"+sprinti("%0.4i",plot_ch(ich))+"_wn"+sprintf("%6.1f",wavenumber({chan|plot_ch(ich)}))
            else
               pres@txString = expt+"  "+instrument+"_ch"+sprinti("%0.4i",plot_ch(ich))
            end if
            gsn_panel(wks,plot,(/3,1/),pres)

            delete(plot)
            delete(pres)
            delete(res_stats)

         end if    ; end of if xmean(ich,:) check

      end do    ; end do nchan_loop2
      destroy(wks)

   end if   ; end of if ntime and xmean check
   ;
   ; numbers
   ;
   if ( ntime .gt. 1 .and. num(.not.ismissing(npts)) .gt. 0 ) then

      data = new((/4,nchan,ntime/),integer)
      data(0,:,:) = npts
      data(1,:,:) = npts_land
      data(2,:,:) = npts_sea
      data(3,:,:) = npts_qc
      ;
      ; numbers vs time
      ;
      outname = instrument + "_num_" + start_date + "_" + end_date
      wks = gsn_open_wks(out_type,plotdir+outname)
      setvalues wks
         "wkForegroundColor" : (/0.,0.,0./)
         "wkBackgroundColor" : (/1.,1.,1./)
      end setvalues

      do ich = 0, nchan-1, 3  ; this is nchan_loop3

         if ( num(.not.ismissing(npts(ich,:))) .gt. 0 ) then

            plot = new(3,graphic)
            res_stats                        = True
            res_stats@gsnPaperOrientation    = "portrait"
            res_stats@gsnMaximize            = True                ; Maximize plot in frame.
            res_stats@gsnFrame               = False               ; Don't advance the frame
            res_stats@gsnDraw                = False
            res_stats@vpHeightF              = 0.25                ; change aspect ratio of plot
            res_stats@vpWidthF               = 0.90
            res_stats@tmYROn                 = False
            res_stats@tmXTOn                 = False
            res_stats@tmYLMinorOn            = False
            res_stats@tmXBMinorOn            = False
            res_stats@tmYLMajorThicknessF    = 1.0                 ; default 2.0
            res_stats@tmXBMajorThicknessF    = 1.0                 ; default 2.0
            res_stats@xyMarkLineMode         = "MarkLines"
;            res_stats@xyMarkers              = (/ 4, 5, 6, 7 /)
            res_stats@xyMarkerColors         = (/ "black", "green", "blue", "red" /)
            res_stats@xyMarkerSizes          = (/ 0.015, 0.015, 0.015, 0.015 /)              ; default 0.01
;            res_stats@xyLineThicknesses      = (/ l.0, 1.0, 1.0, 1.0 /)                 ; default 1.0
            res_stats@xyLineColors           = (/ "black", "green", "blue", "red" /)     ; change line color
            res_stats@tmXBMode               = "Explicit"
            res_stats@tmXBLabels             = xlabels ;mmddhh
            res_stats@tmXBValues             = xvalues ;xc
            res_stats@tmLabelAutoStride      = True                ; Auto stride
            ; res_stats@tmXBLabelAngleF        = 15.
            res_stats@pmLegendDisplayMode    = "Always"            ; turn on legend
            res_stats@pmLegendSide           = "Right"             ; Change location of
            res_stats@pmLegendWidthF         = 0.15                ; Change width and default 0.55
            res_stats@pmLegendHeightF        = 0.1                 ; height of legend. default 0.18
            res_stats@lgLabelFontHeightF     = .015                ; change font height default 0.02
            res_stats@xyExplicitLegendLabels = (/"before QC","land","sea","after QC"/)     ; explicit labels

            res_stats@tiYAxisString = "Number"
            res_stats@tiMainFontHeightF = 0.025
            res_stats@tiMainString = instrument+"_ch"+sprinti("%0.4i",plot_ch(ich))+"   "+date(0)+" -- "+date(ntime-1)
            plot(0) = gsn_csm_xy (wks,xc,data(:,ich,:),res_stats)
            if ( ich+1 .le. nchan-1 ) then
               res_stats@tiMainString = instrument+"_ch"+sprinti("%0.4i",plot_ch(ich+1))+"   "+date(0)+" -- "+date(ntime-1)
               plot(1) = gsn_csm_xy (wks,xc,data(:,ich+1,:),res_stats)
            end if
            if ( ich+2 .le. nchan-1 ) then
               res_stats@tiMainString = instrument+"_ch"+sprinti("%0.4i",plot_ch(ich+2))+"   "+date(0)+" -- "+date(ntime-1)
               plot(2) = gsn_csm_xy (wks,xc,data(:,ich+2,:),res_stats)
            end if
;            if ( ich+3 .le. nchan-1 ) then
;               res_stats@tiMainString = instrument+"_ch"+sprinti("%0.4i",plot_ch(ich+3))+"   "+date(0)+" -- "+date(ntime-1)
;               plot(3) = gsn_csm_xy (wks,xc,data(:,ich+3,:),res_stats)
;            end if
            pres                = True              ; mod panel plot
;            pres@gsnPanelBottom = 0.03              ; add some space at bottom 
            pres@txString = " "
            gsn_panel(wks,plot,(/3,1/),pres)

            delete(plot)

         end if    ; end of if xmean(ich,:) check

      end do    ; end do nchan_loop3

   end if   ; end of if ntime and npts check

end 
