
***********************************************************************************************************
***********************************************************************************************************
***	Educational trajectories of students of migrant and non-migrant descent in Germany 	*******************
***********************************************************************************************************
***********************************************************************************************************

set more off 

*current date
local date : di %dDNCY daily("$S_DATE", "DMY")
di "`date'"


capture log close _all 
log using "$LOG\log_01_to_panel_`date'.log", replace



* relationship information 
use "$DATA/w6_ylhcp_ge_v6.0.0_rv.dta", clear
describe

* education and profession 
use "$DATA/w6_ylhcs_ge_v6.0.0_rv.dta", clear
describe

 
 
 *use "$DATA/w6_ym_ge_v6.0.0_rv", clear
 
**  add the year of birth from the other dataset 
merge m:1 youthid using "$DATA/w6_ym_ge_v6.0.0_rv.dta" , keepusing (y6_doby) keep (match)
 
 
 
 fre y6_doby   if y6_ylhcs_index==1  
 
 gen age = y6_ylhcs_begdaty - y6_doby 
 fre age  if y6_ylhcs_index==1  
  
  
  
 br if age == 22 & y6_ylhcs_index==1  
 
 
 fre y6_sample
 
 
 y6_s1_sit2a
 
 
 
 
 

br youthid *beg* *end* y6_s1*
br

fre y6_ylhcs_spt1
fre y6_ylhcs_spt2


fre  y6_s1_sit2a if y6_ylhcs_index==1 




unique(youthid)

/*
Number of unique values of youthid is  5074
Number of records is  25008
*/



 
 * youthid --> id variable 
 *  y6_ylhcs_begdatm --> beginning of spell (month)
 * y6_ylhcs_begdaty --> beginning of spell (year)
 * y6_ylhcs_enddatm --> end of spell (month)
*  y6_ylhcs_enddaty --> end of spell (year)


* other important variables:
* *_ongoing
* *_correction 


*************  Globals for spell file ****************************

global spellfile 		"artkalen"				/** Name of spell datafile **/

global s_pid 			persnr					/** Identifier for individuals in spell datafile **/
global spellnr 			spellnr					/** Identifier for spells of each person **/
global spelltype 		spelltyp				/** spelltype of spells which will be used for splitting **/
global spells 			"3 4"					/** Values of Spelltyp for which spells between interviews shall be identified (here for example the values for vocational training. You can choose as much spelltypes you want by putting the according values of the spelltype) **/

global begin 			begin					/** Begin of spells **/
global end 				end						/** End of spells **/
global censor 			zensor					/** Censor-Variable **/


