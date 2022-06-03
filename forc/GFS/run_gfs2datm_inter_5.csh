#!/bin/csh
#
set gsdate = 20220530
set gedate = 20220530

set csdate = 20220530
set cedate = 20220530 

#--- missing
#set gsdate = 20210517
#set gedate = 20210517 
#set csdate = 20210517
#set cedate = 20210517 

#-- PRATE,UFLX,VFLX are from the f006 fcst of the run before 6 hour.
#set hprate = f006

set do_get = 0
set do_con = 1
set do_put = 0

#=====================

if ($do_get == 1) then
 #csh ./get_gfs_beta4.csh $gsdate $gedate
  csh ./get_gfs_beta5_gdas.csh $gsdate $gedate
endif

if ($do_con == 1) then
  csh ./conv_gfs2datm.fort_beta5.csh $csdate $cedate
endif

if ($do_put == 1) then
  set ym = `echo $cedate | cut -c 1-6`
  echo "put to Hpss for $ym"
  csh ./put_2hpss.csh $ym 1
  csh ./put_Reanal_2hpss.csh $ym 1
endif
