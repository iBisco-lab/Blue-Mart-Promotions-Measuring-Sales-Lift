clear all
set more off

cd "C:\Users\Tomma\OneDrive\Desktop\Marketing Analytics\GP\Final Codes"

import delimited using "30420_Project2_data_Group1_sales.csv", ///
    varnames(1) case(lower) clear

* convert to daily date
gen date_stata = daily(date, "YMD")
format date_stata %td
drop date
rename date_stata date

* Promo dummy at row level:
* 1 if the discount is > 0 and not missing
gen byte promo_line = (discount_pct > 0 & discount_pct < .)
label var promo_line "1 se questa transazione ha qualche sconto attivo"

* COLLAPSE at DAY level:
collapse (sum) qty_total = quantity ///
         (max) promo_active = promo_line, ///
         by(date)
		 
label var qty_total     
label var promo_active  

*CALENDAR VARIABLES (SEASONAL CONTROLS)

gen year  = year(date)
gen month = month(date)

gen byte dow = dow(date)
replace dow = 7 if dow == 0  
label define dowlbl 1 "Mon" 2 "Tue" 3 "Wed" 4 "Thu" 5 "Fri" 6 "Sat" 7 "Sun"
label values dow dowlbl

* Save base dataset
save "new_dataset.dta", replace
export delimited using "new_dataset.csv", replace

* 5. MODEL 1
gen log_qty = log(qty_total + 1)
label var log_qty "log(qty_total + 1)"

reg log_qty i.promo_active i.dow i.month
est store m_log

* Expected effects with and without promo (back-transform to level)
margins promo_active, expression(exp(predict()) - 1)

* 6. CONSTRUCTION OF DYNAMIC DATASET (PHASES 5 DAYS PRE/POST)

use "new_dataset.dta", clear
sort date

* Find the first and last date with promo active
egen promo_start_tmp = min(date) if promo_active == 1
egen promo_end_tmp   = max(date) if promo_active == 1

egen promo_start = min(promo_start_tmp)
egen promo_end   = max(promo_end_tmp)

drop promo_start_tmp promo_end_tmp

* Quick check (optional)
display "Promo start: " %td promo_start
display "Promo end:   " %td promo_end

* Define phase:
* 1 = baseline (default)
* 2 = pre  (up to 5 days before promo start)
* 3 = promo
* 4 = post (up to 5 days after promo end)

gen byte phase = .
replace phase = 3 if promo_active == 1
replace phase = 2 if promo_active == 0 & date >= promo_start - 5 & date <  promo_start
replace phase = 4 if promo_active == 0 & date >  promo_end   & date <= promo_end + 5
replace phase = 1 if missing(phase)

label define phase_lbl 1 "baseline" 2 "pre" 3 "promo" 4 "post"
label values phase phase_lbl
label var phase "Dynamic promo phase (5d pre/post)"

save "new_dataset_dynamic_effects_5d.dta", replace
export delimited using "new_dataset_dynamic_effects_5d.csv", replace

* 7. MODEL 2: LOG WITH DYNAMIC PHASES

use "new_dataset_dynamic_effects_5d.dta", clear

gen log_qty = log(qty_total + 1)
label var log_qty "log(qty_total + 1)"

reg log_qty i.phase i.dow i.month
est store m_log_phase

* Predictions for each phase (back-transformed)
margins phase, expression(exp(predict()) - 1)
