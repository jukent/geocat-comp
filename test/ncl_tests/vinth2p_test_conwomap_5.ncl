;***********************
; based conwomap_5.ncl
; generates an output array and saves two plots
;
; Concepts illustrated:
;   - Drawing a simple contour plot
;   - Making an axis logarithmic in a contour plot
;   - Changing the labels and tickmarks on a contour plot
;   - Creating a main title
;   - Attaching coordinate arrays to a variable
;
;***********************
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;===========================

begin
;*************************
; get data
;*************************
 f     = addfile("atmos.nc","r")
 u     = f->U(0,:,:,:)
;*************************
; convert to pressure levels
;*************************
  hyam   = f->hyam
  hybm   = f->hybm
  ps     = f->PS
  p0     = 1000.
  pres3d      = (/1000,950,800,700,600,500,400,300,200/)
  pres3d@units= "mb"

  u_int=(/vinth2p(u,hyam,hybm,pres3d,ps(0,:,:),2,\
              p0,2,False)/)
  u_int!0    = "plev"
  u_int&plev = pres3d
  u_int!1    = "lat"
  u_int&lat  = u&lat
  u_int!2    = "lon"
  u_int&lon  = u&lon
  u_int@long_name = "Zonal Wind"

  uzon=u_int(:,:,0)
  uzon=dim_avg(u_int)

  print(uzon)

;===========================
; plot parameters
;===========================
 wks   = gsn_open_wks ("png", "conwomap" )         ; send graphics to PNG file

 res               = True            ; Plot mods desired
 res@gsnMaximize   = True            ; Maximize plot in frame
 res@cnFillOn      = True            ; Turn on contour fill
 res@tiMainString  = "Linear axis"   ; Main title

 plot = gsn_csm_contour(wks, uzon, res )

 res@tiMainString          = "Logarithmic axis"
 res@gsnYAxisIrregular2Log = True    ; Convert Y axis to logarithmic

;---Set some axis labels, otherwise all we'll get is "10^3".
 res@tmYLMode              = "Explicit"
 res@tmYLValues            = (/300,500,700,1000/)
 res@tmYLLabels            = "" + res@tmYLValues

 plot = gsn_csm_contour(wks, uzon, res )


;===========================
; write output to netcdf
;===========================

   system("/bin/rm -f vinth2p_output.nc")   ; remove any pre-existing file
   ncdf = addfile("vinth2p_output.nc" ,"c")  ; open output netCDF file

;===================================================================
; create global attributes of the file (optional)
;===================================================================
   fAtt               = True            ; assign file attributes
   fAtt@title         = "vinth2p output of atmos.nc (conwomap_5 example)"
   fAtt@source_file   =  "original-file.nc"
   fAtt@Conventions   = "None"
   fAtt@creation_date = systemfunc ("date")
   fileattdef( ncdf, fAtt )            ; copy file attributes

;===================================================================
; make time an UNLIMITED dimension; recommended  for most applications
;===================================================================
   filedimdef(ncdf,"time",-1,True)

;===================================================================
; output variables directly; NCL will call appropriate functions
; to write the meta data associated with each variable
;===================================================================

   ncdf->u_int  = u_int                          ; 3D
   ncdf->uzon   = uzon                           ; 2D

end
