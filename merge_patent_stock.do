cd "D:\My Drive\Wei\Patent"
foreach v in ee or{
**Transform csv to dta
*File matching `v'_name to ticker (latest only)
import delimited `v'_matcher.csv,varn(1) clear
gen len=length(`v'_name_unclean)
recast str209 `v'_name_unclean, force //no strL
save `v'_matcher.dta,replace

*raw listed company data file
import delimited stock_raw.csv,varn(1) clear
save stock_raw.dta,replace

*raw patent transfer file
import delimited patent_raw.csv,varn(1) clear
gen len=length(`v'_name_unclean)
recast str209 `v'_name_unclean, force
save patent_raw.dta,replace

**Ticker to permno(based on 2022)
//Data source of Ticker-permno matcher: https://wrds-www.wharton.upenn.edu/query-manager/query/6674801/#payload_formatted_collapsed_section

*Import the ticker-permno matcher download from CRSP
import delimited `v'_ticker2permno_22_latest.csv,varn(1) clear
duplicates tag permno,gen(tag)
drop if tag>=1 //some of permno not unique, which is not supposed to happen
drop tag
save `v'_ticker2permno.dta,replace

**match patent data with ticker
use patent_raw,clear
merge m:m `v'_name_unclean using `v'_matcher.dta,nogen force 
//m:m is ok HERE because switching order of matching company name doesn't effect the data structure

drop if ticker=="" //Drop the ticker that's not found
drop if ticker=="nan" //Drop the ticker that's not found
tostring `v'_name_unclean,replace
drop `v'_name //The clean version of ee name doesn't make any sense now, it's reordered


**Merge patent_ticker data to with permno using ticker2permno file
merge m:1 ticker using `v'_ticker2permno.dta,force
keep if _merge==3
drop _merge
drop date //date is the time on market
save patent_ee,replace //patent_ee contains:`v'_name,ticker,corresponding permno


**Merge raw listed company file with patent_ee usingpermno
use stock_raw,clear
merge 1:m permno using patent_ee.dta,force
keep if _merge==3
count if _merge==3
drop _merge




** Clean the individual's name
//There're many `v'_name that are not company, but individual's name
//They are not suppose to be in the dataset now, since certainly individual is not listed company. They are included due to the API's searching error.
//For a company in the `v'_name_unclean, it must include: INC,CORP,CORPERATION, COMPANY, BANK, GROUP, LLC, AG,CO,LTD, TRUST, L.L.C., LIMITED, ASSOCIATION, CAPITAL, PHARMA, THERAPEUTICS, JOHNSON & JOHNSON (There're 2422 unique `v'_name values, and I check manually that this is enough to eliminate all individuals. JOHNSON & JOHNSON is an exception among them)

//duplicates drop `v'_name_unclean,force //codes help check the pattern of company name

drop if regexm(`v'_name,"INC")==0 & regexm(`v'_name,"CORP")==0 & regexm(`v'_name,"COMPANY")==0 & regexm(`v'_name,"BANK")==0 & regexm(`v'_name,"GROUP")==0 & regexm(`v'_name,"LLC")==0 & regexm(`v'_name,"AG")==0 & regexm(`v'_name,"CO")==0 & regexm(`v'_name,"LTD")==0 & regexm(`v'_name,"TRUST")==0 & regexm(`v'_name,"L.L.C")==0 & regexm(`v'_name,"LIMITED")==0 & regexm(`v'_name,"ASSOCIATION")==0 & regexm(`v'_name,"CAPITAL")==0 & regexm(`v'_name,"PHARMA")==0 & regexm(`v'_name,"THERAPEUTICS")==0 & regexm(`v'_name,"JOHNSON & JHONSON")==0


save stock_`v'_patent_demo.dta,replace


**Further cleaning searching error based on `v'_state information


export delimited stock_`v'_patent_demo.csv,replace //export the result
}

