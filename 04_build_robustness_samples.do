*===============================================================================
* 04 robustness.do
* prepare for PSM-DID 

*======================== 1. Control group based on total consumption coefficient ===
use "$clean/只有6加1_新版.dta", clear

gen 干扰大的行业_完全消耗系数 = 0
local industries A111 A112 A113 A119 A121 A122 A123 A131 A132 A133 A134 A141 A142 A143 A149 A151 A152 A153 A154 A159 A161 A162 A163 A164 A169 A171 A179 A181 A182 A190 A211 A212 A231 A232 A241 A242 A251 A252 A311 A312 A313 A314 A315 A319 A321 A322 A323 A329 A391 A392 A399 A411 A412 A421 A422 A511 A512 A513 A514 A515 A519 A521 A522 A523 A529 A531 A532 A539 A541 A549 B711 B712 B721 B722 B112 C131 C132 C133 C134 C135 C136 C137 C139 C141 C142 C143 C144 C145 C146 C149 C151 C152 C153 C161 C162 C169 C221 C222 C223 C231 C232 C233 C251 C252 C253 C412 C254 C261 C262 C263 C264 C265 C266 C267 C268 C281 C282 C283 C311 C312 C313 C314 C321 C322 C323 C324 C325 C345 C346 C347 C348 C349 C351 C352 C353 C354 C355 C356 C357 C358 C359 C432 C433 C361 C362 C363 C364 C365 C366 C367 C371 C372 C373 C374 C375 C376 C377 C378 C379 C434 C381 C382 C383 C384 C385 C386 C387 C389 C435 C391 C392 C393 C394 C395 C396 C397 C398 C399 C241 C242 C243 C244 C245 C246 D441 D442 D443 F511 F512 F513 F514 F515 F516 F517 F518 F519 F521 F522 F523 F524 F525 F526 F527 F528 F529
foreach industry of local industries {
    replace 干扰大的行业_完全消耗系数 = 1 if 国民行业三位数 == "`industry'"
}
keep if 干扰大的行业_完全消耗系数 == 0
save "$clean/只有6加1_新版_排除完全消耗系数大的.dta", replace

*======================== 2. Drop firms that changed their main business ========
//delete firms whose main business description added service or industry keywords 

use "$clean/只有6加1_新版.dta", clear
merge 1:1 code_str year using "$clean/主营业务变更.dta", keepusing(scope_change) keep(1 3) nogen
replace scope_change = 0 if missing(scope_change)

*drop the whole firm of all years if it changed its main business in any year
bysort code: egen drop_firm = max(scope_change)
drop if drop_firm == 1
drop scope_change drop_firm
save "$clean/删除主营业务增加的.dta", replace



*======================== 3. Cross-sectional PSM  ===========================
use "$clean/只有6加1_新版.dta", clear
 
bysort code: egen treated = max(did)
tab treated

set seed 0000
gen norvar_1 = rnormal() //stata capture the nearest sample by default, which may be in the same province or code_str. So this is to generate random numbers as normal distribution to ensure random.
sort norvar_1

psmatch2 treated $xlist, outcome(TFP_LP TFP_OP) logit neighbor(2) ties common ate caliper(0.05)

* Frequency weights: matched controls get _weight * 2, treated firms get 1
gen     weight = _weight * 2
replace weight = 1 if treated == 1 & _weight != .

save "$clean/PSM_DID_1.dta", replace

*------Balance test and common support // see if the difference of controls and treated on covariant has been eliminated 
pstest, both graph saving("$figs/balancing_assumption", replace)
psgraph, saving("$figs/common_support", replace)

*--------------------------- Kernel density of propensity scores ----------------
* Mean propensity score of the treated group
sum _pscore if treated == 1, detail
local m_treat = r(mean)

* Before matching
sum _pscore if treated == 0, detail

twoway(kdensity _pscore if treated == 1, lpattern(solid)                     ///
              lcolor(black)                                                  ///
              lwidth(thin)                                                   ///
              scheme(qleanmono)                                              ///
              ytitle("{stSans:核}""{stSans:密}""{stSans:度}",                ///
                     size(medlarge) orientation(h))                          ///
              xtitle("{stSans:匹配前的倾向得分值}",                          ///
                     size(medlarge))                                         ///
              xline(`m_treat', lpattern(solid) lcolor(black))                ///
              xline(`r(mean)', lpattern(dash)  lcolor(black))                ///
              saving("$figs/kensity_cs_before", replace))                    ///
      (kdensity _pscore if treated == 0, lpattern(dash)),                    ///
      xlabel(     , labsize(medlarge) format(%02.1f))                        ///
      ylabel(0(1)4, labsize(medlarge))                                       ///
      legend(label(1 "{stSans:处理组}")                                      ///
             label(2 "{stSans:控制组}")                                      ///
             size(medlarge) position(1) symxsize(10))
graph export "$figs/kensity_cs_before.png", replace

* After matching
sum _pscore if treated == 0 & _weight != ., detail  // low scores would be replaced by.

twoway(kdensity _pscore if treated == 1, lpattern(solid)                     ///
              lcolor(black)                                                  ///
              lwidth(thin)                                                   ///
              scheme(qleanmono)                                              ///
              ytitle("{stSans:核}""{stSans:密}""{stSans:度}",                ///
                     size(medlarge) orientation(h))                          ///
              xtitle("{stSans:匹配后的倾向得分值}",                          ///
                     size(medlarge))                                         ///
              xline(`m_treat', lpattern(solid) lcolor(black))                ///
              xline(`r(mean)', lpattern(dash)  lcolor(black))                ///
              saving("$figs/kensity_cs_after", replace))                     ///
      (kdensity _pscore if treated == 0 & _weight != ., lpattern(dash)),     ///
      xlabel(     , labsize(medlarge) format(%02.1f))                        ///
      ylabel(0(1)4, labsize(medlarge))                                       ///
      legend(label(1 "{stSans:处理组}")                                      ///
             label(2 "{stSans:控制组}")                                      ///
             size(medlarge) position(1) symxsize(10))
graph export "$figs/kensity_cs_after.png", replace





*======================== 4. Year-by-year PSM ===================================
use "$clean/只有6加1_新版.dta", clear
bysort code: egen treated = max(did)

* Match within each year, then append all years.
// _rc is return code, _rc==0 means comands run successfully

tempfile yby
local first = 1
forvalues i = 2008/2023 {
    preserve
        keep if year == `i'
        set seed 0000
        gen norvar_2 = rnormal()
        sort norvar_2

        capture psmatch2 treated $xlist, outcome(TFP_LP) logit neighbor(2) ties common ate caliper(0.05)
        if _rc == 0 {
            if `first' == 0 append using `yby'
            save `yby', replace
            local first = 0
        }
        else {
            display as error "Matching failed for year `i'; year skipped"
        }
    restore
}
use `yby', clear

* Frequency weights
gen     weight = _weight * 2
replace weight = 1 if treated == 1 & _weight != .

save "$clean/ybydata.dta", replace

*--------------------------- Kernel density of propensity scores ----------------
sum _pscore if treated == 1, detail
local m_treat = r(mean)

* Before matching
sum _pscore if treated == 0, detail

twoway(kdensity _pscore if treated == 1, lpattern(solid)                     ///
              lcolor(black)                                                  ///
              lwidth(thin)                                                   ///
              scheme(qleanmono)                                              ///
              ytitle("{stSans:核}""{stSans:密}""{stSans:度}",                ///
                     size(medlarge) orientation(h))                          ///
              xtitle("{stSans:匹配前的倾向得分值}",                          ///
                     size(medlarge))                                         ///
              xline(`m_treat', lpattern(solid) lcolor(black))                ///
              xline(`r(mean)', lpattern(dash)  lcolor(black))                ///
              saving("$figs/kensity_yby_before", replace))                   ///
      (kdensity _pscore if treated == 0, lpattern(dash)),                    ///
      xlabel(     , labsize(medlarge) format(%02.1f))                        ///
      ylabel(0(1)3, labsize(medlarge))                                       ///
      legend(label(1 "{stSans:处理组}")                                      ///
             label(2 "{stSans:控制组}")                                      ///
             size(medlarge) position(1) symxsize(10))
graph export "$figs/kensity_yby_before.png", replace

* After matching
sum _pscore if treated == 0 & _weight != ., detail

twoway(kdensity _pscore if treated == 1, lpattern(solid)                     ///
              lcolor(black)                                                  ///
              lwidth(thin)                                                   ///
              scheme(qleanmono)                                              ///
              ytitle("{stSans:核}""{stSans:密}""{stSans:度}",                ///
                     size(medlarge) orientation(h))                          ///
              xtitle("{stSans:匹配后的倾向得分值}",                          ///
                     size(medlarge))                                         ///
              xline(`m_treat', lpattern(solid) lcolor(black))                ///
              xline(`r(mean)', lpattern(dash)  lcolor(black))                ///
              saving("$figs/kensity_yby_after", replace))                    ///
      (kdensity _pscore if treated == 0 & _weight != ., lpattern(dash)),     ///
      xlabel(     , labsize(medlarge) format(%02.1f))                        ///
      ylabel(0(1)3, labsize(medlarge))                                       ///
      legend(label(1 "{stSans:处理组}")                                      ///
             label(2 "{stSans:控制组}")                                      ///
             size(medlarge) position(1) symxsize(10))
graph export "$figs/kensity_yby_after.png", replace

*--------------------------- Year-by-year balance tests ------------------------
//Before, the coefficient should be significant. After, it should be insignificant.
//Because it's Year-by-year, so we have to regress each year
* Before matching  
estimates clear
local before ""
forvalues i = 2008/2023 {
    capture qui logit treated $xlist if year == `i', vce(cluster PROVINCE_11)
    if _rc == 0 {
        est store ybyb`i'
        local before "`before' ybyb`i'"
    }
}
esttab `before' using "$tables/逐年平衡性检验_匹配前.rtf", replace ///
    b(%6.4f) t(%6.4f) star(* 0.1 ** 0.05 *** 0.01)             ///
    scalars("N Observations" "r2_p Pseudo R-squared")          ///
    compress nogap                                              ///
    title("Table: Yearly Balance Test (Before Matching)")

* After matching (only years with more than 5 matched treated firms)
estimates clear
local after ""
forvalues i = 2008/2023 {
    qui count if year == `i' & treated == 1 & _weight != .
    if r(N) > 5 {
        capture qui logit treated $xlist if year == `i' & _weight != ., vce(cluster PROVINCE_11)
        if _rc == 0 {
            est store ybya`i'
            local after "`after' ybya`i'"
        }
    }
}
esttab `after' using "$tables/逐年平衡性检验_匹配后.rtf", replace ///
    b(4) t(4) star(* 0.1 ** 0.05 *** 0.01)                     ///
    scalars("N Observations" "r2_p Pseudo R-squared")          ///
    compress nogap                                              ///
    title("Table: Yearly Balance Test (After Matching)")