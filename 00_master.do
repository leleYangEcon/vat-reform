*===========================================================================

* Project: Fiscal Incentives, Allocative Efficiency, and the Unified National Market: Evidence from China's VAT Reform

*===========================================================================
clear all
set more off
*------------------------------- 1. Paths ----------------------------------------
global root "path/to/project"
global code   "$root/code"
global raw    "$root/data/raw"
global clean  "$root/data/clean"
global tables "$root/output/tables"
global figs   "$root/output/figures"
*------------------------------- 2. External packages ----------------------------
ssc install ftools,   replace
ssc install psmatch2, replace
ssc install csdid,    replace
ssc install drdid,    replace
ssc install bdiff,    replace
ssc install distinct, replace
*------------------------------- 3. Global macros --------------------------------

* PSM Covariates
global xlist "size_w DA_w roa_w invt_w top1_w cash_w growth_w ia_w administration_w TR_w Fin_w"

* fe and cluster
global fe "absorb(year code) cluster(PROVINCE_11)"

* esttab
global esopt `"b(%12.3f) se(%12.3f) nogap compress star(* 0.1 ** 0.05 *** 0.01)"'

*------------------------------- 4. Run ------------------------------------------
* notes:cross-regional investment is built in Python
do "$code/02_build_sample.do"
do "$code/03_build_variables.do"
do "$code/04_build_robustness_samples.do"
do "$code/05_placebo.do"
do "$code/06_export_results.do"
do "$code/07_stylized_facts.do"

