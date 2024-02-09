***********************************************************************************************************
***********************************************************************************************************
***	Relationship trajectories of students of migrant and non-migrant descent in Germany 	***************
***********************************************************************************************************
***********************************************************************************************************





************************************************************************
**# Bookmark  2. Preparation of dataset ********************************
************************************************************************

* Dataset on partner life course history
use "$DATA/w6_ylhcp_ge_v6.0.0_rv.dta", clear

 
*  add year of birth from the other dataset 
merge m:1 youthid using "$DATA/w6_ym_ge_v6.0.0_rv.dta" , keepusing (y6_doby y6_dobm  y6_sex) keep (match)

* Get months and year of the interview separately 
gen intdate = dofm(y6_intdat_ylhcpRV)
format intdate %d
gen intmonth=month(intdate)
gen inty=year(intdate) 
drop intdate

* Generate an age variable (broad)
recode y6_rp1startyRV (-99 -88 = .)
gen age = y6_rp1startyRV - y6_doby 

* Checking year of first relationship: seems like most people have at least one
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
recode y6_rpback2RV (-99 -88 -55 = .), gen(spelltype)

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
	
	keep youthid begm begy endm endy spelltype ongoing intmonth inty
	
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

keep youthid begm begy endm endy spelltype ongoing intmonth inty

save "$TEMP\cohabitation.dta", replace 


* Appending them back together
use "$TEMP\relationdata.dta", clear
append using "$TEMP\cohabitation.dta"
save "$TEMP\relationdata.dta", replace


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
2 "Migrant-origin partner" 3 "Cohabiting" 4 "Child", replace
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
Number of unique values of youthid is  3554
Number of records is  6173
*/

* Question: are the missing youthid's simply the people who never have a relationship spell?



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
replace duration = 0 if ${end} ==. | ${begin} ==. // only 166 cases
replace duration = 0 if duration <0   

fre duration

* multiply/expand each spell according to its duration 
expand duration

* adjust the beginning of all spells that the duration of each subspell of an original spell amounts to one months 
bysort ${pid} ${spellnr} (${begin} ${end}): replace ${begin} = ${begin}[_n-1] + 1 if ${begin}[_n-1]!= .
 
* adjust the ending so that the ending of each subspell equals to the beginning of the next subspell 
replace ${end} = ${begin} + 1 if ${begin}!=. 


drop duration 
order ${pid} ${begin} ${end} ${spellnr} ${spelltype}
 
cap drop _merge
save "$TEMP\relspell.dta", replace 



************************************************************************
**# Bookmark 5.  Panel data preparation  *******************************
************************************************************************

* Create a "blanco" dataset with youthid and N total observations (see dis  maxendcm -  minbegincm) to merge the spelldata with 

* IMPORTANT: I use the relationship spell data and the appended child one. 
*BUT: TBD if I should use the main data

use "$TEMP\relspell.dta", clear


* Define some globals 
global startcm 577  // start date of the earliest time observed (see minbegincm above)
global expansion 102 // whole observation period of the sample (see dis  maxendcm -  minbegincm   // 210  above (I made 211 just to be sure))


* identify the first spell of each individual (tag =1 ) 
bys ${pid}(begincm): gen tag= _n ==1

* Tag a single observation per individual


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

save "$TEMP\rel_paneldata.dta", replace



* BEFORE MERGING, I MUST FILL IN EMPTY PERIODS WITH SINGLE SPELLS
use "$TEMP\rel_paneldata.dta", clear
cap drop _merge
merge 1:m youthid begincm endcm using "$TEMP\relspell.dta"
bysort youthid: egen max_intcm = max(intcm)
replace spelltype = 0 if _merge==1 & endcm<max_intcm 
drop max_intcm

* Must now create new index for spells
bysort youthid (begincm endcm spelltype): ///
gen spellchange = sum(spelltype != spelltype[_n-1] ///
& spelltype !=spelltype[_n-2] & spelltype !=spelltype[_n-2])

bysort youthid (begincm endcm spelltype): ///
replace spellchange = spellchange[_n-2] if spelltype==spelltype[_n-2]
replace spellchange = spellchange[_n-3] if spelltype==spelltype[_n-3]

drop index
rename spellchange index


************************************************************************
**# Bookmark 6.   Merging    *******************************************
************************************************************************

use "$TEMP\relspell.dta", clear  


** Generate a variable indicating the educational/spelltype status for each index/spell (in this case total 17 = (max)y6_ylhcs_index))
* generate a variable for each possible value of ${spelltype}  (22 values)
forvalues i = 1(1)17 {
clonevar spell_rel`i' =  ${spelltype}  if index ==`i'
 display `i'
}


save "$TEMP\relspell_short.dta", replace 


** here, I create one separate dataset for each spell (because sometimes spells overlap which means merge doesn't work if we'd do it with the complete dataset)
forvalues i = 1(1)17 {
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
forvalues i = 1(1)17 {
merge 1:1 ${pid} ${begin}  using "$TEMP\relspell_`i'.dta", gen(mergepanel`i')
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




