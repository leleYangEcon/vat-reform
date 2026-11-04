*===============================================================================
* 02_did.do
* Define the treatment timing, the DID indicator, the control groups, and the event-study dummies
*===============================================================================



*--------------------------- 1. Keep only the first "1+6" batch ----------
* Drop service industries reformed in 2014 or later and the final 2016 batch
drop if inlist(note, "广播影视服务", "铁路和邮政", "电信业", "最后一波")

*--------------------------- 2. did setting -----------------------
* Shanghai 2012; eight provinces 2013; all remaining provinces 2014
* NOTE: uses 省份代码 (province codes such as "310000"), not PROVINCE_11 (province names)
gen PostTreat = 0
replace PostTreat = 1 if 省份代码 == "310000" & year >= 2012
replace PostTreat = 1 if inlist(省份代码, "110000", "320000", "340000", "350000","440000", "120000", "420000", "330000") & year >= 2013
replace PostTreat = 1 if year >= 2014


gen Treat = (note == "6plus1")
gen Post  = PostTreat
gen did   = Treat * Post

*------------- 3. Control group 1: direct consumption coefficient ------------

gen 干扰大的行业 = 0
local industries "A111 A112 A113 A119 A121 A122 A123 A131 A132 A133 A134 A141 A142 A143 A149 A151 A152 A153 A154 A159 A161 A162 A163 A164 A169 A171 A179 A181 A182 A190 A211 A212 A231 A232 A241 A242 A251 A252 A311 A312 A313 A314 A315 A319 A321 A322 A323 A329 A391 A392 A399 A411 A412 A421 A422 A511 A512 A513 A514 A515 A519 A521 A522 A523 A529 A531 A532 A539 A541 A549 C131 C132 C133 C134 C135 C136 C137 C139 C141 C142 C143 C144 C145 C146 C149 C151 C152 C153 C161 C162 C169 C221 C222 C223 C231 C232 C233 C251 C252 C253 C412 C254 C261 C262 C263 C264 C265 C266 C267 C268 C281 C282 C283 C347 C361 C362 C363 C364 C365 C366 C367 C371 C372 C373 C374 C375 C376 C377 C378 C379 C434 C381 C382 C383 C384 C385 C386 C387 C389 C435 C391 C392 C393 C394 C395 C396 C397 C398 C399 C241 C242 C243 C244 C245 C246 D441 D442 D443 F511 F512 F513 F514 F515 F516 F517 F518 F519 F521 F522 F523 F524 F525 F526 F527 F528 F529"

foreach ind of local industries {
    replace 干扰大的行业 = 1 if 国民行业三位数 == "`ind'"
}

keep if 干扰大的行业 == 0


*------------ 3. Control group 2: industry linkage (robustness) ---------------
* Manufacturing industries in the bottom 50% of industry linkage serve as controls
gen 制造业后50 = (全行业50_2010 == 0 & Treat == 0)
gen 保留 = (制造业后50 == 1 | Treat == 1)


*--------------------------- 4. Event study  ---------------------------
gen action = 0
replace action = 2012 if 省份代码 == "310000" & Treat == 1
replace action = 2013 if Eight   == 1        & Treat == 1
replace action = 2014 if Remains == 1        & Treat == 1

* PD: years relative to treatment
gen PD = year - action
replace PD = . if PD > 500      // for never-treated firms action = 0, so PD equals the calendar year

gen ind_city = (Treat == 1 & action > 0)

forvalues i = 6(-1)1 {
    gen Pre_`i' = (PD == -`i' & ind_city == 1)
}
forvalues j = 1/11 {
    gen Las_`j' = (PD == `j' & ind_city == 1)
}
gen Current = (PD == 0 & ind_city == 1)


save "$clean/只有6加1_新版.dta", replace
