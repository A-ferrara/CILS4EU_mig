************************************************************************
************* 1. Definition of Globals *********************************
************************************************************************
 
************* 1.1 Globals defining your paths **************************
global path 			K:\Projekte\spellfiles\BEFEHLE\weiterentwicklung\examples
global MY_DO_FILE 		${path}\example_do_files
global MY_IN_PATH 		${path}\example_input_data\spell_to_panel
global MY_OUT_PATH 		${path}\example_output_data
global MY_TEMP_PATH 	${path}\example_temp_data

global censor_prog 		${path}\example_do_files

************* 1.2 Globals defining your data ***************************

************* 1.2.a Globals for spell file ****************************

global spellfile 		"artkalen"				/** Name of spell datafile **/

global s_pid 			persnr					/** Identifier for individuals in spell datafile **/
global spellnr 			spellnr					/** Identifier for spells of each person **/
global spelltype 		spelltyp				/** spelltype of spells which will be used for splitting **/
global spells 			"3 4"					/** Values of Spelltyp for which spells between interviews shall be identified (here for example the values for vocational training. You can choose as much spelltypes you want by putting the according values of the spelltype) **/

global begin 			begin					/** Begin of spells **/
global end 				end						/** End of spells **/
global censor 			zensor					/** Censor-Variable **/

************* 1.2.b Globals for panel file ****************************

global panelfile 			"pl"				/** Name of panel datafile **/
global p_pid 				pid					/** Identifier for individuals in panel datafile **/
global year 				syear				/** Year of interview **/
global variables_panel 		"p_nace pld0131"	/** List of variables of panel datafile **/
global month 				"pmonin"			/** Month of interview **/


************************************************************************
************* 2. Preparation of datasets *******************************
************************************************************************

run ${censor_prog}/Censor_Programs.do /*defines the programs in the Censor_Programs do file. */

************* 2.1 Spell data preparation ******************************
 
use $MY_IN_PATH\\${spellfile}.dta, clear
 
rename ${s_pid} ${p_pid}


sort ${p_pid} ${begin} ${end} ${spelltype} 

gen keep_spells = 0
foreach val of global spells {
	replace keep_spells = 1 if ${spelltype} == `val'
}
keep if keep_spells == 1
 
censor_unfold ${censor}   
// what is this step doing exactly?


 
* all endings of spells must be equal to the beginning of the following
bysort ${p_pid} (${begin} ${end}): replace ${end} = ${end} + 1 if ${end} > 0 

gen duration = ${end} - ${begin} 
*if end or begin of a spell is unknown or missing, the duration of a spell is set as zero month and the spell will not be expanded
replace duration = 0 if ${end} < 0 | ${begin} < 0
expand duration
bysort ${p_pid} ${spellnr} (${begin} ${end}): replace ${begin} = ${begin}[_n-1] + 1 if ${begin}[_n-1] != .
 
replace ${end} = ${begin} + 1

drop duration keep_spells
order ${p_pid} ${begin} ${end} ${spellnr} ${spelltype}
 
save ${MY_TEMP_PATH}\spelldata.dta, replace 
 
 
 
************* 2.2 Panel data preparation ******************************
 

use ${p_pid} ${year} ${month} ${variables_panel} using ${MY_IN_PATH}\\${panelfile}.dta, clear
sort ${p_pid} ${year} 
 
*under the assumption that the spell data is on monthly basis
gen not_valid = 0
replace not_valid = 1 if ${month} < 0
lab var not_valid "Month of interview not valid"
replace ${month} = 2 if ${month} < 0
gen ${begin} = ym(${year}, ${month}) - 275
 
sort ${p_pid} 
 
save ${MY_TEMP_PATH}\paneldata.dta, replace

 
************************************************************************
************* 3. Merging ***********************************************
************************************************************************
 

 
use ${MY_TEMP_PATH}\spelldata.dta, clear
merge m:1 ${p_pid} ${begin} using ${MY_TEMP_PATH}\paneldata.dta

sort ${p_pid} ${begin} ${spellnr} ${spelltype} 
order ${p_pid} ${year} ${begin} ${end} ${spellnr} ${spelltype} ${variables_panel} ${not_valid} 
 
gen year_interview = ${year}
bysort ${p_pid} (${begin} ${end} ${spelltype} ${spellnr}): replace ${year} = ${year}[_n-1] if _n > 1 & ${year} == . & ${year}[_n-1] != .
 
sort ${p_pid} ${begin} ${end} ${spellnr} ${spelltype}

order ${begin} ${end} ${spelltype} ${spellnr} year_interview ${variables_panel} left right org_censor
 
*** adjusting censor variable
bysort ${p_pid} ${spellnr} (${begin} ${end} ${spellnr}): replace right = 0 if _n != _N & _N > 1
bysort ${p_pid} ${spellnr} (${begin} ${end} ${spellnr}): replace left = 0 if _n > 1 & _N > 1
sort ${p_pid} ${begin} ${end} ${spellnr} ${spelltype}

censor_contract org_censor ${censor}

order ${p_pid} ${begin} ${end} ${spelltype} ${spellnr} year_interview ${variables_panel} ${censor} org_censor

 
************************************************************************
************* 4. 4.	Expanding information from panel to spells ********
************************************************************************

************* 4.1 Automatic generation of incidences and durations *****

global between_waves_duration " "
* automatic generation of duration.
foreach val of global spells { 
	gen _help_`val' = ${end} - ${begin} if ${spelltype} == `val' 
	* gen _help_`val' = ${end} - ${begin} if ${spelltype} == `val' &  (org_censor != 4 & org_censor != 5 )   /* if you want to exlude left-censored and left/right spells. Variable org_censor ist the original censor variable and contains the same value for all subspells. In contrast the zesnor variable is already adjusted    */
	
	bysort ${p_pid} ${spelltype} ${year} (${begin} ${end}): replace _help_`val' = _help_`val' + _help_`val'[_n-1] if _n > 1 & ${spelltype} == `val' & ${year} == ${year}[_n-1]
	bysort ${p_pid} (${begin} ${end} ${spelltype}): replace _help_`val' = _help_`val'[_n-1] if ${year} == ${year}[_n-1] & _help_`val' == . 
	 
	bysort ${p_pid} (${begin} ${end} ${spelltype}): gen duration_of_the_state_`val' = _help_`val'[_n-1] if ${year} == ${year}[_n-1]+1 
	lab var duration_of_the_state_`val' "duration of `:label ${spelltype} `val'' between interviews"
	 
	bysort ${p_pid} ${begin} ${end} : egen max_`val' = max(duration_of_the_state_`val') 
	replace duration_of_the_state_`val' = max_`val' if duration_of_the_state_`val' == .
	drop max_`val' _help_`val'
	global between_waves_duration "${between_waves_duration} duration_of_the_state_`val'"
}

 
global between_waves_incidence " "
foreach val of global spells { 
	gen _help_`val' = 1 if ${spelltype} == `val'
	bysort ${p_pid} (${begin} ${end} ${spelltype}): replace _help_`val' = _help_`val'[_n-1] if ${year} == ${year}[_n-1] & _help_`val' == . 
	bysort ${p_pid} (${begin} ${end} ${spelltype}): gen incidence_of_the_state_`val' = _help_`val'[_n-1] if ${year} == ${year}[_n-1]+1 
	lab var incidence_of_the_state_`val' "incidence of `:label ${spelltype} `val'' between interviews"
	 
	bysort ${p_pid} ${begin} ${end} : egen max_`val' = max(incidence_of_the_state_`val') 
	replace incidence_of_the_state_`val' = max_`val' if incidence_of_the_state_`val' == .
	drop max_`val' _help_`val'
	global between_waves_incidence "${between_waves_incidence} incidence_of_the_state_`val'"
}

 
display "${between_waves_incidence} ${between_waves_duration}"
order ${p_pid} ${begin} ${end} ${spelltype} ${spellnr} ${between_waves_incidence} ${between_waves_duration} 


************* 4.2 How to construct your variables (To intervene) *******
 /*
** Incidence of vocational training between interviews 
gen incidence_vocational_tr = 1 if ${spelltype} == 4
gen incidence_part_time    = 1 if ${spelltype} == 3

order ${begin} ${end} ${spelltype} ${spellnr} year_interview ${variables_panel} ${censor} org_censor
 
*** Duration of vocational training and part time employment between interviews taking into account left censoring and left/right cesoring

* first we calculate the duration in given states for each line
* Note in this example we suppress the calculation for  left-censored and left/right censored spells. Variable org_censor ist the original censor variable and contains the same value for all subspells. In contrast the zesnor variable is already adjusted. By puttint proper values for org_censor variable you can    */
capture drop duration_vocational_tr
gen duration_vocational_tr = ${end} - ${begin} if ${spelltype} == 4  &  (org_censor != 4 & org_censor != 5 ) 
capture drop duration_part_time
gen duration_part_time = ${end} - ${begin} if ${spelltype} == 3   &  (org_censor != 4 & org_censor != 5 )
 
* in the second step we summarize duration over the lines.
bysort ${p_pid} ${spelltype} ${year} (${begin} ${end} ${spelltype}): replace duration_vocational_tr = duration_vocational_tr + duration_vocational_tr[_n-1] if _n > 1 & ${spelltype} == 4 & ${year} == ${year}[_n-1]
bysort ${p_pid} ${spelltype} ${year} (${begin} ${end} ${spelltype}): replace duration_part_time = duration_part_time + duration_part_time[_n-1] if _n > 1 & ${spelltype} == 3 & ${year} == ${year}[_n-1]

 

*** How many interruptions for vocational training between interviews 
bysort ${p_pid} ${spelltype} ${year} (${begin} ${end} ${spelltype}): gen interruption_voc_tr_nr = begin != end[_n-1] & _n > 1
order ${p_pid} ${year} ${begin} ${end} ${spellnr} ${spelltype} interruption_voc_tr_nr ${variables_panel} ${not_valid} 

bysort ${p_pid} ${spelltype} ${year} (${begin} ${end} ${spelltype}): replace interruption_voc_tr_nr = interruption_voc_tr_nr + interruption_voc_tr_nr[_n-1] if _n > 1 & ${spelltype} == 4 & ${year} == ${year}[_n-1]
order ${p_pid} ${year} ${begin} ${end} ${spellnr} ${spelltype} interruption_voc_tr_nr ${variables_panel} ${not_valid} 

*** start and end of vocational training in the given year
 bysort ${p_pid} ${spelltype} ${year} (${begin} ${end} ${spelltype}): egen voc_tr_begin= min(${begin} ) if ${spelltype} == 4 
 bysort ${p_pid} ${spelltype} ${year} (${begin} ${end} ${spelltype}): egen voc_tr_end = max(${end} ) if ${spelltype} == 4 
 
*the information of the spelldata between the waves is captured in the variable "between"
global variables_between_interviews "duration_vocational_tr duration_part_time incidence_vocational_tr incidence_part_time voc_tr_begin voc_tr_end interruption_voc_tr_nr"

sort ${p_pid} ${begin} ${end} ${spelltype} ${spelltype}
pause off
foreach var of global variables_between_interviews {
clonevar _help_`var' = `var'
drop `var'
bysort ${p_pid} (${begin} ${end} ${spelltype} ${spelltype}): replace _help_`var' = _help_`var'[_n-1] if ${year} == ${year}[_n-1] & _help_`var' == . 
* order pid ${year} begin end spelltyp _help_duration_vocational_tr 
 pause
bysort ${p_pid} (${begin} ${end} ${spelltype} ${spelltype}): gen `var' = _help_`var'[_n-1] if ${year} == ${year}[_n-1]+1 
pause
* order pid ${year} begin end spelltyp _help_duration_vocational_tr ${variables_between_interviews}
bysort ${p_pid} ${begin} ${end} : egen `var'_max = max(`var') 
 replace `var' = `var'_max if `var' == .
 drop `var'_max
}

 */

 
************************************************************************
************* 5. Reducing to panel data ********************************
************************************************************************

sort ${p_pid} ${begin} ${end} ${year}
display "${between_waves}"
keep if _merge == 2 | _merge == 3 /* keep only those definied by interviews through the panel data */

bysort ${p_pid} ${year} (${begin} ${end}): gen interview_N_sameyear = _n 
keep if interview_N_sameyear == 1 
 
keep ${p_pid} ${year} ${variables_panel} ${variables_between_interviews} ${between_waves_incidence} ${between_waves_duration} 
save $MY_OUT_PATH\fin_spell_to.dta, replace
 
 
 

 

