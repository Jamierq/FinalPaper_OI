/*=========================================================================
Paper Final Organisasi Industri
Nama: Muhammad Jamie Rofie Quality
NPM : 2006473812
==========================================================================*/


global workdir "\Users\Jamie\Documents\Tugas\OI\"
cd "$workdir"

use SI2011-2015, clear
gen D4KBLI09=substr(DISIC5,1,4)
destring D4KBLI09, replace

**Memilih Lapangan Usaha no 2101, yaitu Industri Farmasi dan Produk Obat Kimia
count if D4KBLI09==2101
keep if D4KBLI09==2101

**Pemilihan variabel
keep PSID year DPROVI DKABUP DISIC5 OUTPUT YPRVCU VTLVCU LFANOU LPDNOU LTLNOU V1101 V1103 V1106 V1109 V1112 V1115 CBNECU CMNECU CVNECU CONECU CTNECU ENPKHU EPLKHU EFUVCU RDNVCU RIMVCU RTLVCU IINPUT D4KBLI09 DDMSTK DPUSAT DASING DPEMDA

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
*Membuat variabel pengeluaran listrik
gen CAPElec = ENPKHU + EPLKHU
*Membuat variabel pengeluaran BBM
gen CAPFuel = EFUVCU
*Mengestimasi persentase barang mentah impor
gen primpor = RIMVCU/RTLVCU
*Mengestimasi IHPB material
gen IHPBmat = (IHPBMent + IHPBAnt)/2
*Mengestimasi input material sesuai dengan IHPB
gen MATERIAL = RTLVCU/IHPBmat*100
*Membuat dummy variabel perusahaan asing
gen dasing = DASING > 50 if DASING <.
*Membuat dummy variabel perusahaan swasta domestik
gen ddmstk = DDMSTK>50 if DDMSTK<.
*Membuat dummy variabel perusahaan pemerintah
gen dgovt = DPUSAT>50 | DPEMDA>50 if DPUSAT<.|DPEMDA<.
*Membuat dummy variabel bahan impor dengan batas 50%
gen dimpor = primpor>.5 if primpor<.

**Removing Outliers
*See statdesc
sum rOUTPUT rPROD rVA LABOR CAPITAL CAPElec MATERIAL
drop if rPROD==.
*Check total number of firms
*Using boxplot (we cannot change the interquartile range)
graph box rOUTPUT
graph box rVA
*Menggunakan extremes
extremes rVA, iqr(1.5)
extremes rOUTPUT rPROD rVA LABOR CAPElec MATERIAL CAPFuel, iqr(3)
*Using histogram & spikeplot
hist rVA, frequency
spikeplot rVA
*Using z-score (3 standard dev of the mean)
egen stdrVA=std(rVA)
*Windsorizing
sum rVA, detail
winsor2 rVA, replace cut(5 85)

**Calculating Productivity
gen OUTLprod=rOUTPUT/LABOR
gen PRODLprod=rPROD/LABOR
gen VALprod=rVA/LABOR
gen OUTCprod=rOUTPUT/CAPITAL
gen OUTCeprod=rOUTPUT/CAPElec
gen OUTCfprod=rOUTPUT/CAPFuel
gen VALCeprod=rVA/CAPElec
gen VALCfprod=rVA/CAPFuel

by year: egen meanVALprod = mean(VALprod)
twoway line meanVALprod year

//Cleaning selesai

**Mengestimasi Total Factor Productivity
xtset PSID year

*Generating and Cleaning Investment and Intermediate Input Data
gen rIINPUT = IINPUT/IHPBmat*100
gen rINVEST = d.CAPITAL

*Membuat bentuk logaritmik dari variabel yang ada
gen y = ln(rOUTPUT)
gen va = ln(rVA)
gen k = ln(CAPITAL)
gen l = ln(LABOR)
gen e = ln(CAPElec)
gen f = ln(CAPFuel)
gen ef = ln(CAPFuel + CAPElec)
gen m = ln(rIINPUT)
gen i = ln(rINVEST)
replace i=0 if rINVEST==0
replace i=0 if rINVEST==.

*Estimasi Fungsi Produksi menggunakan variabel Output dengan ACF
acfest y, state(k) proxy(i) free(l) i(PSID) intmat(m ef) t(year) nbs(200) invest robust
acfest y, state(k) proxy(i) free(l) i(PSID) intmat(m ef) t(year) nbs(200) invest robust second

*Estimasi Fungsi Produksi menggunakan variabel Output dengan ACF
acfest va, state(k) proxy(i) free(l) i(PSID) t(year) nbs(200) va invest robust
acfest va, state(k) proxy(i) free(l) i(PSID) t(year) nbs(200) va invest robust second

*Melakukan analisis lanjutan (overidentifiaction)
acfest va, state(k) proxy(i) free(l) i(PSID) t(year) nbs(200) va overid invest robust second
predict omega_hat, omega

histogram omega_hat, by(dimpor)
sktest omega_hat if dimpor==0
sktest omega_hat if dimpor==1
tabstat omega_hat if dimpor==0, stats(n mean median min max)
tabstat omega_hat if dimpor==1, stats(n mean median min max)

histogram omega_hat, by(ddmstk dgovt dasing)
sktest omega_hat if ddmstk==1
sktest omega_hat if dgovt==1
sktest omega_hat if dasing==1
tabstat omega_hat if ddmstk==1, stats(n mean median min max)
tabstat omega_hat if dgovt==1, stats(n mean median min max)
tabstat omega_hat if dasing==1, stats(n mean median min max)

save SI2011-2015_UAS, replace
