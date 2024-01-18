
***********************************************************************************************************
***********************************************************************************************************
***	Educational trajectories of students of migrant and non-migrant descent in Germany 	*******************
***********************************************************************************************************
***********************************************************************************************************


************************************************************************
*************     0. Basic setting     *********************************
************************************************************************


*** clear
clear all

*** Set version
*version STATA 16 SE

*** Control monitor output
set more off
set logtype text
set linesize 255 



************************************************************************
************* 1. Definition of Globals *********************************
************************************************************************

global researcher == ""

if "$researcher" == "Alessandro" {

global WORKDIR "Z:\Eigene Dateien\Migrants and Education\03 Analysis"

global DATA "$WORKDIR\01_data" 
global TEMP "$WORKDIR\01_data\TEMP"
global DO "$WORKDIR\02_code"
global LOG     "$WORKDIR\03_log" /* hier soll das log-file gespeichert werden */
global DESC "$WORKDIR\04_graphs"
global GRAPH "$WORKDIR\05_tables"

}



if "$researcher" == "Maria" {

global WORKDIR "Z:\Eigene Dateien\Migrants and Education\03 Analysis"

global DATA "$WORKDIR\01_data" 
global TEMP "$WORKDIR\01_data\TEMP"
global DO "$WORKDIR\02_code"
global LOG     "$WORKDIR\03_log" /* hier soll das log-file gespeichert werden */
global DESC "$WORKDIR\04_graphs"
global GRAPH "$WORKDIR\05_tables"

}




************************************************************************
************* 2. Installation of packages ******************************
************************************************************************

*ssc install varlab 





************************************************************************
************* 3. Run do-files             ******************************
************************************************************************


*-------------+---------------------------------------------------------
** Run the do-files:
*-------------+---------------------------------------------------------


 *do "$DO/01_Mixed_generation.do"	

