*===============================================================================
* 01 stylized facts
*===============================================================================

*======================== Figure 1  Composition of local tax revenue ==========
use "$raw/地方税收变化.dta", clear

ds 年份 合计, not
foreach var of varlist `r(varlist)' {
    gen `var'_占比 = `var' / 合计 * 100
}

twoway (line 增值税_占比     year, lcolor(black) lwidth(medthick))                  ///
       (line 营业税_占比     year, lcolor(black) lwidth(medthick) lpattern(dash))   ///
       (line 企业所得税_占比 year, lcolor(black) lwidth(medthick) lpattern(dot))    ///
       (line 个人所得税_占比 year, lcolor(black) lwidth(medthick) lpattern(longdash)), ///
       legend(order(1 "增值税" 2 "营业税" 3 "企业所得税" 4 "个人所得税")          ///
              rows(1) position(6) size(small) region(lstyle(none)))               ///
       xtitle("年份") ytitle("占地方税收收入比例（%）")                            ///
       ylabel(0(5)45, format(%9.0f) labsize(vsmall) nogrid)                        ///
       xlabel(1998(1)2021, labsize(vsmall) angle(45))                              ///
       graphregion(color(white)) bgcolor(white)
graph export "$figs/Figure1_local_tax_composition.png", replace

*======================== Figure 2  Growth rate of local tax revenue ==========
sort year
tsset year

* annual growth rate of each tax
foreach v in 个人所得税 企业所得税 增值税 营业税 合计 {
    gen growth_`v' = (`v' - L.`v') / L.`v' * 100 if !missing(L.`v')
}

twoway (line growth_增值税     year, lcolor(black) lwidth(medthick))                ///
       (line growth_营业税     year, lcolor(black) lwidth(medthick) lpattern(dash)) ///
       (line growth_企业所得税 year, lcolor(black) lwidth(medthick) lpattern(dot))  ///
       (line growth_个人所得税 year, lcolor(black) lwidth(medthick) lpattern(longdash)), ///
       legend(order(1 "增值税" 2 "营业税" 3 "企业所得税" 4 "个人所得税")          ///
              rows(1) position(6) size(small) region(lstyle(none)))               ///
       xtitle("年份", size(small))                                                 ///
       ytitle("地方税收收入增速（%）", size(small))                                ///
       ylabel(-50(10)85, format(%2.0f) labsize(vsmall) gmin gmax nogrid)           ///
       xlabel(1998(1)2021, labsize(vsmall) angle(45))                              ///
       yline(0, lcolor(black) lpattern(dash) lwidth(thin))                         ///
       graphregion(color(white)) plotregion(margin(small))
graph export "$figs/Figure2_local_tax_growth.png", replace

*======================== Figures 3-5  Fiscal ratios ==========================
use "$raw/省级财政数据.dta", clear

//aggregate provincial data to the national level
collapse (sum) 地方财政税收收入 地方财政非税收入 地方财政一般预算收入 地方财政一般预算支出, by(year)

sort year
tsset year

* ratios to general budget expenditure 
gen totaltax_expenditure = 地方财政税收收入     / 地方财政一般预算支出 * 100
gen nontax_expenditure   = 地方财政非税收入     / 地方财政一般预算支出 * 100
gen fiscal_autonomy      = 地方财政一般预算收入 / 地方财政一般预算支出 * 100

* annual growth rates of tax and non-tax revenue
gen growth_tax    = (地方财政税收收入 - L.地方财政税收收入) / L.地方财政税收收入 * 100 ///
                    if !missing(L.地方财政税收收入)
gen growth_nontax = (地方财政非税收入 - L.地方财政非税收入) / L.地方财政非税收入 * 100 ///
                    if !missing(L.地方财政非税收入)

*--------------------------- Figure 3: tax revenue -------------------------------
* Left axis: tax revenue / expenditure; right axis: growth rate of tax revenue
twoway (line totaltax_expenditure year if year > 1998,                       ///
             lcolor(black) lwidth(medthick) yaxis(1))                        ///
       (line growth_tax year if year > 1998,                                 ///
             lcolor(black) lwidth(medthick) lpattern(dash) yaxis(2)),        ///
       legend(order(1 "税收收入占一般预算支出比重（左轴）"                   ///
                    2 "税收收入增速（右轴）")                                ///
              rows(1) position(6) size(small) region(lstyle(none)))         ///
       xtitle("年份")                                                        ///
       ytitle("占一般预算支出比重（%）", axis(1))                            ///
       ytitle("增速（%）", axis(2))                                          ///
       ylabel(, nogrid labsize(vsmall) axis(1))                              ///
       ylabel(, nogrid labsize(vsmall) axis(2))                              ///
       xlabel(1999(1)2021, labsize(vsmall) angle(45))                        ///
       graphregion(color(white)) bgcolor(white)
graph export "$figs/Figure3_tax_expenditure.png", replace

*--------------------------- Figure 4: non-tax revenue ---------------------------
* Left axis: non-tax revenue / expenditure; right axis: growth rate of non-tax revenue
twoway (line nontax_expenditure year if year > 1998,                         ///
             lcolor(black) lwidth(medthick) yaxis(1))                        ///
       (line growth_nontax year if year > 1998,                              ///
             lcolor(black) lwidth(medthick) lpattern(dash) yaxis(2)),        ///
       legend(order(1 "非税收入占一般预算支出比重"                           ///
                    2 "非税收入增速")                                        ///
              rows(1) position(6) size(small) region(lstyle(none)))         ///
       xtitle("年份")                                                        ///
       ytitle("占一般预算支出比重（%）", axis(1))                            ///
       ytitle("增速（%）", axis(2))                                          ///
       ylabel(, nogrid labsize(vsmall) axis(1))                              ///
       ylabel(, nogrid labsize(vsmall) axis(2))                              ///
       xlabel(1999(1)2021, labsize(vsmall) angle(45))                        ///
       graphregion(color(white)) bgcolor(white)
graph export "$figs/Figure4_nontax_expenditure.png", replace

*--------------------------- Figure 5: fiscal autonomy ---------------------------
* fiscal autonomy = general budget revenue / general budget expenditure
twoway (line fiscal_autonomy year if year > 1998,                            ///
             lcolor(black) lwidth(medthick)),                                ///
       xtitle("年份") ytitle("财政自主度（%）")                              ///
       ylabel(, nogrid labsize(vsmall))                                      ///
       xlabel(1999(1)2021, labsize(vsmall) angle(45))                        ///
       graphregion(color(white)) bgcolor(white)
graph export "$figs/Figure5_fiscal_autonomy.png", replace