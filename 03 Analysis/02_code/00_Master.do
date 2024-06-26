**# Bookmark #1

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

global researcher "Maria"




if "$researcher" == "Alessandro" {

global WORKDIR "C:\Users\Alessandro Ferrara\OneDrive - Istituto Universitario Europeo\Documents\PAPERS\CILS4EU_SEQUENCE"

global DATA "$WORKDIR\01_data" 
global TEMP "$WORKDIR\01_data\TEMP"
global LOG  "$WORKDIR\03_log" 
global GRAPH "$WORKDIR\04_graphs"
global DESC "$WORKDIR\05_tables"

}



if "$researcher" == "Maria" {

global DATA "C:\Users\hornunma\Desktop\DATA\CILS4EU_mig" 

global TEMP "C:\Users\hornunma\Desktop\DATA\TEMP"

global WORKDIR "Z:Eigene Dateien\Migrants and Education\03 Analysis"
global DO "$WORKDIR\02_code"
global LOG     "$WORKDIR\03_log" /* hier soll das log-file gespeichert werden */
global GRAPH "$WORKDIR\04_graphs"
global DESC "$WORKDIR\05_tables"
global DESKTOP "C:\Users\hornunma\Desktop"

}






************************************************************************
************* 2. Installation of packages ******************************
************************************************************************

*ssc install varlab 
net install convertCMC, from(https://raw.githubusercontent.com/bugbunny/convertCMC/master)




************************************************************************
************* 3. Run do-files             ******************************
************************************************************************


*-------------+---------------------------------------------------------
** Run the do-files:
*-------------+---------------------------------------------------------


do "$DO/01_to_panel_education.do"
do "$DO/02_to_panel_relationships_3.do"	
*do "$DO/03_final_panel.do"
