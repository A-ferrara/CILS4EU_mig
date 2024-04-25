
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
log using "$LOG\log_01_to_panel_`date'_$researcher.log", replace


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

 
order  *id   y6_ylhcs_index y6_s1_sit2a *dat* y6_ylhcs_spt2  y6_ylhcs_spt1
br *id   y6_ylhcs_index y6_s1_sit2a *dat* y6_ylhcs_spt2  y6_ylhcs_spt1

  

 
 
************************************************************************
**# Bookmark  2. Preparation of dataset ********************************
************************************************************************

* Dataset  education and profession
use "$DATA/w6_ylhcs_ge_v6.0.0_rv.dta", clear

 
*  add year of birth from the other dataset 
merge m:1 youthid using "$DATA/w6_ym_ge_v6.0.0_rv.dta" , keepusing (y6_doby y6_dobm  y6_sex) keep (match)


* Get months and year of the interview separately 
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



* Extract value labels
levelsof y6_s1_sit2a, local(values) clean
label list y6_s1_sit2a


levelsof  y6_s2_sit2b ,  local(values) clean
label list y6_s2_sit2b 


levelsof  y6_ylhcs_spt2 ,  local(values) clean
label list y6_ylhcs_spt2



* Educational spells

// Create a variable for the educational spells including : y6_s1_sit2a (detailed info on school),  y6_ylhcs_spt2 (other things such employment,..), y6_s2_sit2b (second chance education )


gen spelltype = .
* Lower secondary
replace spelltype = 1 if y6_s1_sit2a == 1 | y6_s1_sit2a == 14
replace spelltype = 1 if y6_s1_sit2a == -77 & inlist(y6_ylhcs_spt2, 4, 5, 8, 9)
replace spelltype = 1 if y6_ylhcs_spt2 == 2 & inlist(y6_s2_sit2b, 1, 6, 7, 8)
* Intermediate secondary 
replace spelltype = 2 if inlist(y6_s1_sit2a, 2, 3, 6, 7, 8, 9, 12, 13, 15)
replace spelltype = 2 if y6_ylhcs_spt2 == 2 & y6_s2_sit2b == 2
* Upper secondary 
replace spelltype = 3 if inlist(y6_s1_sit2a, 4, 5, 11, 16)
replace spelltype = 3 if y6_ylhcs_spt2 == 2 & inlist(y6_s2_sit2b, 3, 9, 11, 12, 13, 14)
* Tertiary
replace spelltype = 4 if y6_s1_sit2a == -77 & y6_ylhcs_spt2 == 7
* Other 
replace spelltype = 5 if inlist(y6_s1_sit2a, 10, 17)
replace spelltype = 5 if y6_s1_sit2a == -77 & y6_ylhcs_spt2 == 6 
replace spelltype = 5 if y6_ylhcs_spt2 == 2 & inlist(y6_s2_sit2b, 4, 5, 10, 15)
* Apprenticeship
replace spelltype = 6 if y6_s1_sit2a == -77 & y6_ylhcs_spt2 == 3
* Employment 
replace spelltype = 7 if y6_s1_sit2a == -77 & inrange(y6_ylhcs_spt2, 10, 17)
* Out of employment 
replace spelltype = 8 if y6_s1_sit2a == -77 & inrange(y6_ylhcs_spt2, 18, 22)


label define spelltype 1 "Lower secondary" 2 "Intermediate secondary" 3 "Upper secondary" 4 "Tertiary" 5 "Other" 6 "Apprenticeship" 7 "Employment" 8 "Out of employment"
label values spelltype spelltype 


tab spelltype y6_s1_sit2a, m  
tab spelltype y6_s2_sit2b, m 
tab spelltype y6_ylhcs_spt2, m 


// it seems as if don't know and no answer in y6_s1_sit2a,is general education or second chance (see y6_ylhcs_spt2), so I'd recode the missings in spelltype to 'other'

replace spelltype = 5 if spelltype ==. 



* Generate a robustness-check variable for educational spells 


gen robtype = .
* Lower secondary
replace robtype = 1 if y6_s1_sit2a == 1 
replace robtype = 1 if y6_s1_sit2a == -77 & inlist(y6_ylhcs_spt2, 4, 5, 8, 9)
replace robtype = 1 if y6_ylhcs_spt2 == 2 & inlist(y6_s2_sit2b, 1, 6, 7, 8)
* Intermediate secondary 
replace robtype = 2 if inlist(y6_s1_sit2a, 2, 3, 6, 7, 8, 9)
replace robtype = 2 if y6_ylhcs_spt2 == 2 & y6_s2_sit2b == 2
* Upper secondary 
replace robtype = 3 if inlist(y6_s1_sit2a, 4, 5)
replace robtype = 3 if y6_ylhcs_spt2 == 2 & inlist(y6_s2_sit2b, 3, 9, 11, 12, 13, 14)
* Tertiary
replace robtype = 4 if y6_s1_sit2a == -77 & y6_ylhcs_spt2 == 7
* Other 
replace robtype = 5 if inlist(y6_s1_sit2a, 10, 17)
replace robtype = 5 if y6_s1_sit2a == -77 & y6_ylhcs_spt2 == 6 
replace robtype = 5 if y6_ylhcs_spt2 == 2 & inlist(y6_s2_sit2b, 4, 5, 10, 15)
* Apprenticeship
replace robtype = 6 if y6_s1_sit2a == -77 & y6_ylhcs_spt2 == 3
* Employment 
replace robtype = 7 if y6_s1_sit2a == -77 & inrange(y6_ylhcs_spt2, 10, 17)
* Out of employment 
replace robtype = 8 if y6_s1_sit2a == -77 & inrange(y6_ylhcs_spt2, 18, 22)
* Combined 
replace robtype = 9 if inrange(y6_s1_sit2a, 11, 16)

label define robtype 1 "Lower secondary" 2 "Intermediate secondary" 3 "Upper secondary" 4 "Tertiary" 5 "Other" 6 "Apprenticeship" 7 "Employment" 8 "Out of employment" 9 "Combined" , modify 
label values robtype robtype 


tab robtype y6_s1_sit2a, m  
tab robtype y6_s2_sit2b, m 
tab robtype y6_ylhcs_spt2, m 


// it seems as if don't know and no answer in y6_s1_sit2a, is general education or second chance (see y6_ylhcs_spt2), so I'd recode the missings in spelltype to 'other'
replace robtype  = 5 if robtype ==. 



tab robtype spelltype, m 
tab spelltype y6_s1_sit2a



** if ongoing, take the date (month) of the interview as month (if month is missing)
br *id y6_ylhcs_index  *m *y *ongoing *correction *tp if endm<0 | begm<0 

//Q: in the variable y6_ylhcs_ongoing  it says sometimes "correction of end date" but I do not know whether they actually corrected the variable and where to find this information??  

* see e.g. this person 
br *id y6_ylhcs_index  *m *y *ongoing *correction *tp if youthid== 20140217


* missing/no answer/ don't know but still ongoing --> interviewmonth and interviewyear (kind of censoring)
replace endm  = intmonth if y6_ylhcs_ongoing == 1 & y6_ylhcs_enddatm  < 0  |  y6_ylhcs_enddatm >12 & y6_ylhcs_ongoing == 1 
replace endy  = inty if y6_ylhcs_ongoing == 1 & y6_ylhcs_enddaty  < 0 


* consider missings using 
fre y6_ylhcs_ongoing 
fre y6_ylhcs_tp
fre y6_ylhcs_correction


* replace unspecific information on the month for beginning and ending month and set to missing
global dates "begm endm  begy endy birthdm birthdy"

foreach val of global dates {
recode `val'  (21 = 2 ) (24 = 4 ) (27 = 7) (30 = 9) (32 = 11) (-99 -88 -55 -22 -44 = .)
}


//  my idea here is that there are five categories/periods meaning the year is split up into 2,5 months per period so first January- mid March so I always took the month "in the middle" , in this case February (other suggestions for coding are welcome!)

/*
        21  beginning of year/winter  --> February
        24  spring                    --> April
        27  mid-year/summer           --> July
        30  autumn                    --> September
        32  end of year				  --> November
*/ 

** another option would be to take the end of the last spell as the beginning of the next.... ? but there may (I did actually not check yet) be gaps between spells??  


* Change data to century month  //the e_m monthly date (months since 1960m1) corresponding to year Y, month M 

* Beginning of a spell in cm 
gen begincm = ym(begy, begm)
 
* End of a spell in cm
gen endcm = ym(endy, endm)

* Year and month of birth in cm  (not sure if this is relevant but more specific than year of birth)
gen birthcm = ym( birthdy, birthdm)

* get the earliest and the latest cm we observe an individual (that is the range of our observations (in months))
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


************************************************************************
**# Bookmark 3. Globals for spell data preparation   *******************
************************************************************************
 

global pid 			    youthid					/** Identifier for individuals in spell datafile **/
global spellnr 			y6_ylhcs_index		    /** Identifier for spells of each person **/
global spelltype 		spelltype		     	/** spelltype of spells which will be used for splitting **/
global spells 			"1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 "	 /** Spells: values of variable spelltype (see creation above)  **/
global begin 			begincm 			    /** Begin of spells **/
global end 				endcm					/** End of spells **/


sort ${pid} ${begin} ${end} ${spelltype} 
order ${pid} ${begin} ${end} ${spelltype} 



************************************************************************
**# Bookmark 4.   Spell data preparation *******************************
************************************************************************


* Adjust the endings of all spells to be exclusive (which means the last months is not the last month e.g. in school but the month after (important for duration)) 
bysort ${pid} (${begin} ${end}): replace ${end} = ${end} + 1 if ${end} > 0 


* Generate a duration variable (in months)
gen duration = ${end} - ${begin} 
order ${pid} ${begin} ${end} ${spelltype}  duration *ongoing* *enddat* *begdat* 
br ${pid} ${begin} ${end} ${spelltype}  duration *ongoing*  *enddat* *begdat*  

*if beginning or end of a spell is missing, the duration of a spell is set as zero month and the spell will not be expanded
replace duration = 0 if ${end} ==. | ${begin} ==.
replace duration = 0 if duration <0   // there is one spell for which the duration is negative (youthid== 22018010  & index==1), in my opinion, this is a mistake in the data, since mid-year/summer is earlier than october??  --> recoded to 0 

fre duration

* multiply/expand each spell according to its duration 
expand duration


* adjust the beginning of all spells that the duration of each subspell of an original spell amounts to one months 
bysort ${pid} ${spellnr} (${begin} ${end}): replace ${begin} = ${begin}[_n-1] + 1 if ${begin}[_n-1]!= .
 
* adjust the ending so that the ending of each subspell equals to the beginning of the next subspell 
replace ${end} = ${begin} + 1 if ${begin}!=. 


drop duration 
order ${pid} ${begin} ${end} ${spellnr} ${spelltype}
 
save "$TEMP\spelldata.dta", replace 



************************************************************************
**# Bookmark 5.  Panel data preparation  *******************************
************************************************************************

* Create a "blanco" dataset with youthid and N total observations (see dis  maxendcm -  minbegincm) to merge the spelldata with 

* Dataset  education and profession 
use "$DATA/w6_ylhcs_ge_v6.0.0_rv.dta", clear


* Define some globals 
global startcm 469  // start date of the earliest time observed (see minbegincm above)
global expansion 211 // whole observation period of the sample (see dis  maxendcm -  minbegincm   // 210  above (I made 211 just to be sure))


* identify the first spell of each individual (tag =1 ) 
bys ${pid}(y6_ylhcs_index): gen tag= _n ==1

* keep only one row for each individual
keep if tag ==1 
keep ${pid} 
unique(${pid})
expand ${expansion}    
sort ${pid} 

gen begincm= ${startcm}


* create a month starting from the first month anyone was observed and ending with the last month anyone was observed (practically like code above)
bysort ${pid}  (${begin} ): replace ${begin} = ${begin}[_n-1] + 1 if ${begin}[_n-1]!= .

gen endcm= 0
* adjust the ending so that the ending of each subspell equals to the beginning of the next subspell 
replace ${end} = ${begin} + 1 if ${begin}!=. 


save "$TEMP\paneldata.dta", replace



************************************************************************
**# Bookmark 6.   Merging    *******************************************
************************************************************************

use "$TEMP\spelldata.dta", clear  


** Generate a variable indicating the educational/spelltype status for each index/spell (in this case total 17 = (max)y6_ylhcs_index))
* generate a variable for each possible value of ${spelltype}  (22 values)
forvalues i = 1(1)17 {
clonevar spell_edu`i' =  ${spelltype}  if index ==`i'
 display `i'
}


save "$TEMP\spelldata_short.dta", replace 


** here, I create one separate dataset for each spell (because sometimes spells overlap which means merge doesn't work if we'd do it with the complete dataset)
forvalues i = 1(1)17 {
	use "$TEMP\spelldata_short.dta", clear  
	keep if index==`i'
	keep youthid begincm endcm birthcm index  spell_edu`i'		 // add here any variables you'd want to keep from the spelldataset 
	clonevar index`i' =  index
	drop index
	save "$TEMP\spelldata_`i'.dta", replace
 display `i'
}


use  "$TEMP\paneldata.dta", clear 

* merge each separate spell dataset to the 'blanco' dataset created above
forvalues i = 1(1)17 {
merge 1:1 ${pid} ${begin}  using "$TEMP\spelldata_`i'.dta", gen(mergepanel`i')
display `i'
}


order ${pid}  ${begin}  ${end} spell_edu* merge* 
br
br if  ${begin}  ==. 


* create a variable to see how many spells match with a cm info (could be >1 if spells overlap)
egen matched = anycount(mergepanel1- mergepanel17), values(3)  
br ${pid}  ${begin}  ${end} spell_edu* merge* matched 


* drop if we have no information on a spell during that month 
drop if matched == 0
drop index* mergepanel* 


* make sure to have no duplicates (not several rows with the same starting month)
unique(${pid}  ${begin})
duplicates report  ${pid}  


* Add some time variables (for the year and months of spell) 
clonevar dm = ${begin}  
* to year and month data 
format %tm dm
format dm %10.0g
gen date = dofm(dm)

format date %d
gen month=month(date)
gen yr=year(date)


drop date
rename dm date 
format %tm date


* Add some time variables (for the year and months of birthday) 
egen birthmax = max(birthcm), by(${pid})
drop birthcm 
rename birthmax birthcm 

clonevar  dm = birthcm 
* to year and month data 
format %tm dm
format dm %10.0g
gen birthdate = dofm(dm)

format birthdate %d
gen birthmonth=month(birthdate)
gen birthyr=year(birthdate)

drop birthdate
rename dm birthdate 
format %tm birthdate


* Add information on the age 

gen agecm = begincm - birthcm

*age in years with decimals
gen age = agecm/12 
gen dismonth= age- (yr- birthyr)
replace dismonth = age+1 - (yr- birthyr) if month < birthmonth //for people where the calculation above doesn't work because the months reported is before their birthday in that year 
gen dismonth_new = dismonth*12

*age in months (rounded)
gen age_month = round(dismonth_new ,0.01)

*age in years (full numbers)
gen age_year = age - dismonth 


drop dismonth* 


order ${pid}  ${begin}  ${end}  spell_edu* matched date yr month birthcm birthd* birthy* birthm* agecm age age_y* age_m* 


* Generate time and age of first observation per individual
bysort youthid: egen frst_month = min(begincm)
bysort youthid: egen frst_year = min(yr)
bysort youthid: egen frst_age = min(age)

* Checking first age - most have age 10, which makes sense
kdensity frst_age

* Question: what to do with the others?
gen frst_age_flag = frst_age < 7
replace frst_age_flag = 2 if frst_age >15
label define flag 0 "Normal first age" 1 "Below 7" 2 "Above 15", replace
label values frst_age_flag flag


* Checking what they are doing
ta spell_edu1 frst_age_flag, col
ta spell_edu1 if frst_age_flag==1 // more likely to be in Rudolf Steiner school
ta spell_edu1 if frst_age_flag==2 // more likely to be in an apprenticeship




save "$TEMP\educ.dta", replace 
use "$TEMP\educ.dta", clear



************************************************************************
**# Bookmark 7. Set time frame  ****************************************
************************************************************************




* Generate cm for all novembers from 2004-2009, 2013-2019

// https://www.calculator.net/age-calculator.html


forval year = 2004/2012 {
    gen nov_`year' = ym(`year',11)
}


* Set the cm start for each individual depending on when they were born 
// criteria: They should be 12 until June of the calendar (before entering the school year in september, this is following the logic of )


gen start = .
replace start = nov_2006 if birthyr == 1992  & birthmonth <= 6 
replace start = nov_2007 if birthyr == 1992  & birthmonth > 6

replace start = nov_2007 if birthyr == 1993  & birthmonth <= 6 
replace start = nov_2008 if birthyr == 1993  & birthmonth > 6

replace start = nov_2008 if birthyr == 1994  & birthmonth <= 6 
replace start = nov_2009 if birthyr == 1994  & birthmonth > 6

replace start = nov_2009 if birthyr == 1995  & birthmonth <= 6 
replace start = nov_2010 if birthyr == 1995  & birthmonth > 6

replace start = nov_2010 if birthyr == 1996  & birthmonth <= 6 
replace start = nov_2011 if birthyr == 1996  & birthmonth > 6

replace start = nov_2011 if birthyr == 1997  & birthmonth <= 6
replace start = nov_2012 if birthyr == 1997  & birthmonth > 6

tab age if start == begincm, miss
label variable start "Grade-specific (age before Nov) start of trajectory"


br youthid begincm endcm nov_* start birthyr birthmonth age 
br if age >13 & start == begincm

br  youthid begincm endcm nov_* start birthyr birthmonth age  if youthid==  20010214

tab age if start == begincm
histogram age if start == begincm



* Generating the end date

forval year = 2013/2020 {
    gen nov_`year' = ym(`year',11)
}




* Set the end date of each individual as well (november again)  (WHAT AGE?? )


gen end = .
replace end = nov_2011 if birthyr == 1992  & birthmonth <= 6 
replace end = nov_2012 if birthyr == 1992  & birthmonth > 6

replace end = nov_2012 if birthyr == 1993  & birthmonth <= 6 
replace end = nov_2013 if birthyr == 1993  & birthmonth > 6

replace end = nov_2013 if birthyr == 1994  & birthmonth <= 6 
replace end = nov_2014 if birthyr == 1994  & birthmonth > 6

replace end = nov_2014 if birthyr == 1995  & birthmonth <= 6 
replace end = nov_2015 if birthyr == 1995  & birthmonth > 6

replace end = nov_2015 if birthyr == 1996  & birthmonth <= 6 
replace end = nov_2016 if birthyr == 1996  & birthmonth > 6

replace end = nov_2016 if birthyr == 1997  & birthmonth <= 6
replace end = nov_2017 if birthyr == 1997  & birthmonth > 6

label variable end "Grade-specific (age before Nov) end of trajectory"
tab age if end == begincm, miss


tab age if end == begincm
histogram age if end == begincm


** create one spell for each individual, if overlapping give preference to educational spells
// There is a bit of an age range since we check the age until June and then start in November 

* Drop observations before the start date
bysort youthid: drop if begincm < start


* Drop observations after the end date 
*bysort youthid: drop if begincm > end


* identify the first observation 
egen min_begincm = min(begincm), by(youthid)


bysort youthid: gen tag1 = 1 if _n==1

* calculate the number of rows missing (until start)
gen missing_start =   min_begincm+1 - start   if tag1 == 1 





* expand the number of rows missing in the beginning 
expand missing_start 
sort youthid begincm 

br if youthid == 20020204
bysort youthid : gen tag2 = 1  if youthid == youthid[_n+1] & tag1 ==1 & tag1[_n+1] ==.


* replace begincm 
sort youthid begincm 
br youthid begincm endcm tag1 tag2 missing_start start 


* adjust begincm for the missing information 
forvalues i = 1/150 {
    replace begincm = begincm[_n+`i'] -`i' if begincm[_n+`i'] != . & tag1 == tag1[_n+`i'] & youthid == youthid[_n+`i'] & tag2[_n+`i'] == 1 
}


br youthid begincm endcm tag1 tag2 missing_start start  if youthid == 20020204
br youthid begincm endcm tag1 tag2 missing_start start 


replace endcm = begincm +1 if begincm!=. 




* identify the last observation in cm 
egen max_endcm = max(begincm), by(youthid)

* tag the last observation 
bysort youthid : gen tag3 = 1 if (_n == _N)

* calculate the number of rows missing (until end)
gen missing_end =   end - max_endcm    if tag3 == 1 


* recode to missing (if we have much longer information than we actually would like to have)
replace missing_end = . if    missing_end <0 



fre missing_end if tag3==1 

br if missing_end==. & tag3==1 

* expand the number of rows missing in the end
expand missing_end
sort youthid begincm 

* check for each birth cohort the ascribed end date and the actual end date 
bysort birthyr: tab max_endcm end, m







br youthid begincm endcm tag1 tag2 tag3  missing_* start end

* adjust begincm for the missing information 
replace begincm = begincm[_n-1] + 1 if begincm[_n-1]!= . & tag3 == tag3[_n-1] & youthid == youthid[_n-1] & tag3 ==1 
replace endcm = begincm +1 if begincm!=. 


bysort youthid : gen tag4 = 1  if youthid == youthid[_n-1] & tag3 ==1 & tag3[_n-1] ==.



* double-check if the expansion worked
sort youthid begincm 
egen max_endcm_new = max(begincm), by(youthid)
tab end birthyr, m
bysort birthyr: tab max_endcm max_endcm_new, m





** until here: check why there are still some missing observations at the end??





* Redo the variable on age, month, etc
capture drop  date month yr age_year age_month  age agecm 


* Add some time variables (for the year and months of spell) 
clonevar dm = begincm 
* to year and month data 
format %tm dm
format dm %10.0g
gen date = dofm(dm)

format date %d
gen month=month(date)
gen yr=year(date)


drop date
rename dm date 
format %tm date


* Add information on the age 

gen agecm = begincm - birthcm

*age in years with decimals
gen age = agecm/12 
gen dismonth= age- (yr- birthyr)
replace dismonth = age+1 - (yr- birthyr) if month < birthmonth //for people where the calculation above doesn't work because the months reported is before their birthday in that year 
gen dismonth_new = dismonth*12

*age in months (rounded)
gen age_month = round(dismonth_new ,0.01)

*age in years (full numbers)
gen age_year = age - dismonth 


br youthid begincm endcm tag1 tag2 missing_start start yr month date age_year  if youthid == 20020204

* Check the spelltype variable



br youthid begincm endcm *spell_* 


gen spell = . 


sort spell_edu* 
egen spell_edu = rowmax(spell_edu1 - spell_edu17)


* check if spells are overlapping and how many are 
egen spell_N = rownonmiss(spell_edu1 - spell_edu17)


* check if any variable is equal to any integer value
egen spell_edu_test = anymatch(spell_edu1 - spell_edu17), values(4)




* Generate a new variable spell_edu with prioritization

/*

*** Priority of spells:
4- Tertiary
3- Upper secondary
2- Intermediate secondary 
1- lower education
5- other
6- Apprenticeship
7- employment
8- out of employment 
*/ 

cap drop edu_spell
gen edu_spell = .

global  spell_edu_vars  "spell_edu1 spell_edu2 spell_edu3 spell_edu4 spell_edu5 spell_edu6 spell_edu7 spell_edu8 spell_edu9 spell_edu10                  spell_edu11 spell_edu12 spell_edu13 spell_edu14 spell_edu15 spell_edu16 spell_edu17"

foreach var of global spell_edu_vars {
    replace spell_edu = 4 if `var' == 4
}

foreach var of global spell_edu_vars {	
	replace spell_edu = 3 if spell_edu==. & `var' == 3
}

foreach var of global spell_edu_vars {	
	replace spell_edu = 2 if spell_edu==. & `var' == 2
}

foreach var of global spell_edu_vars {	
	replace spell_edu = 1 if spell_edu==. & `var' == 1
}

foreach var of global spell_edu_vars {	
	replace spell_edu = 5 if spell_edu==. & `var' == 5
}

foreach var of global spell_edu_vars {	
	replace spell_edu = 6 if spell_edu==. & `var' == 6
}

foreach var of global spell_edu_vars {	
	replace spell_edu = 7 if spell_edu==. & `var' == 7
}

foreach var of global spell_edu_vars {	
	replace spell_edu = 8 if spell_edu==. & `var' == 8
}

sort youthid begincm

* replace the gap fillers (until start and end date) with missing (are filled right now because of the expand code)
replace spell_edu = 9 if tag3==1 & tag4!=1 
replace spell_edu = 9 if tag1==1 & tag2!=1 

label define spell_edu 1 "Lower secondary" 2 "Intermediate secondary" 3 "Upper secondary" 4 "Tertiary" 5 "Other" 6 "Apprenticeship" 7 "Employment" 8 "Out of employment" 9 "Missing ", modify 
label values spell_edu spell_edu 



br youthid begincm endcm *spell_*  if spell_N>1 

br youthid begincm endcm spell_edu 



tab spell_edu ,m 

bysort begincm: tab spell_edu ,m 


* Generate a variable if any information on education are missing 
gen missing = 0
replace missing = 1 if  spell_edu == 9




* Change the time frame to grademonth (time focuses now on the grade and not on the cmonth)

sort youthid begincm
egen grade_month = seq(), from(1) by (youthid)

label variable grade_month "Months starting from November in Grade 9"

** grademonth= 1 is equivalent to November of the year, in which the pupil turned 14 until the end of June 
tab age if grade_month==1

/*

        age |      Freq.     Percent        Cum.
------------+-----------------------------------
   14.41667 |        393        7.82        7.82
       14.5 |        445        8.85       16.67
   14.58333 |        369        7.34       24.01
   14.66667 |        432        8.59       32.60
      14.75 |        381        7.58       40.18
   14.83333 |        423        8.41       48.59
   14.91667 |        426        8.47       57.06
         15 |        388        7.72       64.78
   15.08333 |        428        8.51       73.29
   15.16667 |        442        8.79       82.08
      15.25 |        436        8.67       90.75
   15.33333 |        465        9.25      100.00
------------+-----------------------------------
      Total |      5,028      100.00

*/ 

*  Generate a sequence of numbers for every second row
egen grade_bimonth = seq(), block(2) by (youthid)
by youthid: replace grade_bimonth = . if grade_bimonth[_n-1]== grade_bimonth


label variable grade_bimonth "Every second months starting from November in Grade 9"



egen grade= seq(), block(12) by (youthid)
replace grade= grade+8
* note: this would assume that the school years starts in November which it doesn't really, but the start of the school year is around August/September (depending on the year and the state)


* make sure to have spell_edu information on every second month 


save "$TEMP\educ2.dta", replace 
use "$TEMP\educ2.dta", clear

fre spell_edu

clonevar educationalspell = spell_edu

bysort youthid begincm: replace spell_edu =  spell_edu[_n+1] if spell_edu == 9 & spell_edu[_n+1]!= 9 & grade_bimonth!=. & _n>1
replace spell_edu = spell_edu[_n+1] if spell_edu==. 
br youthid spell_edu *grade* educational* 
br youthid spell_edu *grade* educational* if educationalspell != spell_edu 
br youthid spell_edu *grade* educational*   if youthid==20090113
count if educationalspell != spell_edu 


*drop every second row 

drop if grade_bimonth ==. 



* Some descriptive statistics 
tab   grade_bimonth  spell_edu , matcell(table)  matrow(names)  m
putexcel set "$DESC\Educationalspells", modify sheet("Overall") 
putexcel B1 = matrix(table), names hcenter
putexcel B2 = matrix(names)

putexcel B1 = "Bimonthly"
putexcel C1 = "Lower secondary"
putexcel D1 = "Intermediate secondary "
putexcel E1 = "Upper secondary"
putexcel F1 = "Tertiary"
putexcel G1 = "Other"
putexcel H1 = "Apprenticeship"
putexcel I1 = "Employment"
putexcel J1 = "Out of employment "
putexcel K1 = "Missing"
putexcel L1 = "SUM"


putexcel M1 = "Percentages"
putexcel N1 = "Lower secondary"
putexcel O1 = "Intermediate secondary "
putexcel P1 = "Upper secondary"
putexcel Q1 = "Tertiary"
putexcel R1 = "Other"
putexcel S1 = "Apprenticeship"
putexcel T1 = "Employment"
putexcel U1 = "Out of employment "
putexcel V1 = "Missing"
putexcel W1 = "SUM"
putexcel X1 = "Missing of max observations"
putexcel Z1 = "Max observations"

forvalues j = 2/34 {
    putexcel L`j' = formula(=SUM(C`j':K`j'))
	putexcel N`j' = formula(=C`j'/L`j')
	putexcel O`j' = formula(=D`j'/L`j')
    putexcel P`j' = formula(=E`j'/L`j')
    putexcel Q`j' = formula(=F`j'/L`j')
    putexcel R`j' = formula(=G`j'/L`j')
    putexcel S`j' = formula(=H`j'/L`j')
    putexcel T`j' = formula(=I`j'/L`j')
    putexcel U`j' = formula(=J`j'/L`j')
    putexcel V`j' = formula(=K`j'/L`j')
    putexcel W`j' = formula(=SUM(N`j':V`j'))
	putexcel Z2   = formula(=MAX(L2:L32)) 
	putexcel X`j' = formula(=L`j'/Z2)
}




** Missing patterns by birth cohorts and century months  

* 1993 1994 1995 1996 1997 1998

local years "1992 1994 1995 1996 1997 1998 "

foreach year in `years' {
    * Tabulate missing data by birth year
    quietly tab   grade_bimonth  spell_edu if birthyr == `year',  matcell(table)  matrow(names)  m
    putexcel set "$DESC\Educationalspells", modify sheet("Birthyr`year'")
	putexcel B1 = matrix(table), names hcenter
    putexcel B2 = matrix(names)
	
	putexcel B1 = "Bimonthly"
	putexcel C1 = "Lower secondary"
	putexcel D1 = "Intermediate secondary "
	putexcel E1 = "Upper secondary"
	putexcel F1 = "Tertiary"
	putexcel G1 = "Other"
	putexcel H1 = "Apprenticeship"
	putexcel I1 = "Employment"
	putexcel J1 = "Out of employment "
	putexcel K1 = "Missing"
	putexcel L1 = "SUM"


	putexcel M1 = "Percentages"
	putexcel N1 = "Lower secondary"
	putexcel O1 = "Intermediate secondary "
	putexcel P1 = "Upper secondary"
	putexcel Q1 = "Tertiary"
	putexcel R1 = "Other"
	putexcel S1 = "Apprenticeship"
	putexcel T1 = "Employment"
	putexcel U1 = "Out of employment "
	putexcel V1 = "Missing"
	putexcel W1 = "SUM"
	putexcel X1 = "Missing of max observations"
	putexcel Z1 = "Max observations"

forvalues j = 2/32 {
    putexcel L`j' = formula(=SUM(C`j':K`j'))
	putexcel N`j' = formula(=C`j'/L`j')
	putexcel O`j' = formula(=D`j'/L`j')
    putexcel P`j' = formula(=E`j'/L`j')
    putexcel Q`j' = formula(=F`j'/L`j')
    putexcel R`j' = formula(=G`j'/L`j')
    putexcel S`j' = formula(=H`j'/L`j')
    putexcel T`j' = formula(=I`j'/L`j')
    putexcel U`j' = formula(=J`j'/L`j')
    putexcel V`j' = formula(=K`j'/L`j')
    putexcel W`j' = formula(=SUM(N`j':V`j'))
	putexcel Z2   = formula(=MAX(L2:L32)) 
	putexcel X`j' = formula(=L`j'/Z2)
}

}




egen maxgrade_bimonth  =max(grade_bimonth), by (youthid)
fre maxgrade_bimonth

br youthid begincm spell_edu age* yr *grade* if maxgrade_bimonth < 29 & birthyr == 1994

tab age if birthyr == 1994

sum age if grade_bimonth ==1 , det 
sum age if grade_bimonth ==30 , det 



* do this for each cohort 


tab   grade_bimonth  grade , matcell(table)  matrow(names)  m

tab   grade_bimonth  grade , matcell(table)  matrow(names)  m


tab spell_edu if grade_bimonth==1 , sort  




* Calculate the number of month individuals spend in each educational state 

forvalues j = 1/9 {
cap drop count_edu`j'
egen count_edu`j' = total(spell_edu == `j'), by(youthid)
tab count_edu`j'
} 

label variable count_edu1 "N months in Lower secondary"
label variable count_edu2 "N months in Intermediate secondary"
label variable count_edu3 "N months in Upper secondary"
label variable count_edu4 "N months in Tertiary"
label variable count_edu5 "N months in Other"
label variable count_edu6 "N months in Apprenticeship"
label variable count_edu7 "N months in Employment"
label variable count_edu8 "N months in Out of employment"
label variable count_edu9 "N months in Missing"




************************************************************************
**# Bookmark 7. Investigate time series data   *************************
************************************************************************


* Declare data to be time series 
tsset youthid begincm 
tsspell spell_edu


// Sort the data by 'youthid' and 'begincm'
sort youthid begincm

// Generate a new variable 'row_number' that represents the row number within each individual
egen row_number = seq(), by(youthid)




* length of the sequences for each sequence 
tab _seq if _end ==1 

sum _seq if _end ==1, det 


/*
 sum _seq if _end ==1, det 

                            _seq
-------------------------------------------------------------
      Percentiles      Smallest
 1%            1              1
 5%            1              1
10%            2              1       Obs              24,281
25%            4              1       Sum of wgt.      24,281

50%           12                      Mean           19.91125
                        Largest       Std. dev.       20.4282
75%           32             97
90%           51             97       Variance       417.3114
95%           68             97       Skewness       1.284021
99%           80             97       Kurtosis       3.827183

*/ 


** -- > on average, each sequence lasts around 20 months, with a minimum of 1 and a maximum of 97 months 

egen meansequence = mean(_seq), by(youthid)
label variable meansequence  "Mean sequence length per individual"


* longest and shortest consecutive sequence for each individual (in months)

egen max_sequence = max(_seq), by(youthid)
egen min_sequence = min(_seq), by(youthid)


* type of longest and shortest consecutive sequence for each individual 

gen max_eduspell = spell_edu if max_sequence == _seq 
egen maxmax_eduspell = max(max_eduspell) , by(youthid)
drop max_eduspell
rename maxmax_eduspell   max_eduspell 

label variable max_eduspell  "Type of longest consecutive sequence per individual"
label values max_eduspell  spell_edu


gen min_eduspell = spell_edu if min_sequence == _seq 
egen minmin_eduspell = max(min_eduspell) , by(youthid)
drop min_eduspell
rename minmin_eduspell   min_eduspell 

label variable min_eduspell  "Type of shortest consecutive sequence per individual"
label values min_eduspell  spell_edu


fre max_eduspell if begincm == min_begincm 
fre min_eduspell if begincm == min_begincm 


* Number of consecutive months in each spelltype by pid
///prioritize the highest months 

forvalues j = 1/9 {
by youthid: gen cons_edu`j'  = 0
replace cons_edu`j' = _seq if _end ==1 & spell_edu == `j'
egen maxcons_edu`j' = max(cons_edu`j'), by(youthid)
drop cons_edu`j' 
rename maxcons_edu`j'  cons_edu`j'
} 


label variable cons_edu1 "N conseq months in Lower secondary"
label variable cons_edu2 "N conseq months in Intermediate secondary"
label variable cons_edu3 "N conseq months in Upper secondary"
label variable cons_edu4 "N conseq months in Tertiary"
label variable cons_edu5 "N conseq months in Other"
label variable cons_edu6 "N conseq months in Apprenticeship"
label variable cons_edu7 "N conseq months in Employment"
label variable cons_edu8 "N conseq months in Out of employment"
label variable cons_edu9 "N conseq months in Missing"


* Identify the first and the last spell per individual

by youthid: gen first_eduspell = spell_edu if _spell == 1 
egen max_first_eduspell  = max(first_eduspell), by(youthid)
drop first_eduspell
rename max_first_eduspell first_eduspell
label values  first_eduspell spell_edu

egen N_spells = max(_spell), by (youthid)


by youthid: gen last_eduspell = spell_edu if _spell == N_spells 
egen min_last_eduspell = min(last_eduspell), by(youthid)
drop last_eduspell
rename min_last_eduspell last_eduspell
label values last_eduspell spell_edu


* Check the length of the first spell 

sum _seq if _end==1 & _spell == 1 , det  
bysort birthyr: sum _seq if _end==1 & _spell == 1 , det  



* Number of consecutive months in missing by birthcohort 

bysort birthyr: sum cons_edu9 if begincm == min_begincm , det 
bysort birthyr: sum count_edu9 if begincm == min_begincm , det 


sort youthid begincm 
br youthid begincm spell_edu _* *seq*  *age* if birthyr == 1995


* First and last spell by birth cohort 
bysort  birthyr:  fre  first_eduspell last_eduspell 



sort youthid begincm 

br youthid begincm date *age* spell_edu _*  count_* cons_* 


	
	
	
	
	
	