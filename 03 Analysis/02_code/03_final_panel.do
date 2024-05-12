***********************************************************************************************************
***********************************************************************************************************
***	Final panel dataset  **********************************************************************************
***********************************************************************************************************
***********************************************************************************************************


set more off 

*current date
local date : di %dDNCY daily("$S_DATE", "DMY")
di "`date'"


* create log file 
capture log close _all 
log using "$LOG\log_03_panel_`date'_$researcher.log", replace




************************************************************************
**# Bookmark  1. Merge the datasets ************************************
************************************************************************



* Dataset education
use "$TEMP\educ3.dta", clear



*  add year of birth from the other dataset 
merge 1:1 youthid grade_bimonth using "$TEMP\relationship3.dta" 




************************************************************************
**# Bookmark  2. Double-check the current dataset **********************
************************************************************************





/*


use "$TEMP\relationship3.dta", clear





* merge on grademonths and unique id?

grade_bimonth 
youthid grade_bimonth



 
