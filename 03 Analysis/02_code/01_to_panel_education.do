
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


// it seems as if don't know and no answer in y6_s1_sit2a,is general education or second chance (see y6_ylhcs_spt2), so I'd recode the missings in spelltype to 'other'
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



* Generate cm for all novembers from 2004-2009, 2013-2019

// https://www.calculator.net/age-calculator.html


forval year = 2004/2009 {
    gen nov_`year' = ym(`year',11)
}


* Set the cm start for each individual depending on when they were born 
// criteria: They should be 12 until June of the calendar (before entering the school year in september, this is following the logic of )


gen start = .
replace start = nov_2004 if birthyr == 1992  & birthmonth <= 6 
replace start = nov_2005 if birthyr == 1992  & birthmonth > 6

replace start = nov_2005 if birthyr == 1993  & birthmonth <= 6 
replace start = nov_2006 if birthyr == 1993  & birthmonth > 6

replace start = nov_2006 if birthyr == 1994  & birthmonth <= 6 
replace start = nov_2007 if birthyr == 1994  & birthmonth > 6

replace start = nov_2007 if birthyr == 1995  & birthmonth <= 6 
replace start = nov_2008 if birthyr == 1995  & birthmonth > 6

replace start = nov_2008 if birthyr == 1996  & birthmonth <= 6 
replace start = nov_2009 if birthyr == 1996  & birthmonth > 6

replace start = nov_2009 if birthyr == 1997  & birthmonth <= 6
replace start = nov_2009 if birthyr == 1997  & birthmonth > 6



br youthid begincm endcm nov_* start birthyr birthmonth age 
br if age >13 & start == begincm

br  youthid begincm endcm nov_* start birthyr birthmonth age  if youthid==  20010214

tab age if start == begincm
histogram age if start == begincm


forval year = 2013/2019 {
    gen nov_`year' = ym(`year',11)
}




* Set the end date of each individual as well (november again)  (WHAT AGE?? )
gen end = .
replace end = nov_2013 if birthyr == 1992  & birthmonth <= 6 
replace end = nov_2014 if birthyr == 1992  & birthmonth > 6

replace end = nov_2014 if birthyr == 1993  & birthmonth <= 6 
replace end = nov_2015 if birthyr == 1993  & birthmonth > 6

replace end = nov_2015 if birthyr == 1994  & birthmonth <= 6 
replace end = nov_2016 if birthyr == 1994  & birthmonth > 6

replace end = nov_2016 if birthyr == 1995  & birthmonth <= 6 
replace end = nov_2017 if birthyr == 1995  & birthmonth > 6

replace end = nov_2017 if birthyr == 1996  & birthmonth <= 6 
replace end = nov_2018 if birthyr == 1996  & birthmonth > 6

replace end = nov_2018 if birthyr == 1997  & birthmonth <= 6
replace end = nov_2019 if birthyr == 1997  & birthmonth > 6



tab age if end == begincm

histogram age if end == begincm
** create one spell for each individual, if overlapping give preference to educational spells



// There is a bit of an age range since we check the age until June and then start in November 



* Drop observations before the start date
bysort youthid: drop if begincm < start




* Drop observations after the start date 
bysort youthid: drop if begincm > end



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



forvalues i = 1/150 {
    replace begincm = begincm[_n+`i'] -`i' if begincm[_n+`i'] != . & tag1 == tag1[_n+`i'] & youthid == youthid[_n+`i'] & tag2[_n+`i'] == 1 
}


br youthid begincm endcm tag1 tag2 missing_start start  if youthid == 20020204


replace endcm = begincm +1 if begincm!=. 




* identify the last observation in cm 
egen max_endcm = max(begincm), by(youthid)

* tag the last observation 
bysort youthid : gen tag3 = 1 if (_n == _N)

* calculate the number of rows missing (until start)
gen missing_end =   end  - max_endcm    if tag3 == 1 


* expand the number of rows missing in the end
expand missing_end
sort youthid begincm 

br youthid begincm endcm tag1 tag2 tag3  missing_* start end


replace begincm = begincm[_n-1] + 1 if begincm[_n-1]!= . & tag3 == tag3[_n-1] & youthid == youthid[_n-1] & tag3 ==1 
replace endcm = begincm +1 if begincm!=. 


bysort youthid : gen tag4 = 1  if youthid == youthid[_n-1] & tag3 ==1 & tag3[_n-1] ==.




* Check the spelltype variable



br youthid begincm endcm *spell_* 


gen spell = 


sort spell_edu* 
egen spell_edu = rowmax(spell_edu1 - spell_edu17)


* check if spells are overlapping and how many are 
egen spell_N = rownonmiss(spell_edu1 - spell_edu17)



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


gen spell_edu = .

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

* replace the gap fillers (until start and end date) with missing (are filled because of the expand code)
replace spell_edu = 9 if tag3==1 & tag4!=1 
replace spell_edu = 9 if tag1==1 & tag2!=1 

label define spell_edu 1 "Lower secondary" 2 "Intermediate secondary" 3 "Upper secondary" 4 "Tertiary" 5 "Other" 6 "Apprenticeship" 7 "Employment" 8 "Out of employment" 9 "Missing ", modify 
label values spell_edu spell_edu 



br youthid begincm endcm *spell_*  if spell_N>1 

br youthid begincm endcm spell_edu 




/// **to-do: 

** spelltype with robtype (and priorities)
** think about gaps before and after but also within (and investigate these further); should we sum up our observations into 6-months periods? 
** here, one could check the duration of spells: how long are individuals generally in one spell?? 


