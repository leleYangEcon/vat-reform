*===============================================================================
* 03_variables.do
* variables used in the mechanism and heterogeneity analyses
*===============================================================================

*======== Taxes and surcharges =========
* reshape wide format
use "$raw/税收相关数据.dta", clear
forvalues y = 2008/2023 {
    rename *税金及附加*`y'* tax_add`y'      // taxes and surcharges
}

keep 证券代码 tax_add*
reshape long tax_add, i(证券代码) j(year)
gen code_str = substr(证券代码, 1, 6)

gen tax_add_test = ln(1 + tax_add)
winsor2 tax_add_test, cut(1 99)
keep code_str year tax_add_test tax_add_test_w
save "$clean/税收相关数据.dta", replace

* merge
use "$clean/只有6加1_新版.dta", clear
merge m:1 code_str year using "$clean/税收相关数据.dta", keep(1 3) nogen

*1. Tax burden------------------------------------------------------------------
*tax burden=(taxes paid-tax rebates received)/operating revenue
gen TaxBurden1 = (C001021000 - C001012000) / B001101000

*Effective income tax rate=income tax expense/ EBIT
gen tax_suode = B002100000 / F050601B

winsor2 TaxBurden1 tax_suode
replace tax_suode_w = . if tax_suode_w < 0

*2. Tax rebates-----------------------------------------------------------------
gen ssfh_temp = ln(C001012000 + 1)
winsor2 ssfh_temp

*3. Bank loans------------------------------------------------------------------
*Total bank loans=(short term + long term)/total assets
gen bank = (A212101_32 + A002201000 + A002101000) / A001000000
winsor2 bank

*4. Cross-regional investment---------------------------------------------------
merge m:1 code_str year using "$clean/cross_regional_investment.dta", keep(1 3) nogen

*5. Land supply--------------------------- -------------
merge m:1 year CITYCODE_13 using "$raw/地级市土地出让.dta", ///
    keepusing(ln_工业用地_供地面积_公顷 ln_商住用地_供地面积_公顷) keep(1 3) nogen
winsor2 ln_工业用地_供地面积_公顷 ln_商住用地_供地面积_公顷

*6. Marketization index --------------------------------------------------------
merge m:1 PROVINCE_11 year using "$raw/樊纲市场化指数.dta", ///
 keepusing(市场化进程总得分 政府与市场关系得分 中介组织发育和法律得分) keep(1 3) nogen

*7. Market segmentation index -------------------------------------------------
merge m:1 PROVINCE_11 year using "$clean/segment.dta", keepusing(PPI_seg_100) keep(1 3) nogen

save "$clean/只有6加1_新版.dta", replace