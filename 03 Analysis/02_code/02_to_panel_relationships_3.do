***********************************************************************************************************
***********************************************************************************************************
***	Relationship trajectories of students of migrant and non-migrant descent in Germany 	***************
***********************************************************************************************************
***********************************************************************************************************

set more off 

*current date
local date : di %dDNCY daily("$S_DATE", "DMY")
di "`date'"


* create log file 
capture log close _all 
log using "$LOG\log_02_relationship_`date'_$researcher.log", replace





************************************************************************
**# Bookmark  2. Preparation of dataset ********************************
************************************************************************

* Dataset on partner life course history
use "$DATA/w6_ylhcp_ge_v6.0.0_rv.dta", clear

 
*  add year of birth from the other dataset 
merge m:1 youthid using "$DATA/w6_ym_ge_v6.0.0_rv.dta" , ///
keepusing (y6_doby y6_dobm  y6_sex y6_date2 y6_intdat_ymRV)
recode _merge (3= 1 "Had relationship") (2 =0 "Never relationship"), gen(ever_relationship)
drop _merge 
replace ever_relationship = .  if y6_date2 == -66

ta ever_relationship // 1,524 cases never had a relationship - i.e. always single
ta y6_rp1startyRV ever_relationship, miss

* Get months and year of the interview separately 
gen intdate = dofm(y6_intdat_ylhcpRV)
replace intdate = dofm(y6_intdat_ymRV) if ever_relationship==0
format intdate %d
gen intmonth=month(intdate)
gen inty=year(intdate) 
drop intdate

* Generate an age variable (broad)
recode y6_rp1startyRV (-99 -88 = .)
gen age = y6_rp1startyRV - y6_doby 

* Checking year of first relationship
ta y6_rp1startyRV if y6_rpindex==1, miss
fre age  if y6_rpindex==1  


*clone some variables
clonevar begm  = y6_rp1startm
clonevar begy  = y6_rp1startyRV

clonevar endm        = y6_rp1endm
clonevar endy        = y6_rp1endy

clonevar birthdm     = y6_dobm 
clonevar birthdy     = y6_doby 

clonevar ongoing = y6_rp1ongoing

clonevar index       = y6_rpindex


/* 
The structure of the data is a bit strange: the unique id is not by spell 
but rather by unique partner. 

This means that repeated relationships with the same partner are treated
in a wide format, with different variables for start and end date

The same goes for cohabitation

I must create separate files for each repeated relationship and append. 

I must also create separate files for cohabitation and append them to 
create a detailed spell variable

The child spells are in a different dataset, will treat them similarly

*/



* First, I distinguish between native vs. foreign-origin relationships
recode y6_rpback2RV ///
(-99 -88 -55 = 4 "Missing") (1 =1 "Native") (2 =2 "Foreign") , gen(spelltype)

ta spelltype ever_relationship, miss

save "$TEMP\relationdata.dta", replace 


* CREATING REPEATED RELATIONSHIP SPELLS
*************************************************************************

forval i =2/3 {
	
	use "$TEMP\relationdata.dta", clear

	keep if y6_rp`i'relship==1
	
	cap drop begm begy endm endy ongoing

	clonevar begm  = y6_rp`i'startm
	clonevar begy  = y6_rp`i'starty

	clonevar endm        = y6_rp`i'endm
	clonevar endy        = y6_rp`i'endy

	
	clonevar ongoing = y6_rp`i'ongoing
	
	keep youthid begm begy endm endy spelltype ///
	ongoing intmonth inty ever_relationship birthdy birthdm
	
	save "$TEMP\relrepeat`i'.dta", replace 

}


use "$TEMP\relationdata.dta", clear
append using "$TEMP\relrepeat2.dta"
append using "$TEMP\relrepeat3.dta"

save "$TEMP\relationdata.dta", replace




* CREATING THE COHABITATION SPELLS
*************************************************************************

keep if y6_rpcohab==1
cap drop begm begy endm endy ongoing
clonevar begm  = y6_rpcohabstartm
clonevar begy  = y6_rpcohabstartyRV

clonevar endm        = y6_rpcohabendm
clonevar endy        = y6_rpcohabendy

clonevar ongoing = y6_rpcohab_ongoing

replace spelltype = 3

keep youthid begm begy endm endy spelltype ///
ongoing intmonth inty ever_relationship birthdy birthdm

save "$TEMP\cohabitation.dta", replace 


* Appending them back together
use "$TEMP\relationdata.dta", clear
append using "$TEMP\cohabitation.dta"
save "$TEMP\relationdata.dta", replace


/*
* CREATING THE CHILD SPELLS
*************************************************************************

use "$DATA/w6_ylhcc_ge_v6.0.0_rv.dta", clear


* Get months and year of the interview separately 
gen intdate = dofm(y6_intdat_ylhccRV)
format intdate %d
gen intmonth=month(intdate)
gen inty=year(intdate) 
drop intdate

* I treat child as an absorbing state
cap drop begm begy endm endy ongoing
clonevar begm  = y6_chdobm
clonevar begy  = y6_chdobyRV

gen endm        = intmonth
gen endy        = inty

gen ongoing = 1 // child as an absorbing state
gen spelltype = 4



keep youthid begm begy endm endy spelltype ongoing intmonth inty

save "$TEMP\child.dta", replace 


* Appending them back together
use "$TEMP\relationdata.dta", clear
append using "$TEMP\child.dta"

*/



* FURTHER CLEANING
*************************************************************************

* Recoding all missings
recode begy begm endy endm (-100/-1=.)

* Creating a new spell index
sort youthid begy begm index
bysort youthid (begy begm): gen count = _n
replace index = count
drop count
label variable index "Spell index"

* Labelling the spell variable
label define spell 0 "Single" 1 "Native-origin partner" ///
2 "Migrant-origin partner" 3 "Cohabiting" 4 "Missing", replace
label values spelltype spell


* Addressing the ongoing spells
replace endm  = intmonth if ongoing == 1 & endm==.  
replace endy  = inty if ongoing == 1 & endy==.  

* Generating new age at start of spell
bysort youthid: egen birth_year = max(y6_doby)
replace age = begy - birth_year 

* replace unspecific information on the month for beginning and ending month and set to missing
global dates "begm endm  begy endy birthdm birthdy"

foreach val of global dates {
recode `val'  (21 = 2 ) (24 = 4 ) (27 = 7) (30 = 9) (32 = 11) (-99 -88 -55 -22 -44 = .)
}



* Converting to century months
gen begincm = ym(begy, begm)
gen endcm = ym(endy, endm)
gen birthcm = ym( birthdy, birthdm)
gen intcm = ym(inty,intmonth)

* Checking the range of months
egen minbegincm = min(begincm) 
dis minbegincm // 577
egen maxendcm   = max(endcm)
dis maxendcm // 679
dis  maxendcm -  minbegincm   // 102 


* Checking youthids
unique(youthid)


/*
Number of unique values of youthid is  5820
Number of records is  8302 (with cohabitation)
*/







************************************************************************
**# Bookmark 3. Globals for spell data preparation   *******************
************************************************************************
 

global pid 			    youthid					/** Identifier for individuals in spell datafile **/
global spellnr 			index		    /** Identifier for spells of each person **/
global spelltype 		spelltype		     	/** spelltype of spells which will be used for splitting **/
global spells 			"1 2 3 4 "	 /** Spells: values of variable spelltype (see creation above)  **/
global begin 			begincm 			    /** Begin of spells **/
global end 				endcm					/** End of spells **/
global ongoing 			ongoing

sort ${pid} ${begin} ${end} ${spelltype} ${spellnr} ${ongoing}
order ${pid} ${begin} ${end} ${spelltype} ${spellnr}  ${ongoing}


************************************************************************
**# Bookmark 4.   Spell data preparation *******************************
************************************************************************


* Adjust the endings of all spells to be exclusive (which means the last months is not the last month e.g. in school but the month after (important for duration)) 
bysort ${pid} (${begin} ${end}): replace ${end} = ${end} + 1 if ${end} > 0 


* Generate a duration variable (in months)
gen duration = ${end} - ${begin}   

*if beginning or end of a spell is missing, the duration of a spell is set as zero month and the spell will not be expanded
replace duration = 0 if ${end} ==. | ${begin} ==. // 2342 cases, of which 2,270 are those without ever relationship
replace duration = 0 if duration <0   

fre duration
ta duration if ever_relationship==1
ta duration if ever_relationship==0
ta duration if ever_relationship==.



* multiply/expand each spell according to its duration 
expand duration

* adjust the beginning of all spells that the duration of each subspell of an original spell amounts to one months 
bysort ${pid} ${spellnr} (${begin} ${end}): replace ${begin} = ${begin}[_n-1] + 1 if ${begin}[_n-1]!= .
 
* adjust the ending so that the ending of each subspell equals to the beginning of the next subspell 
replace ${end} = ${begin} + 1 if ${begin}!=. 


drop duration 
order ${pid} ${begin} ${end} ${spellnr} ${spelltype}
 
 
 
* Checking the range of months
cap drop minbegincm maxendcm
egen minbegincm = min(begincm) 
dis minbegincm // 577
egen maxendcm   = max(endcm)
dis maxendcm // 680
dis  maxendcm -  minbegincm   // 103


cap drop _merge
save "$TEMP\relspell.dta", replace 



************************************************************************
**# Bookmark 5.  Panel data preparation  *******************************
************************************************************************

* Create a "blanco" dataset with youthid and N total observations (see dis  maxendcm -  minbegincm) to merge the spelldata with 

use "$TEMP\relspell.dta", clear


* Define some globals - these are taken from the education spell data, to make them comparable
global startcm 469 
global expansion 211 


* identify the first spell of each individual (tag =1 ) 
bys ${pid}(begincm): gen tag= _n ==1

* keep only one row for each individual
keep if tag ==1 
keep ${pid} ever_relationship intcm birthdy birthdm birthcm
unique(${pid})
expand ${expansion}    
sort ${pid} 

gen begincm= ${startcm}


* create a month starting from the first month anyone was observed and ending with the last month anyone was observed (practically like code above)
bysort ${pid}  (${begin} ): replace ${begin} = ${begin}[_n-1] + 1 if ${begin}[_n-1]!= .

gen endcm= 0

* adjust the ending so that the ending of each subspell equals to the beginning of the next subspell 
replace ${end} = ${begin} + 1 if ${begin}!=. 

save "$TEMP\rel_paneldata.dta", replace



* BEFORE MERGING, I MUST FILL IN EMPTY PERIODS WITH SINGLE SPELLS
use "$TEMP\rel_paneldata.dta", clear
cap drop _merge
merge 1:m youthid begincm endcm using "$TEMP\relspell.dta"

* First, I fill those without every any relationship
replace spelltype=0 if ever_relationship==0
ta _merge ever_relationship
drop if _merge==2 & ever_relationship==0

* Drop those cases with missing start/end dates completely
bysort youthid: gen flagged = _merge==2
bysort youthid: egen flagged_id = max(flagged)
drop if flagged_id==1

* For the rest, convert missing values before the interview to "single" spells
replace spelltype = 0 if _merge==1 & begincm<intcm 

* Only remaining missings are observations after inteview, I code them
replace spelltype=4 if spelltype==. & begincm>=intcm
drop _merge

* Generating maximum observation for each
cap drop maxendcm 
bysort youthid: egen maxendcm = max(endcm)

* However, I see there are some relationship overlaps! This may overestimate spells
recode spelltype (3 4 0 =0) (1 2 =1), gen(relationship)
bysort youthid begincm endcm relationship: gen n_rel = _n 
unique youthid if n_rel>1 // 101 individuals 

* Flagging them for now, may want to drop
bysort youthid (begincm endcm), sort: gen multi_rel_flag = sum(n_rel-1)>=1

* Checking migrant origin of overlaps
egen tag = tag (youthid begincm endcm spelltype) if n_rel>1 
egen ndistinct = total(tag), by(youthid begincm endcm)
ta ndistinct multi_rel_flag 
drop tag ndistinct

// Almost all of the overlapping relationships are from same original
// So we count as the same episode for our purposes
duplicates tag youthid begincm endcm spelltype, gen(tag)
drop if tag>0
drop tag

// Those with double relationship and different origins I keep native
// Can change approach later on
duplicates tag youthid begincm endcm relationship, gen(tag)
drop if tag>0 & relationship==1 & spelltype==2
drop tag


* Must now create new index for spells
bysort youthid (begincm endcm spelltype): ///
gen new_index2 = sum(spelltype!= spelltype[_n-1] & spelltype != spelltype[_n-2])

bysort youthid (begincm endcm spelltype): ///
replace new_index2 = new_index2[_n-2] if spelltype==spelltype[_n-2]

replace new_index = .  if begincm>intcm
cap drop index
rename new_index index

ta index //  maximum 13


* Cehcking duplicates
duplicates report youthid begincm endcm index


ta index

************************************************************************
**# Bookmark 6.   Merging    *******************************************
************************************************************************


** Generate a variable indicating the spelltype status for each index/spell (in this case total 17 = (max)y6_ylhcs_index))
* generate a variable for each possible value of ${spelltype}  (22 values)
forvalues i = 1(1)13 {
clonevar spell_rel`i' =  ${spelltype}  if index ==`i'
 display `i'
}


save "$TEMP\relspell_short.dta", replace 


** here, I create one separate dataset for each spell (because sometimes spells overlap which means merge doesn't work if we'd do it with the complete dataset)
forvalues i = 1(1)13 {
	use "$TEMP\relspell_short.dta", clear  
	keep if index==`i'
	keep youthid begincm endcm birthcm index  spell_rel`i'		 // add here any variables you'd want to keep from the spelldataset 
	clonevar index`i' =  index
	drop index
	save "$TEMP\relspell_`i'.dta", replace
 display `i'
}




use  "$TEMP\rel_paneldata.dta", clear 

* merge each separate spell dataset to the 'blanco' dataset created above
forvalues i = 1(1)13 {
merge 1:1 ${pid} ${begin} ${end} using "$TEMP\relspell_`i'.dta", gen(mergepanel`i')
display `i'
}


order ${pid}  ${begin}  ${end} merge* 
br
br if  ${begin}  ==. 


* create a variable to see how many spells match with a cm info (could be >1 if spells overlap)
egen matched = anycount(mergepanel1- mergepanel13), values(3)  
br ${pid}  ${begin}  ${end}  merge* matched 


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

sort youthid begincm endcm
order youthid begincm endcm ///
spell_rel1 spell_rel2 spell_rel3 spell_rel4 spell_rel5 spell_rel6 spell_rel7 ///
spell_rel8 spell_rel9 spell_rel10 spell_rel11 spell_rel12 spell_rel13


* CREATING SINGLE SPELL VARAIBLE
********************************************************************************


gen spell_rel = ""
forval i =1/13 {
	replace spell_rel = spell_rel + string(spell_rel`i')

}

destring spell_rel, ignore(".") replace
recode spell_rel (0 = 0 "Single") ///
(1 = 1 "Rel: nat-origin") (2 = 2 "Rel: mig-origin") ///
(13 31 = 3 "Cohab: nat-origin") (23 32 = 4 "Cohab: mig-origin") ///
(4 = 5 "Missing") (3=7 "Cohab: unclear"), ///
gen(spell_relationship) label(spell_rel)

ta spell_relationship

*keep youthid begincm endcm spell_relationship



* REASSIGNING SOME VALUES TO MISSING (BECAUSE PRE-2011 OR PRE-FIRST SPELL)
********************************************************************************

format %tm begincm

* Replacing pre-2011 for those who report never having a relationship before then
replace spell_relationship = 6 if ever_relationship==0 & begincm< ym(2011,1)

* Replacing events before first non-single spell before 2011 for the rest
bysort youthid (begincm): gen change = sum(spell_rel!= spell_rel[_n-1])
gen frst_year = begincm if change==2
bysort youthid: egen cmFrstSpell = min(frst_year)
replace spell_relationship = 6 if begincm < cmFrstSpell & begincm <ym(2011,1)


label define spell_rel 6 "Missing/single", modify
label values spell_relationship spell_rel

ta spell_relationship
ta spell_relationship if begincm > ym(2011,1)

save "$TEMP\relationship.dta", replace 


************************************************************************
**# Bookmark 6.   Setting time frame    ********************************
************************************************************************


use "$TEMP\relationship.dta", clear


* Generate cm for all novembers from 2004-2012
// https://www.calculator.net/age-calculator.html
forval year = 2004/2012 {
    gen nov_`year' = ym(`year',11)
}


* Set the cm start for each individual depending on when they were born 
// criteria: They should be 14 until June of the calendar (before entering the school year in novemver, this is following the logic of Dollmann & Weißmann 2019)


gen start = .
* Class of 2006 
replace start = nov_2006 if birthyr == 1992  & birthmonth <= 6 

* Class of 2007
replace start = nov_2007 if birthyr == 1992  & birthmonth > 6
replace start = nov_2007 if birthyr == 1993  & birthmonth <= 6 

* Class of 2008
replace start = nov_2008 if birthyr == 1993  & birthmonth > 6
replace start = nov_2008 if birthyr == 1994  & birthmonth <= 6 

* Class of 2009
replace start = nov_2009 if birthyr == 1994  & birthmonth > 6
replace start = nov_2009 if birthyr == 1995  & birthmonth <= 6 

* Class of 2010
replace start = nov_2010 if birthyr == 1995  & birthmonth > 6
replace start = nov_2010 if birthyr == 1996  & birthmonth <= 6
 
* Class of 2011
replace start = nov_2011 if birthyr == 1996  & birthmonth > 6
replace start = nov_2011 if birthyr == 1997  & birthmonth <= 6

* Class of 2012
replace start = nov_2012 if birthyr == 1997  & birthmonth > 6

tab age if start == begincm, m
label variable start "Grade-specific start of trajectory in cm"




** Create the starting year of each individual (based on birthyear and birthmonth)
gen class = .
* Class of 2006 
replace class = 2006 if birthyr == 1992  & birthmonth <= 6 

* Class of 2007
replace class = 2007 if birthyr == 1992  & birthmonth > 6
replace class = 2007 if birthyr == 1993  & birthmonth <= 6 

* Class of 2008
replace class = 2008 if birthyr == 1993  & birthmonth > 6
replace class = 2008 if birthyr == 1994  & birthmonth <= 6 

* Class of 2009
replace class = 2009 if birthyr == 1994  & birthmonth > 6
replace class = 2009 if birthyr == 1995  & birthmonth <= 6 

* Class of 2010
replace class = 2010 if birthyr == 1995  & birthmonth > 6
replace class = 2010 if birthyr == 1996  & birthmonth <= 6
 
* Class of 2011
replace class = 2011 if birthyr == 1996  & birthmonth > 6
replace class = 2011 if birthyr == 1997  & birthmonth <= 6

* Class of 2012
replace class = 2012 if birthyr == 1997  & birthmonth > 6


label variable start "Class of the specific calendar year"

label define class 2006 "2006 (92)" ///
                        2007 "2007 (92/93)" ///
                        2008 "2008 (93/94)" ///
                        2009 "2009 (94/95)" ///
                        2010 "2010 (95/96)" ///
                        2011 "2011 (96/97)" ///
                        2012 "2012 (97)"
						
label values class class			
						
						
						
						
* identify the first observation in cm 
egen min_begincm = min(begincm), by(youthid)
unique youthid if min_begincm> start						
						
						
* Checking spell type in start date
ta spell_relationship if begincm==start
ta spell_relationship if begincm==start & inlist(class, 2009, 2010)					
ta spell_relationship class if begincm==start, col
					
* 						
			
			
			
			
/*			

* Generating the end date

forval year = 2013/2020 {
    gen nov_`year' = ym(`year',11)
}

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


tab age if end == begincm, miss


*/




************************************************************************
**# Bookmark 9. Set the time frame   ***********************************
************************************************************************


* Drop all observations before the start date we have now (around age 14)
bysort class: count if begincm < start 


drop if start==. 
drop if begincm < start  
/// (676,256 observations deleted - this is more bc of how I generated the data)


* Change the time frame to grademonth (time focuses now on the grade and not on the cmonth)
sort youthid begincm
egen grade_month = seq() , from(1) by (youthid)

** if command: there are some individuals who start after the "official start date"

label variable grade_month "Months starting from November in Grade 9"

** grademonth= 1 is equivalent to November of the year, in which the pupil turned 14 until the end of June 
tab age if grade_month==1


/*

This matches pretty well with the educational spell data

        age |      Freq.     Percent        Cum.
------------+-----------------------------------
   14.41667 |        393        7.95        7.95
       14.5 |        438        8.86       16.82
   14.58333 |        361        7.31       24.12
   14.66667 |        432        8.74       32.87
      14.75 |        374        7.57       40.44
   14.83333 |        410        8.30       48.74
   14.91667 |        419        8.48       57.22
         15 |        378        7.65       64.87
   15.08333 |        417        8.44       73.30
   15.16667 |        433        8.76       82.07
      15.25 |        430        8.70       90.77
   15.33333 |        456        9.23      100.00
------------+-----------------------------------
      Total |      4,941      100.00


*/ 




*  Generate a sequence of numbers for every second row
egen grade_bimonth = seq(), block(2) by (youthid)
by youthid: replace grade_bimonth = . if grade_bimonth[_n-1]== grade_bimonth
label variable grade_bimonth "Every second months starting from November in Grade 9"



egen grade= seq(), block(12) by (youthid)
replace grade= grade+8
* note: this would assume that the school years starts in November which it doesn't really, but the start of the school year is around August/September (depending on the year and the state)


* make sure to have information on every second month 
egen max_grade_bimonth =max(grade_bimonth), by (youthid)
bysort class: tab max_grade_bimonth

* I fill in the bimonths with the minimum (gives priority to singlehood)
bysort youthid grade_bimonth: egen spell_relat = min(spell_relationship)
label values spell_relat spell_rel
fre spell_relat
fre spell_relationship

save "$TEMP\relationship2.dta", replace 
use "$TEMP\relationship2.dta", clear



* Calculate the number of month individuals spend in each educational state (gping by priorization)

forvalues j = 1/9 {
cap drop count_relationship`j'
egen count_relationship`j' = total(spell_relationship == `j'), by(youthid)
tab count_relationship`j'
} 

label variable count_relationship1 "N months in Single"
label variable count_relationship2 "N months in Rel: nat-origin"
label variable count_relationship3 "N months in Rel: mig-origin"
label variable count_relationship4 "N months in Cohab: nat-origin"
label variable count_relationship5 "N months in Cohab: mig-origin"
label variable count_relationship6 "N months in Missing"
label variable count_relationship7 "N months in Missing/single"
label variable count_relationship8 "N months in Cohab: unclear"
label variable count_relationship9 "N months in Missing"




*drop every second row 
drop if grade_bimonth ==. 

 


* Some descriptive statistics 
tab   grade_bimonth spell_relationship , matcell(table)  matrow(names)  m
putexcel set "$DESKTOP\Relationship", modify sheet("Overall") 
putexcel B1 = matrix(table), names hcenter
putexcel B2 = matrix(names)


	putexcel A1  = "Months"
    putexcel A2  = "1"
    putexcel A3 = formula(=A2+2)
    putexcel B1 = "Bimonthly"
    putexcel C1 = "Single"
    putexcel D1 = "Rel: nat-origin"
    putexcel E1 = "Rel: mig-origin"
    putexcel F1 = "Cohab: nat-origin"
    putexcel G1 = "Cohab: mig-origin"
    putexcel H1 = "Missing"
    putexcel I1 = "Missing/single"
    putexcel J1 = "Cohab: unclear"
	putexcel K1 = "Missing Total"
    putexcel L1 = "SUM"


    putexcel M1 = "Percentages"
    putexcel N1 = "Single"
    putexcel O1 = "Rel: nat-origin"
    putexcel P1 = "Rel: mig-origin"
    putexcel Q1 = "Cohab: nat-origin"
    putexcel R1 = "Cohab: mig-origin"
    putexcel S1 = "Missing"
    putexcel T1 = "Missing/single"
    putexcel U1 = "Cohab: unclear"
    putexcel V1 = "Missing Total"
    putexcel W1 = "SUM"
    putexcel X1 = "Missing of max observations"
    putexcel Z1 = "Max observations"

forvalues j = 2/100 {
    putexcel K`j' = formula(=SUM(H`j':J`j'))
	putexcel L`j' = formula(=SUM(C`j':J`j'))
	putexcel N`j' = formula(=C`j'/L`j')
	putexcel O`j' = formula(=D`j'/L`j')
    putexcel P`j' = formula(=E`j'/L`j')
    putexcel Q`j' = formula(=F`j'/L`j')
    putexcel R`j' = formula(=G`j'/L`j')
    putexcel S`j' = formula(=H`j'/L`j')
    putexcel T`j' = formula(=I`j'/L`j')
    putexcel U`j' = formula(=J`j'/L`j')
    putexcel V`j' = formula(=K`j'/L`j')
    putexcel W`j' = formula(=SUM(N`j':U`j'))
	putexcel Z2   = formula(=MAX(L2:L50)) 
	putexcel X`j' = formula(=L`j'/Z2)
}




** Relationships by class and century months  

local years  "2006 2007 2008 2009 2010 2011 2012  "



foreach year in `years' {
    * Tabulate missing data by birth year
    quietly tab   grade_bimonth  spell_relationship if class == `year',  matcell(table)  matrow(names)  m
    putexcel set "$DESKTOP\Relationship", modify sheet("Class`year'")
	putexcel B1 = matrix(table), names hcenter
    putexcel B2 = matrix(names)
	
	putexcel A1  = "Months"
    putexcel A2  = "1"
	putexcel A3 = formula(=A2+2)
	putexcel B1 = "Bimonthly"
    putexcel C1 = "Single"
    putexcel D1 = "Rel: nat-origin"
    putexcel E1 = "Rel: mig-origin"
    putexcel F1 = "Cohab: nat-origin"
    putexcel G1 = "Cohab: mig-origin"
    putexcel H1 = "Missing"
    putexcel I1 = "Missing/single"
    putexcel J1 = "Cohab: unclear"
	putexcel K1 = "Missing Total"
    putexcel L1 = "SUM"


    putexcel M1 = "Percentages"
    putexcel N1 = "Single"
    putexcel O1 = "Rel: nat-origin"
    putexcel P1 = "Rel: mig-origin"
    putexcel Q1 = "Cohab: nat-origin"
    putexcel R1 = "Cohab: mig-origin"
    putexcel S1 = "Missing"
    putexcel T1 = "Missing/single"
    putexcel U1 = "Cohab: unclear"
	putexcel V1 = "Missing Total"
	putexcel W1 = "SUM"
	putexcel X1 = "Missing of max observations"
	putexcel Z1 = "Max observations"

forvalues j = 2/50 {
	putexcel K`j' = formula(=SUM(H`j':J`j'))
	putexcel L`j' = formula(=SUM(C`j':J`j'))
	putexcel N`j' = formula(=C`j'/L`j')
	putexcel O`j' = formula(=D`j'/L`j')
    putexcel P`j' = formula(=E`j'/L`j')
    putexcel Q`j' = formula(=F`j'/L`j')
    putexcel R`j' = formula(=G`j'/L`j')
    putexcel S`j' = formula(=H`j'/L`j')
    putexcel T`j' = formula(=I`j'/L`j')
    putexcel U`j' = formula(=J`j'/L`j')
    putexcel V`j' = formula(=K`j'/L`j')
    putexcel W`j' = formula(=SUM(N`j':U`j'))
	putexcel Z2   = formula(=MAX(L2:L50)) 
	putexcel X`j' = formula(=L`j'/Z2)
	
}
}


egen maxgrade_bimonth  =max(grade_bimonth), by (youthid)
fre maxgrade_bimonth





************************************************************************
**# Bookmark 10. Investigate time series data   *************************
************************************************************************


use "$TEMP\relationship2.dta", clear




*change the format of begincm
 format begincm %10.0g

* Sort the data by 'youthid' and 'begincm'
sort youthid begincm 


* Declare data to be time series 
tsset youthid begincm 
tsspell spell_relationship



// Generate a new variable 'row_number' that represents the row number within each individual
egen row_number = seq(), by(youthid)




* length of the sequences for each sequence 
tab _seq if _end ==1 

sum _seq if _end ==1, det 




** -- > on average, each sequence lasts around 20 months, with a minimum of 1 and a maximum of 97 months 

egen meansequence = mean(_seq), by(youthid)
label variable meansequence  "Mean sequence length per individual"


* longest and shortest consecutive sequence for each individual (in months)

egen max_sequence = max(_seq), by(youthid)
egen min_sequence = min(_seq), by(youthid)


* type of longest and shortest consecutive sequence for each individual 
gen max_relationship = spell_relationship if max_sequence == _seq 
egen maxmax_relationship = max(max_relationship) , by(youthid)
drop max_relationship
rename maxmax_relationship   max_relationship 

label variable max_relationship  "Type of longest consecutive sequence per individual"
label values max_relationship   spell_rel


gen min_relationship = spell_relationship if min_sequence == _seq 
egen minmin_relationship = max(min_relationship) , by(youthid)
drop min_relationship
rename minmin_relationship   min_relationship 

label variable min_relationship  "Type of shortest consecutive sequence per individual"
label values min_relationship  spell_rel

fre max_relationship if begincm == min_begincm 
fre min_relationship if begincm == min_begincm 

forvalues j = 1/9 {
by youthid: gen cons_relationship`j'  = 0
replace cons_relationship`j' = _seq if _end ==1 & spell_relationship == `j'
egen maxcons_relationship`j' = max(cons_relationship`j'), by(youthid)
drop cons_relationship`j' 
rename maxcons_relationship`j'  cons_relationship`j'
} 

label variable cons_relationship1 "N conseq months in Single"
label variable cons_relationship2 "N conseq months in Rel: nat-origin"
label variable cons_relationship3 "N conseq months in Rel: mig-origin"
label variable cons_relationship4 "N conseq months in Cohab: nat-origin"
label variable cons_relationship5 "N conseq months in Cohab: mig-origin"
label variable cons_relationship6 "N conseq months in Missing"
label variable cons_relationship7 "N conseq months in Missing/single"
label variable cons_relationship8 "N conseq months in Cohab: unclear"



* Identify the first spell per individual
by youthid: gen first_relationship = spell_relationship if _spell == 1 
egen max_first_relationship  = max(first_relationship), by(youthid)
drop first_relationship
rename max_first_relationship first_relationship
label values  first_relationship spell_rel


* Identify the last spell per individual
egen N_spells = max(_spell), by (youthid)

by youthid: gen last_relationship = spell_relationship if _spell == N_spells 
egen min_last_relationship = min(last_relationship), by(youthid)
drop last_relationship
rename min_last_relationship last_relationship
label values last_relationship spell_rel


*drop every second row 
drop if grade_bimonth ==. 


save "$TEMP\relationship3.dta", replace 




