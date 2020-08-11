;From the NCO manual (3.23)
;Another task that arises in regridding is characterizing new grids. In such cases
;it can be helpful to have a skeleton version of a dataset on the grid, so that 
;grid center and interfaces locations can be assessed, continental outlines can be
;examined, or the skeleton can be manually populated with data rather than relying
;on a model. SCRIP files can be difficult to visualize and manipulate, so NCO will 
;provide, if requested, a so-called skeleton file on the user-specified grid. As of
;NCO version 4.5.3, released in October, 2015, the argr skl=fl_skla switch outputs 
;the skeleton file to fl_skl. The skeleton file may then be examined in a dataset 
;viewer, populated with data, and generally serve as a template for what to expect 
;from datasets of the same geometry.

;# Generate T42 Gaussian grid file t42_SCRIP.nc and skeleton file t42_skl.nc
;ncks --rgr skl=${DATA}/grids/t42_skl.nc --rgr scrip=${DATA}/grids/t42_SCRIP.nc \
;     --rgr latlon=64,128#lat_typ=gss#lon_typ=Grn_ctr \
;     ~zender/nco/data/in.nc ~/foo.nc
;When generating skeleton files, both the grid file (t42_SCRIP.nc) and the skeleton 
;file (t42_skl.nc) are written, the input file (in.nc) is ignored, and the output
;file (foo.nc) is overwritten (its contents are immaterial).

begin
 print("NOTE: ncl version >= 4.9.1 is required")
 ; Gaussian grids to use and the name of the land mask in the file
 name = "FORCING_SRC_LOW"
 dname = str_upper(name)
 maskname = "slmsksfc"
 gridsrc = "GRIDSRC"
 ; gridsrc = "/scratch1/NCEPDEV/nems/emc.nemspara/RT/DATM-MOM6-CICE5/update-20200127/DATM/"
 ; the file containing the grid center grid lat,lons
 gridfile = gridsrc+"GRIDFILE"
 ; gridfile = gridsrc+dname+"/201110/"+name+".2011100100.nc"
 ; the output directory for the generated SCRIP file
   dirout = "DIROUT"
 ;  dirout = "/scratch2/NCEPDEV/climate/Denise.Worthen/update-20200425/DATM/"
 
 ; intermediate and temporary files
    fland = dname+"_imask.nc"
     fskl = dname+".skl"
  ;Remove the files if exist
  if (isfilepresent(fland)) then
    system("rm " + fland)
  end if
  if (isfilepresent(fskl)) then
    system("rm " + fskl)
  end if
  if (isfilepresent("out.nc")) then
    system("rm out.nc")
  end if
  ;print(fland)
  ;print(fskl)
 ; output SCRIP file
  fscrip = dirout+name+".SCRIP.nc"
  ;Remove the file if it already existed.
  if (isfilepresent(fscrip)) then
    system("rm " + fscrip)
  end if

 ; first extract the land surface mask from the source file using a series of nco commands
 ; this variable is the "sea-land-ice mask (0-sea, 1-land, 2-ice)" 
   fgrid = addfile(gridfile,"r")
 nckscmd = "ncks -v "+maskname+" "+gridfile+" "+fland
 print(nckscmd)
 system(nckscmd)
 ; remove the time dimension
 nckscmd = "ncwa -O -a time "+fland+"  "+fland
 system(nckscmd)
 nckscmd = "ncks -O -x -v time "+fland+"  "+fland
 system(nckscmd)
 nckscmd = "ncap2 -O -s 'lat=double(lat);lon=double(lon)' "+fland+"  "+fland
 system(nckscmd)

 ; retrieve the land mask and turn it into a 1,0 value
    gf = addfile(fland,"r")
 lmask = gf->slmsksfc(:,:)
 grid_imask = tointeger(where(lmask .eq. 1, 1, 0))
 printVarSummary(grid_imask)

 ; determine the N:S orientation of the grid
 dims = getvardimnames(lmask)
 ;print(dims)
 if(str_lower(dims(0)) .eq. "lat" .or. dims(0) .eq. "latitude")then
  lats = gf->$dims(0)$
  ;print(lats)
  ; define a string to set the lat_drc flag
  if(lats(0) .gt. lats(1))then
   n2s = "#lat_drc=n2s "
   print("************* creating a  N:S grid with "+n2s+"*************")
  else
   n2s = " "
  end if
 end if

 ; obtain the grid size
 dims = dimsizes(lmask)
   ny = dims(0)
   nx = dims(1)
 print("grid size "+nx+" "+ny)

 delete(gf)
 delete(fgrid)
 delete(lmask)

 oned_imask = ndtooned(grid_imask)
 ;printVarSummary(oned_imask)
 ;print(oned_imask)

 ; create the SCRIP file with the magic command
  nckscmd = "ncks -O --rgr skl="+fskl+" --rgr scrip="+fscrip+" --rgr latlon="+ny+","+nx+"#lat_typ=gss"+n2s+fland+"  out2.nc"
 print(nckscmd)
 system(nckscmd)

 ; fill the grid_imask array
    gf = addfile(fscrip,"w")
 ; retrieve the current mask
 imask = gf->grid_imask
 ; replace and rewrite
 imask := oned_imask
 gf->grid_imask = (/imask/)

 ; retrieve grid values and print
 loncenter = gf->grid_center_lon
 latcenter = gf->grid_center_lat
 loncorner = gf->grid_corner_lon
 latcorner = gf->grid_corner_lat

 print(dname+" SCRIP grid lon centers  "+ min(loncenter)+" : "+max(loncenter))
 print(dname+" SCRIP grid lat centers  "+ min(latcenter)+" : "+max(latcenter))
 print(dname+" SCRIP grid lon corners  "+ min(loncorner)+" : "+max(loncorner))
 print(dname+" SCRIP grid lat corners  "+ min(latcorner)+" : "+max(latcorner))

 ; add global attributes
 nl = integertochar(10)  ; newline character
 globalAtt             = True
 globalAtt@history     = nl+\
                         "created on "+systemfunc("date")+"  "+ nl+\
                         "using source file "+gridfile
 fileattdef( gf, globalAtt )


 ; clean up
     fskl = dname+".skl"
  ;Remove the files if exist
  if (isfilepresent(fskl)) then
    system("rm " + fskl)
  end if
  if (isfilepresent("out2.nc")) then
    system("rm out2.nc")
  end if

end
