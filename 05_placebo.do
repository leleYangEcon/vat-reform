*===============================================================================
* 05_placebo.do
*===============================================================================

*--------------------------- 1. Baseline estimate -------------------------------
use "$clean/只有6加1_新版.dta", clear
xtset code year

qui reghdfe TFP_LP did, $fe
local b_true = _b[did]

*--------------------------- 2. Size of each random draw ------------------------
// Number of treated observations(firm-years), used as the number of placebo firms drawn in each replication
count if Treat == 1
local n_treat_obs = r(N)
display "Treated firm-years: `n_treat_obs'"

// The original code fixed this number at 6429, stop if the data no longer match
assert `n_treat_obs' == 6429


*--------------------------- 3. 1000 random draws ------------------------------
tempfile placebo_draw

* Random seed: makes the 1,000 draws reproducible
set seed 0000

mat b  = J(1000, 1, .)
mat se = J(1000, 1, .)
mat p  = J(1000, 1, .)

forvalues i = 1/1000 {
    qui {
        use "$clean/只有6加1_新版.dta", clear
        xtset code year

        * Draw one random fake year per firm 
        bys code (year): gen bbb = _n
        sample 1 if bbb != 1, count by(code) //excluding its first year
        drop if bbb == 1

        * Draw the placebo treated firms
        sample `n_treat_obs', count
        keep code year
        rename year policy_year
        save `placebo_draw', replace

        * Merge back
        merge 1:m code using "$clean/只有6加1_新版.dta"
        gen treat_aw     = (_merge == 3)
        gen period       = (year >= policy_year)
        gen ddd_placebo2 = treat_aw * period

        reghdfe TFP_LP ddd_placebo2, $fe
        mat b[`i', 1]  = _b[ddd_placebo2]
        mat se[`i', 1] = _se[ddd_placebo2]
        mat p[`i', 1]  = 2 * ttail(e(df_r), abs(_b[ddd_placebo2] / _se[ddd_placebo2]))
    }
}

*--------------------------- 4. Plot --------------------------------------------
clear
svmat b,  names(coef)
svmat se, names(se)
svmat p,  names(pvalue)
drop if missing(pvalue1)
label var coef1   "估计系数"
label var pvalue1 "p值"

save "$clean/placebo_results.dta", replace

* Vertical line at the baseline estimate
twoway (kdensity coef1, yaxis(2))                                                   ///
       (scatter pvalue1 coef1, msymbol(smcircle_hollow) mcolor(gray) yaxis(1)),     ///
       xline(`b_true', lwidth(vthin) lp(shortdash))                                 ///
       yline(0.1, lwidth(vthin) lp(dash))                                           ///
       xlabel(-0.5(0.1)0.5, nogrid format(%4.2f))                                   ///
       ylabel(0(0.2)1, nogrid axis(1) format(%7.1f) angle(0))                       ///
       ylabel(, axis(2) angle(0))                                                   ///
       ytitle("p值", orientation(horizontal) axis(1))                               ///
       ytitle("核密度", orientation(horizontal) axis(2))                            ///
       xtitle("估计系数")                                                           ///
       legend(label(1 "估计系数核密度") label(2 "p值"))                             ///
       plotregion(style(none)) graphregion(color(white))
graph export "$figs/placebo_TFP.png", replace