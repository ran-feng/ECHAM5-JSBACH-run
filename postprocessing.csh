#!/bin/csh -fx
#PBS -l nodes=1:ppn=1
#PBS -l walltime=100:00:00
#PBS -N TrHiRoLoBr_mod
#PBS -j oe
################################################################################
# the tag of experiments
setenv EXP TrHiRoLoBr_mod
setenv RES 63
setenv LEV 31
setenv YEAR 2007
setenv YEARED 2008
set DAT = /condor/data25/rfeng/echam5j-wiso.2.3/run/T${RES}/Miocene.new/${EXP}
setenv DPATH ${DAT}/
#gunzip  ${EXP}_${YEAR}${MON}.tar.gz
#tar -xvf  ${EXP}_${YEAR}${MON}.tar
#set STAT = $status
#if ( $STAT != 0 ) then
#   echo "error occurs when untaring"
#   exit 1
#else
#   rm ${EXP}_${YEAR}${MON}.tar
#endif
##########################################
#the following settings are just for subjob
set diagwiso = /condor/data25/rfeng/script_post/
#
################################################################################
#
#set COPY = /condor/data25/rfeng/echam5j-wiso.2.3/run/T31/${EXP}/mlo/means
set COPY = ${DPATH}means
#
#############################################################
# the location of afterburner
set SERV = /condor/data18/rfeng/afterburner-4.7.0/bin/after
#
#############################################################
#the location of scripts and data to calculate the water isotope
set CWISO = ${diagwiso}calc_wiso_monmean_d.sh
set ISOTBL = ${diagwiso}CODES.WISO
set ISODAT = ${diagwiso}SMOW.FAC.T${RES}L${LEV}.nc
#end of user specification
############################################################
#
if ( ! -e $COPY ) mkdir -p $COPY
#
######################################################
#ECHAM standard postprocessing
cd $DPATH
cat >! inp_list1 << EOR1
 &select
 code=89,91,92,93,94,95,96,97,102,103,104,105,106,107,108,109,110,111,112,113,
      114,115,116,117,118,119,120,121,122,123,124,125,126,
      134,137,139,140,141,142,143,144,145,146,147,150,151,160,161,164,165,166,
      167,168,169,171,172,175,176,177,178,179,180,181,182,184,
      185,186,187,188,189,190,191,192,193,197,203,204,205,208,209,
      210,211,213,214,216,218,221,222,229,230,231,232,233,260,
 type=20,
 LEVEL=1,2,3,4,5,
 FORMAT=2,
 mean=1,
 interval=0
 &end
EOR1
#
cat >! SELECT3 << eos3
 &SELECT
 CODE=130,131,134,135,132,133,138,148,149,153,154,155,156,157,223,165,166,
 LEVEL=100000,92500,85000,77500,70000,60000,50000,40000,
 30000,25000,20000,15000,10000,7000,5000,3000,1000,
 TYPE=70,
 FORMAT=2,
 MEAN=1,
 interval=0
 &END
eos3
#
##################################################
#
while ( $YEAR <= $YEARED )
#
foreach MON ( 01 02 03 04 05 06 07 08 09 10 11 12 )
##################################################
   set ANHA = ${YEAR}${MON}.nc
   set DATF = ${DPATH}${EXP}_${YEAR}${MON}.01.nc
   set DATF_wiso = ${DPATH}${EXP}_${YEAR}${MON}.01_wiso.nc
   if ( ! -e ${DATF} ) then
        gunzip  ${EXP}_${YEAR}${MON}.tar.gz
        tar -xvf  ${EXP}_${YEAR}${MON}.tar
        set STAT = $status
        if ( $STAT != 0 ) then
           echo "error occurs when untaring"
           exit 1
        else
           rm ${EXP}_${YEAR}${MON}.tar
        endif
   endif
#
######################################################
#calculate water isotope first
${CWISO} $DATF $DATF_wiso $COPY/WISO_${ANHA} ${ISOTBL} ${ISODAT}
#
###################################################
#
###################################################
# make postprocessing
#echo "processing ${DATF}, by using ${SERV} " >>& fort.after_${YEAR}
$SERV <inp_list1 $DATF $COPY/BOT_${ANHA}
$SERV <SELECT3 $DATF $COPY/ATM_${ANHA}
#
##################################################
set STAT = $status

if ( $STAT != 0 ) then
   echo "error occurs when doing postprocessing of gcm"
   exit 1
endif
#################################################
# calculate leaf area index
set NCL = /opt/packages/ncl/5.1.1/bin/ncl
cp ${diagwiso}create_land2d.ncl create_land2d_${EXP}${YEAR}${MON}.ncl
$NCL  dir=\"${DPATH}\"  expname=\"${EXP}\" yeartag=\"${YEAR}${MON}.01\" ftag=\"land\" diro=\"${COPY}\" \
         <  create_land2d_${EXP}${YEAR}${MON}.ncl > fort.land2d${YEAR}${MON}
rm create_land2d_${EXP}${YEAR}${MON}.ncl

cp ${diagwiso}create_land3d.ncl create_land3d_${EXP}${YEAR}${MON}.ncl
$NCL  dir=\"${DPATH}\"  expname=\"${EXP}\" yeartag=\"${YEAR}${MON}.01\" ftag=\"land\" diro=\"${COPY}\" \
         <  create_land3d_${EXP}${YEAR}${MON}.ncl > fort.land3d${YEAR}${MON}
rm create_land3d_${EXP}${YEAR}${MON}.ncl
################################################

set STAT = $status
if ( $STAT != 0 ) then
   echo "error occurs when doing postprocessing of land files"
   exit 1
endif

setenv tarfile ${EXP}_${YEAR}${MON}.tar
tar -cvf ${tarfile} ${EXP}_${YEAR}${MON}.01*.nc
gzip ${tarfile}
if ( $status == 0 ) then
    rm ${EXP}_${YEAR}${MON}.01*.nc
endif

end
@ YEAR = $YEAR + 1
end
#
###################################################
