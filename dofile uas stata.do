/*=========================================================================
Tugas Kelompok Organisasi Industri
Industri = Industri Pengolahan Kopi, Teh dan Herbal (Herb Infusion)
==========================================================================*/

global workdir "\Users\Jamie\Documents\Tugas\OI\"
cd "$workdir"

use SI2011-2015, clear
gen D4KBLI09=substr(DISIC5,1,4)
destring D4KBLI09, replace

**Memilih Lapangan Usaha no 1076, yaitu Industri Pengolahan Kopi, Teh dan Herbal
count if D4KBLI09==1076
keep if D4KBLI09==1076
**Menghitung jumlah perusahaan (Plant ID)
bysort PSID: gen byte tagpsid=(_n==1)
count if tagpsid>0

**Pemilihan variabel
keep PSID year DPROVI DKABUP DISIC5 OUTPUT YPRVCU VTLVCU LTLNOU V1101 V1103 V1106 V1109 V1112 V1115 CBNECU CMNECU CVNECU CONECU CTNECU ENPKHU EPLKHU RDNVCU RIMVCU RTLVCU IINPUT D4KBLI09

**Deflasi variabel dengan indeks harga masing-masing
*Membuat variabel Indeks Harga Perdagangan Besar untuk barang akhir, antara, dan awal menggunakan data IHPB sektor Industri untuk barang akhir pada 2011-2015.
gen IHPBAkh=.
replace IHPBAkh=178 if year==2011
replace IHPBAkh=186 if year==2012
replace IHPBAkh=192 if year==2013
replace IHPBAkh=123 if year==2014
replace IHPBAkh=132 if year==2015

gen IHPBAnt=.
replace IHPBAnt=181 if year==2011
replace IHPBAnt=188 if year==2012
replace IHPBAnt=194 if year==2013
replace IHPBAnt=122 if year==2014
replace IHPBAnt=130 if year==2015

gen IHPBMent=.
replace IHPBMent=221 if year==2011
replace IHPBMent=232 if year==2012
replace IHPBMent=247 if year==2013
replace IHPBMent=139 if year==2014
replace IHPBMent=163 if year==2015

*Membuat variabel Indeks Harga Konsumen umum menggunakan statistik inflasi pada 2011-2015
gen IHK=.
replace IHK=120 if year==2015
replace IHK=113 if year==2014
replace IHK=142 if year==2013
replace IHK=133 if year==2012
replace IHK=128 if year==2011

**Menyesuaikan masing-masing variabel dengan Indeks Harga masing-masing tahun
*Menyesuaikan gross output dengan IHPB akhir industri
gen rOUTPUT = OUTPUT/IHPBAkh*100
*Menyesuaikan produk dengan IHPB akhir industri
gen rPROD = YPRVCU/IHPBAkh*100
*Menyesuaikan value added dengan IHK industri
gen rVA = VTLVCU/IHK*100

ren LTLNOU LABOR

*Menyesuaikan modal yang dipakai dengan IHPB antara
gen CAPITAL = V1115/IHPBAnt
*Membuat variabel pengeluaran 
gen CAPElec = ENPKHU + EPLKHU
*Mengestimasi persentase barang mentah impor
gen primpor = RIMVCU/RTLVCU
*Mengestimasi IHPB material
gen IHPBmat = (IHPBMent + IHPBAnt)/2
*Mengestimasi input material sesuai dengan IHPB
gen MATERIAL = RTLVCU/IHPBmat*100 

**Removing Outliers
*See statdesc
sum rOUTPUT rPROD rVA LABOR CAPITAL CAPElec MATERIAL
drop if rPROD==.
*Check total number of firms
*Using boxplot (we cannot change the interquartile range)
graph box rOUTPUT
graph box rVA
*Using extremes
ssc install extremes
extremes rVA, iqr(1.5)
extremes rOUTPUT rPROD rVA LABOR CAPElec MATERIAL, iqr(3)
*Using histogram & spikeplot
hist rVA, frequency
spikeplot rVA
*Using z-score (3 standard dev of the mean)
egen stdrVA=std(rVA)
*Windsorizing
ssc install winsor2
sum rVA, detail
winsor2 rVA, replace cut(5 95)

**Calculating Productivity
gen OUTLprod=rOUTPUT/LABOR
gen PRODLprod=rPROD/LABOR
gen VALprod=rVA/LABOR
gen OUTCprod=rOUTPUT/CAPITAL
gen OUTCeprod=rOUTPUT/CAPElec
gen VALCprod=rVA/CAPElec

by year: egen meanVALprod = mean(VALprod)
twoway line meanVALprod year

//Cleaning selesai

**Mengestimasi Total Factor Productivity
xtset PSID year

*Generating and Cleaning Investment and Intermediate Input Data
gen rIINPUT = IINPUT/IHPBmat*100
gen rINVEST = d.CAPITAL

*Membuat bentuk logaritmik dari variabel yang ada
gen va = ln(rVA)
gen l = ln(LABOR)
gen k = ln(CAPElec)
gen m = ln(rIINPUT)
gen i = ln(rINVEST)
replace i=0 if rINVEST==0

**Mengestimasi Production Function menggunakan TransLog

prodest va, method(lp) free(l) proxy(m) state(k) acf va att trans id(PSID) t(year) poly(2) fsresiduals(residacftrans)
predict TFPacftrans, resid

*Membuat variabel rata-rata produktivitas berdasarkan tahun
egen meanTFPacftrans = mean(TFPacftrans), by (year)
sort year
twoway line meanTFPacftrans year

*Membuat variabel Production Level sesuai ACF
gen TFPlvACFtrans = exp(TFPacftrans)
egen meanTFPlvACFtrans = mean(TFPlvACFtrans), by (year)
twoway line meanTFPlvACFtrans year

save SI2011-2015_TFPEst_Tugaskelompok, replace

//Prodest selesai

**Mengestimasi Markup

use SI2011-2015, clear
keep PSID year ZPSVCU ZNSVCU
gen laborexpenses=ZPSVCU+ZNSVCU
save SI2011-2015_LaborExp, replace

use SI2011-2015_TFPEst_Tugaskelompok, clear

merge m:1 PSID year using SI2011-2015_LaborExp
destring D4KBLI09, replace

**Prosedur DLW

xtset PSID year

ssc install markupest

*Mengestimasi Markup Industri terkait
markupest markup, method(dlw) id(PSID) t(year) output(va) inputvar(l) free(l) state(k) proxy(m) valueadded prodestopt("poly(2) acf translog") verbose corr

*Membuat variabel rata-rata markup per tahun
egen meanmarkup=mean(markup), by(year)
sort year
twoway line meanmarkup year

drop if laborexpenses==.

*Melakukan penyesuaian markup dengan pengeluaran untuk input labor
gen markupeslabexp=markup*l/laborexpenses 

*Membuar variabel rata-rata atas markup yang telah disesuaikan, kemudian mengurutkan berdasarkan tahun
egen meanmarkuplabexp=mean(markupeslabexp), by(year)
sort year
twoway line meanmarkuplabexp year

save SI2011-2015_Markup_Tugaskelompok, replace


