// pull nhanes dataset
do nhanes_fena.ado

nhanes_fena, ys(1999) ye(2018) s2017 ds(4)
nhanes_fena, ys(1999) ye(2018) s2017 ds(1)
nhanes_fena, ys(1999) ye(2018) s2017 ds(2)

use "NHANES_demographic_1999_2018", clear
sort seqn
merge 1:1 seqn using "NHANES_questionnaire_1999_2018", nogen
merge 1:1 seqn using "NHANES_exam_1999_2018", nogen

save nhanes_demo_exam_ques, replace

// tab and see the missingness of questionnaire data for each year
// tab year_start _merge

// subset to 1999-2009
/* Turned off 
    Leave the subset part to variable cleaning to allow different outcomes
*/

/*
keep if year_start <= 2009

save nhanes_2009, replace

use nhanes_2009, clear

keep seqn rhq551b ssq010 ssd011 ssq011 ssd031 ssq030 ssq031 ciqd* cidd* ciqg* cidg* ciqp* cidp* dpq* year_start
save nhanes_2009_mental, replace
*/


