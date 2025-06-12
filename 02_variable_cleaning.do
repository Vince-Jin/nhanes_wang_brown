qui {
	if 1 {
		// setting up the environment
		cls
		clear all
		set more off

		global root : di "`c(pwd)'"
		global slash

		if substr("`c(os)'", 1, 1) == "W" {
			global slash "\"
		}
		else {
			global slash "/"
		}

		global root : di "${root}${slash}"
	}

	if 2 {
		cd "${root}"

		// loading the data
		use nhanes_demo_exam_ques, clear
	}

	if 3 {
		/* some basic info about variables:
			- seqn: id
			- year_start: survey cycle start year - renamed to survey
            - age: age in years
            - race
            - gender
            - diabete: diabetes status
            - dia_med: diabetes medication intake
            - hypertension: hypertension status
            - hyp_med: antihypertensive medication intake
            - smoke: ever smoked 100 cigarettes in life
            - education: education level
            - bpxsar_new: systolic blood pressure
            - bpxdar_new: diastolic blood pressure
            - bmi: body-mass index
            - ghb: glycated hemoglobin
            - hs: self-rated health
            - support: need more support
            - emo_support: anyone to help with emotional support
            - asi: asian subgroup (not used in current version due to all missing values)
            - stroke: stroke history
            - depression: depression status
		*/

		rename year_start survey

		if 3.01 { // some labels for back up
			capture label drop riagendr
			label define riagendr 1 "Male" 2 "Female"
			label values riagendr riagendr
			capture label drop race
			label define race 1 "Mexican America" 2 "Other Hispanic" 3 "Non-Hispanic White" 4 "Non-Hispanic Black" 5 "Other"
			// label values race race
			capture label drop ridreth3 1 "Mexican America" 2 "Other Hispanic" 3 "Non-Hispanic White" 4 "Non-Hispanic Black" 5 "Non-Hispanic Asian" 6 "Other"
			label values ridreth3 ridreth3
		}

		if 3.1 { // regrouping for gender
			capture drop gender
			gen gender = .
			replace gender = 1 if riagendr == 1
			replace gender = 2 if riagendr == 2
            replace gender = gender - 1
			
			capture label drop gender
            label define gender 0 "Male" 1 "Female"
			label values gender gender
			label variable gender "Female"
		}

		if 3.2 { // regrouping for race
			capture drop race
			gen race = .
			replace race = ridreth1 if ridreth1 != .
			replace race = ridreth3 if ridreth3 != .
			replace race = 5 if ridreth3 == 6
			replace race = 5 if ridreth3 == 7

			label values race race
			label variable race "Race"
			
		}

		if 0 { // regrouping for asian subgroups
			// turned off due to all missing values for ridreth3
			capture drop asi
			gen asi = .
			replace asi = 1 if ridreth3 == 6
			replace asi = 0 if ridreth3 == 7

			label define asi 0 "No" 1 "Yes"
		}

		if 3.4 { // regrouping for age
			capture drop age
			gen age = ridageyr
			label variable age "Age in Years"
		}

		if 3.5 { // regrouping for diabetes and diabetes medication
			capture drop diabete
			gen diabete = .
			label variable diabete "Diabetes"
			capture label drop diabete
			label define diabete 1 "Yes" 0 "No"
			capture drop dia_med
			gen dia_med = .
			replace diabete = 1 if diq010 == 1
			replace diabete = 0 if diq010 == 2
			label values diabete diabete

			replace dia_med = 1 if (diq010 == 1 & diq050 == 1)
			replace dia_med = 2 if (diq010 == 1 & diq070 == 1) | (diq010 == 1 & did070 == 1)

			capture label drop dia_med
			label define dia_med 1 "Insulin Dependent" 2 "Other Medication"
			label values dia_med dia_med
			label variable dia_med "Diabetic Medication Intake"
		}

		if 3.6 { // regrouping for hypertension and hypertension medication
			capture drop hypertension
			gen hypertension = .
			replace hypertension = 1 if bpq020 == 1
			replace hypertension = 0 if bpq020 == 2
			replace hypertension = . if bpq020 == 7
			replace hypertension = . if bpq020 == 9
			
			capture label drop hypertension
			label define hypertension 0 "No" 1 "Yes" 2 "Refused to Answer" 3 "Don't Know"
			label variable hypertension "Hypertension"
			label values hypertension hypertension
			
			capture drop hyp_med
			gen hyp_med = .
			replace hyp_med = 0 if bpq040a == 2
			replace hyp_med = 1 if bpq040a == 1
			replace hyp_med = . if bpq040a == 3
			replace hyp_med = . if bpq040a == 4
			

			
			capture label drop hyp_med
			label define hyp_med 0 "No" 1 "Yes" 2 "Refused to Answer" 3 "Don't Know"
			label variable hyp_med "Antihypertensive"
			label values hyp_med hyp_med
		}

		if 3.7 { // regrouping for smoking status

			// smq020: ever smoked at least 100 cigarettes in life
			capture drop smoke
			gen smoke = .
			replace smoke = 0 if smq020 == 2
			replace smoke = 1 if smq020 == 1
			label variable smoke "Ever Smoked"
			
			capture label drop smoke
			label define smoke 1 "Yes" 0 "No"
			label values smoke smoke
		}

		if 3.8 { // regrouping for education
			capture drop education
			gen education = .
			// education
			/*
			1 - k8
			2 - high school
			3 - diploma/equivalent
			4 - some college/associate
			5 - above
			6 - more than high school
			7 - refused
			*/
			replace education = 1 if (dmdeduc2 == 1)
			replace education = 2 if (dmdeduc2 == 2)
			replace education = 3 if (dmdeduc2 == 3)
			replace education = 4 if (dmdeduc2 == 4)
			replace education = 5 if (dmdeduc2 == 5)
			replace education = . if (dmdeduc2 == 7)
			
			capture label drop education
			label define education 1 "k8" 2 "Some High School" 3 "High School Diploma or Equivalent" 4 "Some College or Associate" 5 "College Graduates and Above" 6 "More Than High School" 7 "Refused"
			label values education education
			label variable education "Education Level"
		}

		if 3.9 { // regrouping for blood pressure
			// turned off as current version of dataset does not have these variables
			capture drop bpxsar_new
			gen bpxsar_new = .
			capture drop bpxdar_new
			gen bpxdar_new = .
			capture drop bpxsar_helper
			capture drop bpxdar_helper

			egen bpxsar_helper = rowmean(bpxosy*)
			egen bpxdar_helper = rowmean(bpxodi*)

			replace bpxsar_new = bpxsar if bpxsar_new == . & bpxsar != .
			replace bpxdar_new = bpxdar if bpxdar_new == . & bpxdar != .
			replace bpxsar_new = bpxsar_helper if bpxsar_new == . & bpxsar == .
			replace bpxdar_new = bpxdar_helper if bpxdar_new == . & bpxdar == .
			
			label variable bpxsar_new "Systolic BP mmHg"
			label variable bpxdar_new "Diastolic BP mmHg"
		}

		if 3.10 { // regrouping for BMI
			capture drop bmi
			gen bmi = bmxbmi
			label variable bmi "Body-Mass Index kg/m^2"
		}

		if 3.11 { // regrouping for glycohemoglobin
			// this information may have relatively high missingness
			capture drop ghb
			gen ghb = lbxgh
			label variable ghb "GLycated Hemoglobin %"
		}

		if 3.12 { // regrouping for self-rated health
			capture drop hs
			gen hs = huq010
			replace hs = . if hs == 7 | hs == 9 
			capture label drop hs
			label define hs 1 "Excellent" 2 "Very Good" 3 "Good" 4 "Fair" 5 "Poor" 7 "Refused" 9 "Don't Know"
			label values hs hs
			label variable hs "Self-Rated Health"
		}

		if 3.13 { // regrouping for need more support
			capture drop support
			gen support = .
			replace support = min(ssq030, ssd031, ssq031)
			replace support = . if support != 1 & support != 2
			replace support = 0 if support == 2

			capture label drop support
			label define support 0 "No" 1 "Yes"
			label variable support "Need More Support"
			label values support support
		}

		if 3.14 { // regrouping for anyone to help with emotional support
			// coded specially as 0 - yes, 1 - no, 2 - no need
			// based on the consideration that the outcome is getting less support
			capture drop emo_support
			gen emo_support = .
			replace emo_support = min(ssq010, ssd011, ssq011)
			replace emo_support = . if emo_support == 7 | emo_support == 9
			replace emo_support = emo_support - 1

			capture label drop emo_support
			label define emo_support 0 "Yes" 1 "No" 2 "No Need"
			label variable emo_support "Anyone to Help with Emotional Support"
			label values emo_support emo_support
		}

        if 3.15 { // regrouping for stroke history
            capture drop stroke
            gen stroke = .
            replace stroke = 1 if mcq160f == 1
            replace stroke = 0 if mcq160f == 2

            capture label drop stroke
            label define stroke 0 "No" 1 "Yes"
            label variable stroke "Stroke History"
            label values stroke stroke
        }

        if 3.16 { // regrouping for depression
            // ciqd001 - Had sad, empty, depressed for 2 week period in past 12 months?
            // !!! WARNING: ciqd001 only applied to survey cycle before 2003 !!!
            // ciqd001 has significant missingness and may consider to drop 1999 - 2002 if doing depression
            // dpq020 - Feeling down, depressed, or hopeless?
            /* dpq020 was coded differently as:
                    0 - Not at all
                    1 - Several days
                    2 - More than half the days
                    3 - Nearly every day
                *** currently, all patients with dpq020 > 0 were considered as yes ***
            */
			/*
			Disregard previous information.
			DPQ is more available in later years from year 2005 and later
			the whole DPQ is a PHQ-9 test
			for each varaible: DPQ010-DPQ090:
			0 - Not at all - score 0
			1 - Several days - score 1
			2 - More than half the days - score 2
			3 - Nearly day - score 3
			7/9/. - Missing

			Sum all these info together to get the total score
			0-4: No depression
			5-9: Mild depression
			10-14: Moderate depression
			15-19: Moderately severe depression
			>=20: Severe depression

			Besides these categories, establish a new var to be binary, classifying all above normal as depressive
			depression:
			0 - No
			1 - Yes
			*/
			capture drop dpq_score
			gen dpq_score = .
			replace dpq_score = dpq010 + dpq020 + dpq030 + dpq040 + dpq050 + dpq060 + dpq070 + dpq080 + dpq090
			label variable dpq_score "Depression Score"

            capture drop depression
            gen depression = .
            replace depression = 1 if !missing(dpq_score) & dpq_score >= 5
			replace depression = 0 if inrange(dpq_score, 0, 5)

            capture label drop depression
            label define depression 0 "No" 1 "Yes"
            label variable depression "Depression"
            label values depression depression

			// add in an variable to indicate depression type
			capture drop depression_type
			gen depression_type = .
			replace depression_type = 0 if dpq_score >= 0 & dpq_score < 5
			replace depression_type = 1 if dpq_score >= 5 & dpq_score < 10
			replace depression_type = 2 if dpq_score >= 10 & dpq_score < 15
			replace depression_type = 3 if dpq_score >= 15 & dpq_score < 20
			replace depression_type = 4 if dpq_score >= 20 & !missing(dpq_score)
			label variable depression_type "Depression Type"

			capture label drop depression_type
			label define depression_type 0 "No Depression" 1 "Mild Depression" 2 "Moderate Depression" 3 "Moderately Severe Depression" 4 "Severe Depression"
			label values depression_type depression_type
        }
	}
	drop bpxsar_helper bpxdar_helper

	if 4 {
		// saving proper dataset
		preserve
		keep if survey < 2009
		noi save nhanes_2007_support, replace
		restore

		preserve
		keep if survey >= 2005
		noi save nhanes_2018_depression, replace
		restore
	}
	
}