*===============================================================================
* 06 export results


*===============================================================================
* Table 2  Descriptive statistics
*===============================================================================
use "$clean/只有6加1_新版.dta", clear

logout, save("$tables/Table2_descriptive") word replace :                           ///
    tabstat TFP_LP TFP_OP TFP_GMM $xlist tax_add_test tax_suode_w TaxBurden1_w        ///
            ssfh_temp_w bank_w yd_investment_ln xzyd                                  ///
            ln_工业用地_供地面积_公顷 ln_商住用地_供地面积_公顷                        ///
            HHI_B_ 市场化进程总得分 政府与市场关系得分 中介组织发育和法律得分,         ///
            s(N mean max min sd) f(%12.3f) c(s)


*===============================================================================
* Table 3  Baseline results
*===============================================================================
est clear
use "$clean/只有6加1_新版.dta", clear

* (1) Province + industry + year fixed effects
reghdfe TFP_LP did, absorb(year industry_guoming province) cluster(PROVINCE_11)
  estadd local year "Yes"
  estadd local industry_guoming "Yes"
  estadd local PROVINCE_11 "Yes"
  est sto m1

* (2) baseline:Firm + year fixed effects 
reghdfe TFP_LP did, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto m2

* (3) PSM-DID: cross-sectional matching, frequency-weighted
use "$clean/PSM_DID_1.dta", clear
reghdfe TFP_LP did $xlist [fweight = weight]
  est sto P1_3

* (4) PSM-DID: year-by-year matching, frequency-weighted
use "$clean/ybydata.dta", clear
reghdfe TFP_LP did $xlist [fweight = weight]
  est sto P2_3

esttab m1 m2 P1_3 P2_3 using "$tables/Table3_baseline.rtf", replace ///
    b(%12.3f) se(%12.3f) nogap compress ///
    s(code year industry_guoming PROVINCE_11 r2_a N) star(* 0.1 ** 0.05 *** 0.01)


*===============================================================================
* Figure 6 and Figure 7  Parallel trends
*===============================================================================
use "$clean/只有6加1_新版.dta", clear

* Figure 6: mean TFP of the treatment and control groups
preserve
    collapse (mean) TFP_LP, by(year Treat)
    twoway (connected TFP_LP year if Treat == 1, sort)                               ///
           (connected TFP_LP year if Treat == 0, sort lpattern(dash) msymbol(triangle)), ///
           xline(2012, lpattern(dash) lcolor(gray))                                  ///
           xlabel(2008(1)2023, labsize(*0.75)) ytitle("TFP (LP)") xtitle("Year")     ///
           legend(label(1 "Treatment") label(2 "Control")) graphregion(color(white))
    graph export "$figs/Figure6_TFP_trend.png", replace
restore

* Figure 7: event study
/// note: the event-time dummies together cover every treated observation and are collinear with the firm fixed effects; reghdfe drops the last variable listed, so Pre_1 is listed last and becomes the reference period -1.
reghdfe TFP_LP Pre_6 Pre_5 Pre_4 Pre_3 Pre_2 Current Las_1-Las_11 Pre_1, $fe

coefplot, baselevels omitted keep(Pre_* Current Las_*) vertical recast(connect) color(gs0) ///
    order(Pre_6 Pre_5 Pre_4 Pre_3 Pre_2 Pre_1 Current Las_1 Las_2 Las_3 Las_4 Las_5 Las_6 Las_7 Las_8 Las_9 Las_10 Las_11) ///
    yline(0, lp(solid) lc(gs0) lw(thin)) xline(7, lp(solid) lc(gs0) lw(thin))   ///
    xlabel(1 "-6" 2 "-5" 3 "-4" 4 "-3" 5 "-2" 6 "-1" 7 "0" 8 "1" 9 "2" 10 "3"     ///
           11 "4" 12 "5" 13 "6" 14 "7" 15 "8" 16 "9" 17 "10" 18 "11")              ///
    ciopts(recast(rcap) lc(gs0) lp(dash) lw(thin))                                ///
    ytitle("Treatment Effect") xtitle("Time") scale(1.2) xscale(titlegap(tiny))   ///
    graphregion(color(white))
graph export "$figs/Figure7_event_study.png", replace


*===============================================================================
* Table 4  Industry spillovers, clustering, last reform batch, alternative TFP
*===============================================================================
est clear

* (1)total consumption coefficient
use "$clean/只有6加1_新版_排除完全消耗系数大的.dta", clear
reghdfe TFP_LP did, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto t4_1

* (2) Industry linkage_bottom 50% 
use "$clean/只有6加1_新版.dta", clear
preserve
    keep if 保留 == 1
    gen did_后50 = Treat * Post
    reghdfe TFP_LP did_后50, $fe
      estadd local code "Yes"
      estadd local year "Yes"
      est sto t4_2
restore

* (3)clustered by industry
reghdfe TFP_LP did, absorb(year code) cluster(国民经济行业代码_两位数)
  estadd local code "Yes"
  estadd local year "Yes"
  est sto t4_3

* (5) TFP estimated by GMM
reghdfe TFP_GMM did, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto t4_5

* (6) TFP estimated by OP
reghdfe TFP_OP did, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto t4_6

* (4) Last reform batch 2016 as the treatment group
use "$clean/2016反向冲击.dta", clear
gen treated = (note == "最后一波")
gen Post = (year >= 2017)
gen did_反向 = treated * Post
reghdfe TFP_LP did_反向, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto t4_4

esttab t4_1 t4_2 t4_3 t4_4 t4_5 t4_6 using "$tables/Table4_robustness.rtf", replace ///
    rename(did_后50 did did_反向 did)                                               ///
    b(%12.3f) se(%12.3f) nogap compress ///
    s(code year r2_a N) star(* 0.1 ** 0.05 *** 0.01)


*===============================================================================
* Table 5  Sample through 2016, excluding firms with changes, CSDID
*===============================================================================
est clear

* (1) exclude the effect of the 2016 50:50 revenue sharing
use "$clean/只有6加1_新版.dta", clear
reghdfe TFP_LP did if year =< 2016, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto w1

* (2)exclude firms changed industry codes
use "$clean/去除行业变更_证监会代码.dta", clear
reghdfe TFP_LP did, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto w2

* (3)exclude firms changed their main business
use "$clean/删除主营业务增加的.dta", clear
reghdfe TFP_LP did, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto w3

* (4) exclude firms changed registered province
bysort code (PROVINCE_11): gen moved = (PROVINCE_11[1] != PROVINCE_11[_N])

reghdfe TFP_LP did if moved == 0, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto w4

esttab w1 w2 w3 w4 using "$tables/Table5_robustness.rtf", replace ///
    b(%12.3f) se(%12.3f) nogap compress ///
    s(code year r2_a N) star(* 0.1 ** 0.05 *** 0.01)

* (5) Callaway-Sant'Anna estimator (results exported manually)
use "$clean/只有6加1_新版.dta", clear

// year each firm is first treated. never-treated firms are set to 0
gen treat_year = year if did == 1
bysort code: egen gvar = min(treat_year)
replace gvar = 0 if gvar == .

// province in each firm's first year, used as a time-invariant cluster variable

encode PROVINCE_11, gen(prov_id)
bysort code (year): gen first_prov = prov_id[1]

csdid TFP_LP, ivar(code) time(year) gvar(gvar) method(reg) cluster(first_prov) notyet
estat simple
estat event, window(-4 5)
csdid_plot
graph export "$figs/Figure10_csdid_event.png", replace


*===============================================================================
* Table 6  Heterogeneity
*===============================================================================
est clear
use "$clean/只有6加1_新版.dta", clear

*--------------------------- Ownership ------------------------------------------
* hierarchy: 0 = local SOE, 1 = central SOE, 2 = non-SOE
gen soe = .
replace soe = 1 if hierarchy == 0
replace soe = 0 if hierarchy == 2

reghdfe TFP_LP did if hierarchy == 0, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto y1

reghdfe TFP_LP did if hierarchy == 2, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto y2

* Permutation test of the difference between groups 
set seed 0000
bdiff, group(soe) model(reghdfe TFP_LP did, $fe) reps(1000)

*--------------------------- Market segmentation groups -------------------------
// split provinces at the median of the pre-reform segmentation index
// note: municipalities (Beijing, Shanghai, Tianjin, Chongqing) are excluded from the split,so their firms are not in either group.
gen is_city = inlist(PROVINCE_11, "北京市", "上海市", "天津市", "重庆市")

// assign each province its 2011 index value
// egen max() ignores missing values
gen seg_2011_temp = PPI_seg_100 if year == 2011
bysort PROVINCE_11: egen seg_initial = max(seg_2011_temp)
drop seg_2011_temp

* median across the 27 non-municipality provinces
egen prov_tag = tag(PROVINCE_11) if year == 2011
sum seg_initial if prov_tag == 1 & is_city == 0, detail
local med_seg = r(p50)
drop prov_tag

// 1 = high segmentation, 0 = low segmentation, missing for municipalities
gen high_seg = (seg_initial > `med_seg') if !is_city & !missing(seg_initial)

* low segmentation 
reghdfe TFP_LP did if high_seg == 0, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto y3

* high segmentation 
reghdfe TFP_LP did if high_seg == 1, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto y4

set seed 0000
bdiff, group(high_seg) model(reghdfe TFP_LP did, $fe) reps(1000)

* Provinces in each group
tab PROVINCE_11 if high_seg == 1 & year == 2011
tab PROVINCE_11 if high_seg == 0 & year == 2011

esttab y1 y2 y3 y4 using "$tables/Table6_heterogeneity.rtf", replace ///
    b(%12.3f) se(%12.3f) nogap compress ///
    s(code year r2_a N) star(* 0.1 ** 0.05 *** 0.01)


*===============================================================================
* Table 7  Mechanism: tax burden
*===============================================================================
est clear

reghdfe tax_add_test did, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto j1

reghdfe tax_suode_w did, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto j2

reghdfe TaxBurden1_w did, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto j3

esttab j1 j2 j3 using "$tables/Table7_tax.rtf", replace ///
    b(%12.3f) se(%12.3f) nogap compress ///
    s(code year r2_a N) star(* 0.1 ** 0.05 *** 0.01)


*===============================================================================
* Table 8  Mechanism: tax rebates
*===============================================================================
est clear

reghdfe ssfh_temp_w did, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto z1

reghdfe ssfh_temp_w did if soe == 0, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto z1_1

reghdfe ssfh_temp_w did if soe == 1, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto z1_2

set seed 0000
bdiff, group(soe) model(reghdfe ssfh_temp_w did, $fe) reps(1000)

esttab z1 z1_1 z1_2 using "$tables/Table8_rebates.rtf", replace ///
    b(%12.3f) se(%12.3f) nogap compress ///
    s(code year r2_a N) star(* 0.1 ** 0.05 *** 0.01)


*===============================================================================
* Table 9  Mechanism: bank loans and cross-regional investment
*===============================================================================
est clear

reghdfe bank_w did, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto z2

reghdfe bank_w did if soe == 0, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto z2_1

reghdfe bank_w did if soe == 1, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto z2_2

set seed 0000
bdiff, group(soe) model(reghdfe bank_w did, $fe) reps(1000)

* New subsidiary in another region
reghdfe xzyd did, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto i2

esttab z2 z2_1 z2_2 i2 using "$tables/Table9_financing_investment.rtf", replace ///
    b(%12.3f) se(%12.3f) nogap compress ///
    s(code year r2_a N) star(* 0.1 ** 0.05 *** 0.01)


*===============================================================================
* Table 10  Mechanism: land supply and institutional environment
*===============================================================================
est clear

* Land supply
reghdfe ln_工业用地_供地面积_公顷_w did, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto gd1

reghdfe ln_商住用地_供地面积_公顷 did, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto gd2

* Market concentration and marketization
reghdfe HHI_B_ did, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto hhi

reghdfe 市场化进程总得分 did, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto market

reghdfe 政府与市场关系得分 did, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto gov

reghdfe 中介组织发育和法律得分 did, $fe
  estadd local code "Yes"
  estadd local year "Yes"
  est sto dev

esttab gd1 gd2 hhi market gov dev using "$tables/Table10_land_institutions.rtf", replace ///
    b(%12.3f) se(%12.3f) nogap compress ///
    s(code year r2_a N) star(* 0.1 ** 0.05 *** 0.01)
