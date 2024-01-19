
***********************************************************************************************************
***********************************************************************************************************
***	Educational trajectories of students of migrant and non-migrant descent in Germany 	*******************
***********************************************************************************************************
***********************************************************************************************************

set more off 

*current date
local date : di %dDNCY daily("$S_DATE", "DMY")
di "`date'"


* create log file 
capture log close _all 
log using "$LOG\log_01_to_panel_`date'.log", replace


************************************************************************
**# Bookmark  1. Browse the datasets ***********************************
************************************************************************

* Dataset relationship information 
use "$DATA/w6_ylhcp_ge_v6.0.0_rv.dta", clear
describe

* Dataset  with year of birth
use "$DATA/w6_ym_ge_v6.0.0_rv.dta", clear


* Dataset  education and profession 
use "$DATA/w6_ylhcs_ge_v6.0.0_rv.dta", clear
describe

  

 
 
************************************************************************
**# Bookmark  2. Preparation of dataset ********************************
************************************************************************
 
*  add year of birth from the other dataset 
merge m:1 youthid using "$DATA/w6_ym_ge_v6.0.0_rv.dta" , keepusing (y6_doby y6_dobm  y6_sex) keep (match)


* Get months and year information of the interview separately 
gen intdate = dofm(y6_intdat_ylhcsRV)
format intdate %d
gen intmonth=month(intdate)
gen inty=year(intdate) 
drop intdate

* generate an age variable (broad)
gen age = y6_ylhcs_begdaty - y6_doby 
fre age  if y6_ylhcs_index==1  
br if age == 22 & y6_ylhcs_index==1  
fre y6_sample

*clone some variables
clonevar begm  = y6_ylhcs_begdatm
clonevar begy  = y6_ylhcs_begdaty


clonevar endm        = y6_ylhcs_enddatm
clonevar endy        = y6_ylhcs_enddaty

clonevar birthdm     = y6_dobm 
clonevar birthdy     = y6_doby 

clonevar index       = y6_ylhcs_index



** if ongoing, take the date (month) of the interview as month (if month is missing)
br *id y6_ylhcs_index  *m *y *ongoing *correction *tp if endm<0 | begm<0 



//Q: in the variable y6_ylhcs_ongoing  it says sometimes "correction of end date" but I do not know whether they actually corrected the variable and where to find this information  

* see e.g. this person 
br *id y6_ylhcs_index  *m *y *ongoing *correction *tp if youthid== 20140217




* missing/no answer/ don't know but still ongoing --> interviewmonth and interviewyear (kind of censoring)
replace endm  = intmonth if y6_ylhcs_ongoing == 1 & y6_ylhcs_enddatm  < 0  |  y6_ylhcs_enddatm >12 & y6_ylhcs_ongoing == 1 
replace endy  = inty if y6_ylhcs_ongoing == 1 & y6_ylhcs_enddaty  < 0 




tab  y6_ylhcs_enddatm y6_ylhcs_ongoing,m 
tab  y6_ylhcs_enddaty y6_ylhcs_ongoing,m 


* consider missings using 
fre y6_ylhcs_ongoing 
fre y6_ylhcs_tp
fre y6_ylhcs_correction





* replace unspecific information on the month for beginning and ending month set negative answers to missing
global dates "begm endm  begy endy birthdm birthdy"

foreach val of global dates {
recode `val'  (21 = 2 ) (24 = 4 ) (27 = 7) (30 = 9) (32 = 11) (-99 -88 -55 -22 -44 = .)
}



** my idea here is that there are five categories/periods meaning the year is split up into 2,5 months per period so first January- mid March so I always took the month "in the middle" , in this case February (other suggestions are welcome)

/*
        21  beginning of year/winter  --> February
        24  spring                    --> April
        27  mid-year/summer           --> July
        30  autumn                    --> September
        32  end of year				  --> November
*/ 

** another option would be to take the end of the last spell as the beginning of the next but they 


* Change data to century month  //the e_m monthly date (months since 1960m1) corresponding to year Y, month M 

* Beginning of a spell in cm 
gen begincm = ym(begy, begm)
 
 
* End of a spell in cm
gen endcm = ym(endy, endm)

* Year and month of birth in cm  (not sure if this is relevant but more specific than year of birth)
gen birthcm = ym( birthdy, birthdm)


* get the earliest and the latest cm we observe an individual 
egen minbegincm = min(begincm)
egen maxendcm   = max(endcm)

dis  maxendcm -  minbegincm   // 210 


br *id *ongoing* *enddat* *begdat* *cm* begy begm endy endm if youthid== 20040214 & index==5 
br *id  *enddat* *ongoing* *begdat*  begy begm endy endm if youthid== 20040214 & index==5 


br *id  *enddat* *ongoing* *begdat*  begy begm endy endm if youthid== 22018010  & index==1 



unique(youthid)
/*
Number of unique values of youthid is  5074
Number of records is  25008
*/

* Check missings
count if endcm==.
count if begincm==.
count if endcm & begincm==.


 * youthid --> id variable 
 *  y6_ylhcs_begdatm --> beginning of spell (month)
 * y6_ylhcs_begdaty --> beginning of spell (year)
 * y6_ylhcs_enddatm --> end of spell (month)
*  y6_ylhcs_enddaty --> end of spell (year)


* other important variables:
* *_ongoing
* *_correction 
 
************************************************************************
**# Bookmark 3. Globals for spell file   *******************************
************************************************************************
 
*global spellfile 		"artkalen"				/** Name of spell datafile **/

global pid 			    youthid					/** Identifier for individuals in spell datafile **/
global spellnr 			y6_ylhcs_index		    /** Identifier for spells of each person **/
global spelltype 		y6_ylhcs_spt2			/** spelltype of spells which will be used for splitting **/
global spells 			"1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22"					/** Values of Spelltyp for which spells between interviews shall be identified (here for example the values for vocational training. You can choose as much spelltypes you want by putting the according values of the spelltype) **/

global begin 			begincm 					/** Begin of spells **/
global end 				endcm					/** End of spells **/
*global censor 			zensor					/** Censor-Variable **/




sort ${pid} ${begin} ${end} ${spelltype} 
order ${pid} ${begin} ${end} ${spelltype} 



************************************************************************
**# Bookmark 4.   Spell data preparation *******************************
************************************************************************



** if there are certain statuses you want to exclude (remove the value from global spells)
gen keep_spells = 0
foreach val of global spells {
	replace keep_spells = 1 if ${spelltype} == `val'
}


br ${pid} ${begin} ${end} ${spelltype}  keep_spells

fre keep_spells
keep if keep_spells == 1 //all statuses of the variable y6_ylhcs_spt2 kept for now 
 

br ${pid} ${begin} ${end} ${spelltype} *enddat* *begdat*  keep_spells 
order ${pid} ${begin} ${end} ${spelltype} 
br ${pid} ${begin} ${end} ${spelltype} *enddat* *begdat*  keep_spells 

 

* Adjust the endings of all spells to be exclusive (which means the last months is not the last month e.g. in school but the month after (important for duration) 
bysort ${pid} (${begin} ${end}): replace ${end} = ${end} + 1 if ${end} > 0 


* Generate a duration variable (in months)
gen duration = ${end} - ${begin} 
order ${pid} ${begin} ${end} ${spelltype}  duration *ongoing* *enddat* *begdat*  keep_spells 
br ${pid} ${begin} ${end} ${spelltype}  duration *ongoing*  *enddat* *begdat*  keep_spells 

*if beginning or end of a spell is missing, the duration of a spell is set as zero month and the spell will not be expanded
replace duration = 0 if ${end} ==. | ${begin} ==.
replace duration = 0 if duration <0   // there is one spell for which the duration is negative (youthid== 22018010  & index==1), in my opinion, this is a mistake in the data, since mid-year/summer is earlier than october??  --> recoded to 0 

fre duration



* multiply each spell according to its duration 
expand duration


* adjust the beginning of all spells that the duration of each subspell of an original spell amounts to one months 
bysort ${pid} ${spellnr} (${begin} ${end}): replace ${begin} = ${begin}[_n-1] + 1 if ${begin}[_n-1]!= .
 
 
* adjust the ending so that the ending of each subspell equals to the beginning of the next subspell 
replace ${end} = ${begin} + 1


drop duration keep_spells
order ${pid} ${begin} ${end} ${spellnr} ${spelltype}
 
save "$TEMP\spelldata.dta", replace 



 
 
************************************************************************
**# Bookmark 5.   Panel data preparation *******************************
************************************************************************

* Create a "blanco" dataset with youthid and N total observations one can merge the spelldata with 


* Dataset  education and profession 
use "$DATA/w6_ylhcs_ge_v6.0.0_rv.dta", clear


* Define some globals 
global startcm 469  // start date of the earliest time observed (see minbegincm above)
global expansion 211 // whole observation period of the sample (see dis  maxendcm -  minbegincm   // 210  above)


* identify the first spell of each individual (and keep only one row for each individual)
bys youthid (y6_ylhcs_index): gen tag=_n==1

keep if tag ==1 
keep youthid
unique(youthid)
expand ${expansion}    
sort youthid

gen begincm= ${startcm}


* create a month starting from the first month anyone was observed and ending with the last month anyone was observed 
bysort ${pid}  (${begin} ): replace ${begin} = ${begin}[_n-1] + 1 if ${begin}[_n-1]!= .

gen endcm= 0
* adjust the ending so that the ending of each subspell equals to the beginning of the next subspell 
replace ${end} = ${begin} + 1


save "$TEMP\paneldata.dta", replace



************************************************************************
**# Bookmark 6.   Merging    *******************************************
************************************************************************

use "$TEMP\spelldata.dta", clear  

**REMOVE??? 
* generate a variable for each possible value of ${spelltype}  (22 values)
forvalues i = 1(1)22 {
clonevar educ`i' =  ${spelltype}  if ${spelltype} ==`i'
 display `i'
}



forvalues i = 1(1)17 {
	use "$TEMP\spelldata.dta", clear  
	keep if index==`i'
	save "$TEMP\spelldata_`i'.dta", replace
 display `i'
}


use  "$TEMP\paneldata.dta", clear 


forvalues i = 1(1)17 {
merge 1:1 ${pid} ${begin}  using "$TEMP\spelldata_`i'.dta", keepusing educ1 educ2 educ3 educ4 educ5 educ6 educ7 educ8 educ9 educ11 educ12 educ13 educ14 educ15 educ16 educ17 educ18 educ19 educ20 educ21 educ22gen(mergepanel`i')
display `i'
}


merge m:1 youthid using "$DATA/w6_ym_ge_v6.0.0_rv.dta" , keepusing (y6_doby y6_dobm  y6_sex) keep (match)




* drop temporary datasets spelldata_* 

save "$TEMP\spelldata_`i'.dta", replace


fre  ${spelltype} 








* Loop over because there may be duplicates 
duplicates report  ${pid}  ${spelltype} 
 
duplicates report  ${pid}  ${begin} 


 keep(1 3)



 
use ${MY_TEMP_PATH}\spelldata.dta, clear
merge m:1 ${p_pid} ${begin} using ${MY_TEMP_PATH}\paneldata.dta



describe


br youthid y6_ylhcs_index tag 


