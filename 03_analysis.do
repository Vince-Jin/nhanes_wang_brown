qui {
    if 1 {
		// setting up the environment
        // check if setup is already done
		
        if ("${root}" == "") {
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
	}

    if 2 {
        // loading the dataset
        use "nhanes_2007_support", clear
    }

    if 3 {
        // set up some output folder
        global output_folder "${root}output${slash}"
        capture mkdir output
        capture cd "${output_folder}"
        if !(_rc) {
            noi di "output folder successfully created"
        }
        capture mkdir figures
        capture cd "${output_folder}figures"
        if !(_rc) {
            noi di "figures sub-folder successfully created"
        }
        cd "${output_folder}"
        capture mkdir tables
        capture cd "${output_folder}tables"
        if !(_rc) {
            noi di "tables sub-folder successfully created"
        }
    }

    if 4 {
        // load in the table 1 program
        if 4.1 {
            qui {
                capture program drop table1_fena
                program define table1_fena

                    qui {
                        
                        syntax [if] [, var(string) by(varname) title(string) excel(string) catt(int 15) missingness order(string)]
                        
                        // first detect varaible type
                        if 1 {
                            noi di "Detecting Variable Types"
                            // in case only by variable was specified
                            if (("`by'" != "") & ("`var'" == "")) {
                                ds
                                local var_helper = r(varlist)
                                local var : di stritrim(subinstr("`var_helper'", "`by'", "", .))
                            }
                            noi var_type, var(`var') catt(`catt')
                            if (strupper("${terminator}") == "EXIT") {
                                exit
                            }				
                            if (strupper("${terminator}") != "EXIT") {
                                noi missing_detect, v(${terminator})
                            }
                            
                            // double verify the variable types 
                            // ask for user input
                            noi di "Please indicate variables to modify, separated by space (e.g.: aaa bbb ccc)"
                            noi di "Press enter to skip modification", _request(var_change)
                            if ("${var_change}" != "") {
                                local bstring : di "${bin}"
                                local castring : di "${cat}"
                                local costring : di "${con}"
                                foreach i in ${var_change} {
                                    
                                    noi di "Please enter the correct variable type for" " variable " "`i'" " (1-binary 2-categorical 3-continuous):", _request(vtype)
                                    
                                    local bstring : di subinstr("`bstring'", "`i'", "", 1)
                                    local castring : di subinstr("`castring'", "`i'", "", 1)
                                    local costring : di subinstr("`costring'", "`i'", "", 1)
                                    
                                    if (${vtype} == 1) {
                                        local bstring : di "`bstring'" " " "`i'"
                                    }
                                    else if (${vtype} == 2) {
                                        local castring : di "`castring'" " " "`i'"
                                    }
                                    else if (${vtype} == 3) {
                                        local costring : di "`costring'" " " "`i'"
                                    }
                                    
                                    local bstring : di stritrim(strtrim("`bstring'"))
                                    local castring : di stritrim(strtrim("`castring'"))
                                    local costring : di stritrim(strtrim("`costring'"))

                                    
                                }
                                global bin `bstring'
                                global cat `castring'
                                global con `costring'
                                noi di "Current Variable Types: "
                                noi di "Binary Variables:"
                                noi di "${bin}"
                                noi di "Categorical Variables: "
                                noi di "${cat}"
                                noi di "Continuous Variables: "
                                noi di "${con}"
                            }
                            
                            // call the table1 program generate table 1
                            noi di as error "Generating Table1"
                            noi table1_creation `if', bin(${bin}) cat(${cat}) con(${con}) title(`title') excel(`excel') by(`by') `missingness' orders(`var')
                            noi di ""
                            noi di as error "Table 1 saved as `excel' to the following directory:"
                            noi di in g "`c(pwd)'"
                        }
                        
                    }

                end
            }

            qui {
                
                capture program drop var_type
                program define var_type
                
                    qui {
                        
                        // determine the type of each variable being taken in
                        // should take list of variables
                        // default should be everything
                        // end product:
                        // three global macro to for binary, categorical, continuous variables
                        syntax [, var(string) catt(int 15)]
                        
                        // sets up proper variable list for action
                        if ("`var'" != "") {
                            local vlist `var'
                        } 
                        else if ("`var'" == "") {
                            ds
                            local vlist `r(varlist)'
                        }
                        
                        // determine if any of the variable specified is not in the dataset
                        noi missing_detect, v(`vlist')

                        if (strupper("${terminator}") == "EXIT") {
                            noi di as error "WARNING: User Requested To Terminate The Program"
                            exit
                        }
                        else {
                            local vlist ${terminator}
                        }

                        // create returning global macros
                        global bin
                        global cat
                        global con
                        global tran
                        
                        // start to detect
                        foreach i in `vlist' {
                            /*
                            levelsof `i', local(l1) s("!*!")
                            
                            local l2 : di subinstr(`"`l1'"', "!*!", "", .)
                            local ln1 = strlen(`"`l1'"')
                            local ln2 = strlen(`"`l2'"')
                            local ln_diff = (`ln1' - `ln2') / 3
                            */
                            local ln_diff = -1
                            levelsof `i', local(l1)
                            foreach var_val in `l1' {
                                local ln_diff = `ln_diff' + 1
                            }
                            
                            if (`ln_diff' == 1 | `ln_diff' < 1) {
                                global bin : di "${bin}" " " "`i'"
                            }
                            else if (`ln_diff' > 1 & `ln_diff' < (`catt')) {
                                global cat : di "${cat}" " " "`i'"
                            }
                            else if (inrange(`ln_diff', (`catt' - 1), (`catt' - 1 + 15))) {
                                global tran : di "${tran}" " " "`i'"
                                global cat : di "${cat}" " " "`i'"
                            }
                            else {
                                global con : di "${con}" " " "`i'"
                            }
                            
                        }
                        
                        // display results
                        noi di "Detected binary variables: "
                        noi di "${bin}"
                        noi di "Detected categorical variables: "
                        noi di "${cat}"
                        noi di "Detected continuous variables: "
                        noi di "${con}"
                        
                        if ("${tran}" != "") {
                            noi di as error "WARNING: Variables Require User Attention"
                            noi di in g "${tran}"
                        }
                        
                        
                    }
                
                end
                
                capture program drop missing_detect
                program define missing_detect
                    qui {
                        syntax, v(string)
                        ds
                        local testing `r(varlist)'
                        local missing
                        foreach i in `v'{	
                            if (strpos("`testing'", "`i'") == 0) {
                                local missing : di "`missing'" " " "`i'"
                                
                            }
                        }
                        
                        if ("`missing'" == "") {
                            noi di in g "Variable check cleared"
                            global terminator `v'
                        }
                        else if ("`missing'" != "") {				
                            noi di ""
                            noi di in g "Variables below not found in current dataset: "
                            noi di "`missing'"
                            noi di "Please re-enter variable list for the program"
                            noi di "(Enter exit to terminate the program)", _request(terminator)
                            
                            if (strupper("${terminator}") == "EXIT") {
                                exit
                            }				
                            if (strupper("${terminator}") != "EXIT") {
                                noi missing_detect, v(${terminator})
                            }
                            
                        }
                    }
                end
                
            }

            qui {
                capture program drop ind_translator
                program define ind_translator
                    syntax, row(int) col(int)

                    // tokenize the alphabet
                    local alphabet "`c(ALPHA)'"
                    tokenize `alphabet'
                    // now translate col
                    local col_helper = `col'
                    
                    
                    while (`col_helper' > 0) {
                        local temp_helper2 = (`col_helper' - 1)
                        local temp_helper = mod(`temp_helper2', 26) + 1
                        local col_name : di "``temp_helper''" "`col_name'"
                        local col_helper = (`col_helper' - `temp_helper') / 26
                    } 
                    
                    
                    // generate a global macro that can be used in main program
                    global ul_cell "`col_name'`row'"
                    
                end
            }

            qui {
                capture program drop table1_creation
                program define table1_creation

                    syntax [if] [, title(string) bin(string) cat(string) con(string) foot(string) by(varname) excel(string) missingness orders(string)]
                    
                    qui {
                        
                        preserve
                        
                        // check if
                        if ("`if'" != "") {
                            keep `if'
                        }
                        
                        // grant default value to excel and title
                        if 2 {
                            if ("`title'" == "") {
                                local title : di "Table 1: Demographics"
                            }
                            if ("`excel'" == "") {
                                local excel : di "Table 1 Outputs"
                            }
                            if ("`orders'" == "") {
                                ds
                                local orders `r(varlist)'
                            }
                        }
                        
                        // generate excel file
                        if 3 {
                            putexcel set "`excel'", replace
                        }
                        
                        // prepare excel row/col
                        if 4 {
                            local erc = 1
                            local ecc = 1
                            global ind : di "ind_translator, row(" "`" "erc" "'" ") col(" "`" "ecc" "'" ")"
                        }
                        
                        // prepare indentation
                        if 5 {
                            local col1: di "_col(40)"
                            local col2: di "_col(50)"
                            local cfac = 20
                            local csep = 60
                        }
                        
                        // run byvar checker
                        if 7 {
                            local dual_screener = 0
                            local var_screener `con' `bin' `cat'
                            foreach var in `var_screener' {
                                if ("`by'" == "`var'") {
                                    local dual_screener = 1
                                }
                            }
                            if (`dual_screener' == 1) {
                                noi di as error "ERROR: The stratifying variable should not be inputted as table 1 variable"
                                noi di in g " "
                                exit
                            }
                        }
                        
                        // get title line and total N
                        if 6 {
                            noi di in g "`title'"
                            ind_translator, row(`erc') col(`ecc')
                            putexcel ${ul_cell} = "`title'"
                            noi di "N=" "`c(N)'"
                            local erc = `erc' + 1
                            ${ind}
                            putexcel ${ul_cell} = "N=`c(N)'"
                        }
                        
                        // deal with byvar
                        local by01 = 1
                        if ("`by'" == "") {
                            // capture drop byvar_helper
                            gen byvar_helper = 1
                            local by byvar_helper
                            local by01 = 0
                        }

                        // run through byvar
                        if 8 {
                            levelsof `by'
                            local b_vals = r(levels)
                            /* for now:
                            if no byvar - b_vals = 1
                            if byvar - b_vals = r(levels)
                            */
                            // gather label information to print out byvar line
                            local by_l : value label `by'
                            // print out by line
                            local cheader = 0
                            // detect byvar type
                            local bstringvar = 1
                            local b_if : di ("`" + "by" + "'" + " == " + `"""' +"`" + "k" + "'" + `"""') 
                            qui capture confirm string var `by'
                            if _rc {
                                local bstringvar = 0
                                local b_if : di ("`" + "by" + "'" + " == " + "`" + "k" + "'")
                            }
                            
                            if ("`by'" != "byvar_helper") {
                                local erc = `erc' + 1
                                foreach i in `b_vals' {
                                    local cheader = `cheader' + 1
                                    local ctemp = `csep' +  `cfac' * (`cheader' - 1)
                                    local col_s : di "_col(`ctemp')"
                                    local ecc = `ecc' + 1
                                    // detect if value label exist
                                    // if yes, label value i
                                    // if no, keep i
                                    if ("`by_l'" == "") {
                                        local val_lab : di "`i'"
                                    }
                                    else if ("`by_l'" != "") {
                                        local val_lab : label `by_l' `i'
                                    }
                                    if (`bstringvar' == 1) {
                                        count if `by' == "`i'"
                                    }
                                    else {
                                        count if `by' == `i'
                                    }
                                    local total = r(N)
                                    noi di `col_s'  "`val_lab'" " " "(n=`total')", _continue
                                    ${ind}
                                    putexcel ${ul_cell} = "`val_lab' (n=`total')"
                                }
                                noi di ""
                            }
                            local ecc = 1
                            local cheader = 0
                            // get some constant for byvar
                            foreach i in `b_vals' {
                                if (`bstringvar' == 1) {
                                    count if `by' == "`i'"
                                }
                                else {
                                    count if `by' == `i'
                                }
                                local cnt`i' = r(N)
                            }
                        }
                        
                        // run through continuous variable
                        local bincat `bin' `cat'
                        foreach var in `orders' {
                            if (strpos("`con'", "`var'") != 0) {
                                // print out the variable
                                // first detect if variable label exist
                                local var_l : variable label `var'
                                if ("`var_l'" == "") {
                                    local var_lab : di "`var'"
                                }
                                else if ("`var_l'" != "") {
                                    local var_lab : di "`var_l'"
                                }
                                // no need to detect value label since it is continuous
                                noi di "`var_lab'" ", median[IQR]", _continue
                                local erc = `erc' + 1
                                ${ind}
                                putexcel ${ul_cell} = "`var_lab', median[IQR]"
                                // detect if string var accidentally got into cont vars
                                local stringvar = 1
                                qui capture confirm string var `var'
                                if _rc {
                                    local stringvar = 0
                                }
                                if (`stringvar' == 1) {
                                    local ctemp = `csep'
                                    local col_s : di "_col(`ctemp')"
                                    noi di as error `col_s' "`var' is in string format and not valid as continuous variables", _continue
                                    local ecc = `ecc' + 1
                                    ${ind}
                                    putexcel ${ul_cell} = "`var' is in string format and not valid as continuous variables"
                                }
                                else {
                                    local cheader = 0
                                    // loop through byvar is enough
                                    foreach k in `b_vals' {
                                        local cheader = `cheader' + 1
                                        sum `var' if `b_if', detail
                                        local med = r(p50)
                                        local lq = r(p25)
                                        local hq = r(p75)
                                        local m_iqr : di %2.1f `med' "[" %2.1f `lq' ", " %2.1f `hq' "]"
                                        local ctemp = `csep' + `cfac' * (`cheader' - 1)
                                        local col_s : di "_col(`ctemp')"
                                        noi di `col_s' "`m_iqr'", _continue
                                        local ecc = `ecc' + 1
                                        ${ind}
                                        putexcel ${ul_cell} = "`m_iqr'"
                                    }
                                }
                                noi di in g ""
                                local ecc = 1
                            }
                            else if (strpos("`bincat'", "`var'") != 0) {
                                // run through binary and categorical variable
                                // print out the variable
                                // first detect if variable label exist
                                
                                // detect if this var is string or not
                                local stringvar = 1
                                qui capture confirm string var `var'
                                if _rc {
                                    local stringvar = 0
                                }
                                
                                local var_l : variable label `var'
                                if ("`var_l'" == "") {
                                    local var_lab : di "`var'"
                                }
                                else if ("`var_l'" != "") {
                                    local var_lab : di "`var_l'"
                                }
                                // then detect if value label exist
                                local val_l01 = 0
                                local val_l : value label `var'
                                if ("`val_l'" != "") {
                                    local val_l01 = 1
                                }
                                else if ("`val_l'" == "") {
                                    local val_l01 = 0
                                }
                                noi di "`var_lab'" ", n(%)"
                                local erc = `erc' + 1
                                ${ind}
                                putexcel ${ul_cell} = "`var_lab', n(%)"
                                // print out each value line
                                levelsof `var'
                                local var_levels = r(levels)
                                foreach j in `var_levels' {
                                    // zero out column counter to ensure columns align appropriately
                                    local cheader = 0
                                    if (`val_l01' == 1) {
                                        local val_lab : label `val_l' `j'
                                    }
                                    else if (`val_l01' == 0) {
                                        local val_lab : di "`j'"
                                    }
                                    // print j value
                                    noi di _col(4) "`val_lab'", _continue
                                    local erc = `erc' + 1
                                    ${ind}
                                    putexcel ${ul_cell} = "    `val_lab'"
                                    // count and percentage
                                    foreach k in `b_vals' {
                                        if `stringvar' == 1 {
                                            count if `var' == "`j'" & `b_if'
                                        }
                                        else {
                                            count if `var' == `j' & `b_if'
                                        }
                                        local cnt = r(N)
                                        local per = `cnt' / `cnt`k'' * 100
                                        // assemble count and per
                                        local cp : di "`cnt'(" %2.1f `per' ")"
                                        // print out cnt and per
                                        local cheader = `cheader' + 1
                                        local ctemp = `csep' +  `cfac' * (`cheader' - 1)
                                        local col_s : di "_col(`ctemp')"
                                        noi di `col_s' "`cp'", _continue
                                        local ecc = `ecc' + 1
                                        ${ind}
                                        putexcel ${ul_cell} = "`cp'"
                                    }
                                    noi di ""
                                    local ecc = 1
                                }
                            }
                            
                        }
                        
                        // missingness
                        if ("`missingness'" == "missingness") {
                            noi di ""
                            local erc = `erc' + 1
                            noi di in g "Missingness Information: "
                            local erc = `erc' + 1
                            local ecc = 1
                            ${ind}
                            putexcel ${ul_cell} = "Missingness Information: "
                            local mis_var `bin' `cat' `con'
                            foreach var in `mis_var' {
                                // display variable name
                                local var_l : variable label `var'
                                if ("`var_l'" == "") {
                                    local var_lab : di "`var'"
                                }
                                else if ("`var_l'" != "") {
                                    local var_lab : di "`var_l'"
                                }
                                noi di "`var_lab'", _continue
                                local erc = `erc' + 1
                                local ecc = 1
                                ${ind}
                                putexcel ${ul_cell} = "`var_lab'"
                                // display missingness
                                count if missing(`var')
                                local mis = r(N)
                                local mis_per = `mis' / `c(N)' * 100
                                local mis_per : di %3.2f `mis_per' "% missing"
                                noi di _col(`csep') "`mis_per'"
                                local ecc = `ecc' + 1
                                ${ind}
                                putexcel ${ul_cell} = "`mis_per'"
                            }
                        }
                    
                    capture restore
                    
                    }
                    
                end
            }
        }
    }

    if 5 {
        // some basic statistics
        capture cd "${output_folder}tables"
        if 5.1 {
            // table 1
            noi table1_fena, var(support emo_support age race gender education bmi hs hypertension diabete survey) by(stroke) missingness title("Table 1: Participants Characteristics By Stroke History At Survey For NHANES 1999-2008") excel("table1_support.xlsx")
        }
		if 5.2 {
			// table 1 for only have support persons
			preserve
			qui count if missing(support)
			local mis_n = `r(N)'
			noi di "Creating Table 1 For Those Answered Support Question"
			keep if !missing(support)
			noi di "`mis_n' person dropped"
			noi table1_fena, var(support emo_support age race gender education bmi hs hypertension diabete survey) by(stroke) missingness title("Table 1: Participants Characteristics By Stroke History At Survey For NHANES 1999-2008") excel("table1_support_only.xlsx")
			restore
		}
		capture cd "${root}"
    }
	
	if 6 {
		// preliminary regression
		capture cd "${output_folder}tables"
		if 6.1 {
			preserve
			keep if !missing(support)
			global bin : di strtrim(stritrim(subinstr(subinstr("${bin}", "support", "", .), "emo_", "", .)))
			global cat : di strtrim(stritrim(subinstr("${cat}", "survey", "", .)))
			local str_temp
			foreach i in $bin {
				local str_temp : di `"`str_temp'"' " " `"i.`i'"'
			}
			local str_temp2
			foreach i in $cat {
				local str_temp2 : di `"`str_temp2'"' " " `"i.`i'"'
			}
			local vars ${con} `str_temp' `str_temp2' 
			noi di "vars = `vars'"
			
			noi logit support i.stroke `vars'
			matrix log_mt = r(table)'
			
			putexcel set logit_support, replace
			
			putexcel A1 = matrix(log_mt), names
			
			noi logit support i.stroke `vars', or
			matrix log_mt = r(table)'
			local support_n = `e(N)'
			
			putexcel set logit_support_or, replace
			
			putexcel A1 = matrix(log_mt), names
			
			restore
			
		} 
		capture cd "${root}"
		
		if 6.2 {
			// assemble a Table 2
			capture cd "${output_folder}tables"
			
			// load in ind_translator
			capture program drop ind_translator
			program define ind_translator
				syntax, row(int) col(int)

				// tokenize the alphabet
				local alphabet "`c(ALPHA)'"
				tokenize `alphabet'
				// now translate col
				local col_helper = `col'
				
				
				while (`col_helper' > 0) {
					local temp_helper2 = (`col_helper' - 1)
					local temp_helper = mod(`temp_helper2', 26) + 1
					local col_name : di "``temp_helper''" "`col_name'"
					local col_helper = (`col_helper' - `temp_helper') / 26
				} 
				
				
				// generate a global macro that can be used in main program
				global ul_cell "`col_name'`row'"
				
			end
			
			// establish a new program to automatically do table 2
			capture program drop table2
			program define table2
				qui {
                    syntax , out(string) exp(string) exp_type(int) var(string) mat(string) n(int) [title(string) excel(string) decimal(int 2)]
                    
                    // general set up for the program
                    local row = 1
                    local col = 1
                    local deci1 = `decimal' + 1
                    local dec_format : di `"%`deci1'.`decimal'f"'
                    
                    // check if title is missing, assign a default one if yes
                    if ("`title'" == "") {
                        local title : di "Table 2: Regression Results"
                    }
                    
                    // check if excel name is missing, assign a default one if yes
                    if ("`excel'" == "") {
                        local excel : di "table2"
                    }
                    
                    // set up the excel file
                    putexcel set `excel', replace
                    
                    // output title
                    putexcel A1 = "`title'"
                    
                    local col = 1
                    local row = `row' + 1
                    
                    ind_translator, row(`row') col(`col')
                    
                    putexcel ${ul_cell} = "Total Number (N) = `n'"
                    
                    local row = `row' + 1
                    
                    // output col names
                    ind_translator, row(`row') col(`col')
                    putexcel ${ul_cell} = "Covariates"
                    
                    local col = `col' + 1
                    ind_translator, row(`row') col(`col')
                    putexcel ${ul_cell} = "Prevalence Odds Ratio"
                    
                    local col = `col' + 1
                    ind_translator, row(`row') col(`col')
                    putexcel ${ul_cell} = "95% Confidence Interval"

                    local col = 1
                    local row = `row' + 1

                    // extract number of lines in matrix for this exposure
                    local mat_row_names : rownames `mat'
                    
                    // output the exposure variable
                    // exp_type 1 = binary, 2 = categorical, 3 = continuous
                    if (`exp_type' == 1 | `exp_type' == 2) {
                    
                        // binary exposure
                        ind_translator, row(`row') col(`col')
                        local var_lab : variable label `exp'
                        local val_lab : value label `exp'
                        if ("`var_lab'" == "") {
                            local var_lab : di "`exp'"
                        }
                        putexcel ${ul_cell} = "`var_lab'"

                        local row = `row' + 1
                        
                        levelsof `exp', local(l1)
                        
                        local level_ct = 0
                        local level_holder
                        foreach i in `mat_row_names' {

                            if (strpos("`i'", "`exp'") != 0) {
                                local level_ct = `level_ct' + 1
                                local level_holder `level_holder' `i'
                            }
                            
                        }

                        forvalue i = 1/`level_ct' {
                            // extract the elements from the macros
                            local val_num : di word("`l1'", `i')

                            local val_str : di word("`level_holder'", `i')

                            // all val_str should be in a format of outcome:x.exposure
                            // now remove the string part before the colon
                            local val_str : di subinstr("`val_str'", "`out':", "", .)
                            // now decompose the val_str into two parts, before and after the dot
                            // first get the position of the dot
                            local dot_pos = strpos("`val_str'", ".")

                            // now extract the two parts
                            local val_str1 : di substr("`val_str'", 1, `dot_pos' - 1)
                            local val_str2 : di substr("`val_str'", `dot_pos' + 1, .)

                            // check if there is a letter "b" in val_str1
                            local base = 0
                            if (strpos("`val_str1'", "b") != 0) {
                                local base = 1
                            }
                            local val_str : label `val_lab' `val_num'

                            ind_translator, row(`row') col(`col')

                            putexcel ${ul_cell} = "        `val_str'"

                            // if base is 1, then this is the reference level
                            // output the base level indicator into the columns
                            if (`base' == 1) {
                                local col = `col' + 1
                                ind_translator, row(`row') col(`col')
                                putexcel ${ul_cell} = "Ref"
                                local col = `col' + 1
                                ind_translator, row(`row') col(`col')
                                putexcel ${ul_cell} = "Ref"
                            }
                            else {
                                local col = `col' + 1
                                ind_translator, row(`row') col(`col')
                                local or = `mat'[`"`out':`val_str1'.`val_str2'"', 1]
                                local or : di `dec_format' `or'
                                
                                local ll = `mat'[`"`out':`val_str1'.`val_str2'"', 5]
                                local ll : di `dec_format' `ll'
                                local ul = `mat'[`"`out':`val_str1'.`val_str2'"', 6]
                                local ul : di `dec_format' `ul'
                                local ci : di `"(`ll', `ul')"'
                                if !inrange(1, `ll', `ul') {
                                    local or : di "`or'" "*"
                                }
                                putexcel ${ul_cell} = "`or'"
                                local col = `col' + 1
                                ind_translator, row(`row') col(`col')
                                putexcel ${ul_cell} = "`ci'"  
                            }

                            local row = `row' + 1
                            local col = 1

                            // extract the odds ratio and confidence interval from the matrix
                            // beta(OR) = `mat'[x, 1]
                            // ll = `mat'[x, 5]
                            // ul = `mat'[x, 6]


                        }

                    }
                    else if (`exp_type' == 3) {
                    
                        // continuous exposure
                        ind_translator, row(`row') col(`col')
                        local var_lab : variable label `exp'
                        if ("`var_lab'" == "") {
                            local var_lab : di "`exp'"
                        }
                        putexcel ${ul_cell} = "`var_lab'"
                        
                        // output the or and ci
                        local or = `mat'["`out':`exp'", 1]
                        local or : di `dec_format' `or'
                        local ll = `mat'["`out':`exp'", 5] 
                        local ll : di `dec_format' `ll'
                        local ul = `mat'["`out':`exp'", 6]
                        local ul : di `dec_format' `ul'
                        local ci : di `"(`ll', `ul')"'
                        if !inrange(1, `ll', `ul') {
                            local or : di "`or'" "*"
                        }
                        local col = `col' + 1
                        ind_translator, row(`row') col(`col')
                        putexcel ${ul_cell} = "`or'"
                        local col = `col' + 1
                        ind_translator, row(`row') col(`col')
                        putexcel ${ul_cell} = "`ci'"

                        local row = `row' + 1
                        local col = 1

                    }

                    // now proceed to the variable part
                    // loop through variable stored in `var'
                    foreach i in `var' {
                        // first check for variable type by counting occurence in matrix row names
                        local var_type_helper = 0
                        foreach j in `mat_row_names' {
                            if (strpos("`j'", "`i'") != 0) {
                                local var_type_helper = `var_type_helper' + 1
                                // if var_type_helper > 1, then this is a categorical variable
                            }
                        }
                        if (`var_type_helper' > 1) {
                            local var_type = 1
                        }
                        else if (`var_type_helper' == 1) {
                            local var_type = 0
                        }
                        // now that var_type = 1 indicate categorical variable
                        // and var_type = 0 indicate continuous variable
                        // proceed to output the variable
                        if (`var_type' == 1) {
                            // first deal with categorical variables
                            // print out the name of the variable
                            ind_translator, row(`row') col(`col')
                            local var_l : variable label `i'
                            if ("`var_l'" == "") {
                                local var_lab : di "`i'"
                            }
                            else if ("`var_l'" != "") {
                                local var_lab : di "`var_l'"
                            }
                            local val_lab : value label `i'
                            putexcel ${ul_cell} = "`var_lab'"
                            local row = `row' + 1
                            // now get the levels of the variable
                            levelsof `i', local(l1)
                            local level_ct = 0
                            local level_holder
                            foreach k in `mat_row_names' {

                                if (strpos("`k'", "`i'") != 0) {
                                    local level_ct = `level_ct' + 1
                                    local level_holder `level_holder' `k'
                                }
                                
                            }
                            forvalue j = 1/`level_ct' {
                                // extract the elements from the macros
                                local val_num : di word("`l1'", `j')

                                local val_str : di word("`level_holder'", `j')

                                // all val_str should be in a format of outcome:x.exposure
                                // now remove the string part before the colon
                                local val_str : di subinstr("`val_str'", "`out':", "", .)
                                // now decompose the val_str into two parts, before and after the dot
                                // first get the position of the dot
                                local dot_pos = strpos("`val_str'", ".")

                                // now extract the two parts
                                local val_str1 : di substr("`val_str'", 1, `dot_pos' - 1)
                                local val_str2 : di substr("`val_str'", `dot_pos' + 1, .)

                                // check if there is a letter "b" in val_str1
                                local base = 0
                                if (strpos("`val_str1'", "b") != 0) {
                                    local base = 1
                                }
                                local val_str : label `val_lab' `val_num'
                                ind_translator, row(`row') col(`col')
                                putexcel ${ul_cell} = "        `val_str'"
                                // if base is 1, then this is the reference level
                                if (`base' == 1) {
                                    local col = `col' + 1
                                    ind_translator, row(`row') col(`col')
                                    putexcel ${ul_cell} = "Ref"
                                    local col = `col' + 1
                                    ind_translator, row(`row') col(`col')
                                    putexcel ${ul_cell} = "Ref"

                                    local row = `row' + 1
                                    local col = 1
                                }
                                else {
                                    local col = `col' + 1
                                    ind_translator, row(`row') col(`col')
                                    local or = `mat'[`"`out':`val_str1'.`val_str2'"', 1]
                                    local or : di `dec_format' `or'
                                    
                                    local ll = `mat'[`"`out':`val_str1'.`val_str2'"', 5]
                                    local ll : di `dec_format' `ll'
                                    local ul = `mat'[`"`out':`val_str1'.`val_str2'"', 6]
                                    local ul : di `dec_format' `ul'
                                    local ci : di `"(`ll', `ul')"'
                                    if !inrange(1, `ll', `ul') {
                                        local or : di "`or'" "*"
                                    }
                                    putexcel ${ul_cell} = "`or'"
                                    local col = `col' + 1
                                    ind_translator, row(`row') col(`col')
                                    putexcel ${ul_cell} = "`ci'"

                                    local row = `row' + 1
                                    local col = 1
                                }
                            }
                        }
                        else if (`var_type' == 0) {
                            // then deal with continuous variables
                            // print out the name of the variable
                            ind_translator, row(`row') col(`col')
                            local var_l : variable label `i'
                            local val_lab : value label `i'
                            if ("`var_l'" == "") {
                                local var_lab : di "`i'"
                            }
                            else if ("`var_l'" != "") {
                                local var_lab : di "`var_l'"
                            }
                            putexcel ${ul_cell} = "`var_lab'"
                            // for continuous vars, print or and ci on the same line
                            local or = `mat'["`out':`i'", 1]
                            local or : di `dec_format' `or'
                            local ll = `mat'["`out':`i'", 5]
                            local ll : di `dec_format' `ll'
                            local ul = `mat'["`out':`i'", 6]
                            local ul : di `dec_format' `ul'
                            local ci : di `"(`ll', `ul')"'
                            if !inrange(1, `ll', `ul') {
                                local or : di "`or'" "*"
                            }
                            local col = `col' + 1
                            ind_translator, row(`row') col(`col')
                            putexcel ${ul_cell} = "`or'"
                            local col = `col' + 1
                            ind_translator, row(`row') col(`col')
                            putexcel ${ul_cell} = "`ci'"
                            local row = `row' + 1
                            local col = 1
                        }
                    }

                    // adding in a footnote
                    local row = `row' + 2
                    ind_translator, row(`row') col(`col')
                    putexcel ${ul_cell} = "* indicates that the 95% confidence interval does not overlap with the null value."

                    noi di as error "Excel file `excel' succesfully saved to `c(pwd)'"
					noi di in g " "
                }
			end
		}

        // now calls for the table2 program to output the regression results
        if 6.3 {
            // first assemble the correct variable list
            local table2_vars : di subinstr("`vars'", "i.", "", .)
            // now the table2 program should take the following arguments:
            // out: support
            // exp: stroke
            // exp_type: 1 (binary)
            // var: `table2_vars'
            // mat: log_mt
            // n: `support_n'
            // title: "Table 2: Adjusted Prevalence Odds Ratios For Needing More Emotional Support In The Past 12 Months By Stroke History For NHANES Population 1999-2008"
            // excel: "table2_support.xlsx"
            // make sure we are in the proper directory
            capture cd "${output_folder}tables"
            noi table2, out(support) exp(stroke) exp_type(1) var(`table2_vars') mat(log_mt) n(`support_n') title("Table 2: Adjusted Prevalence Odds Ratios For Needing More Emotional Support In The Past 12 Months By Stroke History For NHANES Population 1999-2008") excel("table2_support.xlsx") decimal(2)
			
			capture cd "${root}"
        }
	}

    if 7 {
        // now move to depression analysis
        if 7.1 {
            // load in depression dataset
            use "nhanes_2018_depression.dta", clear
        }

        if 7.2 {
            // table 1 creation
            // some basic statistics
            capture cd "${output_folder}tables"
            if 5.1 {
                // table 1
                noi table1_fena, var(depression depression_type age race gender education bmi hs hypertension diabete survey) by(stroke) missingness title("Table 1: Participants Characteristics By Stroke History At Survey For NHANES 2005-2018") excel("table1_depression.xlsx")
            }
            if 5.2 {
                // table 1 for only have support persons
                preserve
                qui count if missing(depression)
                local mis_n = `r(N)'
                noi di "Creating Table 1 For Those Answered Depression Question"
                keep if !missing(depression)
                noi di "`mis_n' person dropped"
                noi table1_fena, var(depression depression_type age race gender education bmi hs hypertension diabete survey) by(stroke) missingness title("Table 1: Participants Characteristics By Stroke History At Survey For NHANES 2005-2018") excel("table1_depression_only.xlsx")
                restore
            }
            capture cd "${root}"
        }

        if 7.3 {
            // regression for depression
            capture cd "${output_folder}tables"
            preserve
            keep if !missing(depression)
            local dep_vars
            foreach i in `vars' {
                if (strpos("`i'", "emo_") == 0) {
                    local dep_vars `dep_vars' `i'
                }
            }
            noi logit depression i.stroke `dep_vars', or
            
            matrix log_mt = r(table)'
			local depression_n = `e(N)'
			
			putexcel set logit_depression_or, replace
			
			putexcel A1 = matrix(log_mt), names

            local table2_vars : di subinstr("`dep_vars'", "i.", "", .)
            // now the table2 program should take the following arguments:
            // out: support
            // exp: stroke
            // exp_type: 1 (binary)
            // var: `table2_vars'
            // mat: log_mt
            // n: `support_n'
            // title: "Table 2: Adjusted Prevalence Odds Ratios For Needing More Emotional Support In The Past 12 Months By Stroke History For NHANES Population 1999-2008"
            // excel: "table2_support.xlsx"
            // make sure we are in the proper directory
            capture cd "${output_folder}tables"
            noi table2, out(depression) exp(stroke) exp_type(1) var(`table2_vars') mat(log_mt) n(`depression_n') title("Table 2: Adjusted Prevalence Odds Ratios For Having PHQ-9 Score Above 4 By Stroke History For NHANES Population 2005-2018") excel("table2_depression.xlsx") decimal(2)
			

            // regression for depression type
            // only outcome changed - vars were the same
            noi ologit depression_type i.stroke `dep_vars', or
            matrix log_mt = r(table)'
            local depression_n = `e(N)'

            putexcel set ologit_depression_type_or, replace
            putexcel A1 = matrix(log_mt), names

            capture cd "${output_folder}tables"
            noi table2, out(depression_type) exp(stroke) exp_type(1) var(`table2_vars') mat(log_mt) n(`depression_n') title("Table 2: Adjusted Prevalence Odds Ratios For Stroke Severity Determined Through PHQ-9 Score By Stroke History For NHANES Population 2005-2018") excel("table2_depression_type.xlsx") decimal(2)

            restore
			capture cd "${root}"
        }
    }
}