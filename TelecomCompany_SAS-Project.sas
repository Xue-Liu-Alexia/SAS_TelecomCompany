libname Alexia 'D:\DataScience\SAS\SAS_Library\Alexia';
*import data;
Data Alexia.Telecom;
	infile 'D:\DataScience\SAS\SAS_Project\New_Wireless_Fixed.txt' dlm=' ' termstr=crlf truncover;
	input Acctno $ 1-14 Actdt : mmddyy10.  Deactdt : mmddyy10.  DeactReason $ 41-52 GoodCredit 53-61 
		  RatePlan 62-64 DealerType $ 65-66 Age 74-79 Province $ 80-82 Sales : dollar8.2;
	format Actdt Deactdt mmddyy10. Sales dollar8.2;
Run;
Proc Print data=Alexia.Telecom (obs=20);
Run;
/*==========================================================================================================*/


/* 1.1 */
/* Is the Acctno unique? */
* Method #1 ;
Title "Is the Acctno unique?";
Proc Contents data=Alexia.Telecom;
Run;
Proc Freq data = Alexia.Telecom nlevels;
	table Acctno / noprint;
Run;
* The CONTENTS Procedure shows this data has 102255 Observations.
  The FREQ Procedure shows the Acctno has 102255 Levels, 
  so the Acctno is unique.;

* Method #2 ;
Proc SQL;
	select count(distinct Acctno) as UniqueAccount
	from Alexia.Telecom;
Quit;
* The result is 102255 is consistent with the total number of observations.;


/* What is the number of accounts activated and deactivated? */
* Method #1 ;
Title "The number of activated accounts";
Proc SQL;
	select count(*) as active_accounts
    from Alexia.Telecom
    where Actdt is not null and Deactdt is missing;
Quit;
* The number of activated accounts is 82620. ;
Title "The number of deactivated accounts";
Proc SQL;
    select count(*) as deactivated_accounts
    from Alexia.Telecom
    where Deactdt is not null;
Quit;
* The number of deactivated accounts is 19635. ;

* Method #2 ;
Title "The number of accounts activated and deactivated";
Data Alexia.Acctno_act_deact;
	set Alexia.Telecom end=last;
	if not missing(Actdt) and missing(Deactdt) then activated_accounts + 1;
	if not missing(Deactdt) then deactivated_accounts + 1;
	retain total_activated_accounts total_deactivated_accounts;
	if last then do;
		total_activated_accounts = activated_accounts;
    	total_deactivated_accounts = deactivated_accounts;
    	output;
	end;
	drop activated_accounts deactivated_accounts;
Run;
Proc Print data=Alexia.Acctno_act_deact noobs;
	var total_activated_accounts total_deactivated_accounts;
Run;

* Method #3 ;
Title "The number of accounts activated and deactivated";
Data Alexia.Status_act_deact;
    set Alexia.Telecom;
    if not missing(Deactdt) then Status = 'Deactivated';
    else if not missing(Actdt) and missing(Deactdt) then Status = 'Activated';
    else Status = 'Unknown';
Run;
Proc Print data=Alexia.Status_act_deact (obs=20);
Run;
Proc Freq data=Alexia.Status_act_deact;
    tables status;
Run;


/* When is the earliest and latest activation/deactivation dates available? */
* Method #1 ;
Title "The earliest and latest activation/deactivation dates - Method: Proc Means";
Proc Means data=Alexia.Telecom noprint;
    var Actdt Deactdt;
    output out=EarLatDate
        min(Actdt)=Earliest_Activation_Date max(Actdt)=Latest_Activation_Date
        min(Deactdt)=Earliest_Deactivation_Date max(Deactdt)=Latest_Deactivation_Date;
Run;
Data Alexia.DateSummary;
    set EarLatDate;
    format Earliest_Activation_Date Latest_Activation_Date Earliest_Deactivation_Date Latest_Deactivation_Date mmddyy10.;
Run;
Proc Print data=Alexia.DateSummary noobs;
	var Earliest_Activation_Date Latest_Activation_Date Earliest_Deactivation_Date Latest_Deactivation_Date;
Run;
* The earliest activation date is 01/20/1999
  The earliest deactivation date is 01/25/1999
  The latest activation date is 01/20/2001
  The latest deactivation date is 01/20/2001 ;

* Method #2 ;
Title "The earliest and latest activation/deactivation dates - Method: Proc SQL";
Proc SQL;
    select 
		min(Actdt) as Earliest_Activation_Date format=mmddyy10., 
		max(Actdt) as Latest_Activation_Date format=mmddyy10.,
		min(Deactdt) as Earliest_Deactivation_Date format=mmddyy10., 
		max(Deactdt) as Latest_Deactivation_Date format=mmddyy10.
    from Alexia.Telecom;
Quit;
/*==========================================================================================================*/


/* 1.2 */
/* What are the age and province distributions of activated and deactivated customers? */
Title "What are the age and province distributions of activated and deactivated customers?";
Proc Freq data=Alexia.Status_act_deact nlevels;
    tables Status * Age / nocum  norow nocol;
    tables Status * Province / nocum  ;
Run;
* For each province, the proportion of activated accounts to the overall accounts is 81%.
  Consistency in proportions could reflect business trends or policies. 
  If there are similar market dynamics, customer demographics, or industry trends across provinces, 
  business decisions might lead to a uniform ratio of activated and deactivated accounts.;
Proc Sgplot data=Alexia.Status_act_deact; 
	vbar Province; 
	where Status = 'Activated';
Run;
Proc Sgplot data=Alexia.Status_act_deact; 
	vbar Province; 
	where Status = 'Deactivated';
Run;
Proc Sgplot data=Alexia.Status_act_deact;
	histogram Age;
	density Age;
	where Status = 'Activated';
Run;
Proc Sgplot data=Alexia.Status_act_deact;
	histogram Age;
	density Age;
	where Status = 'Deactivated';
Run;
* Active accounts and deactivate accounts are mainly concentrated in the ON province. 
  Among the provinces, the QC province with the smallest proportion of active accounts and deactivate accounts 
  The overall age is mainly concentrated in the middle-aged crowd;
/*==========================================================================================================*/


/* 1.3 */
/* Segment the customers based on age, province and sales amount:
Sales segment: < $100, $100---500, $500-$800, $800 and above.
Age segments: < 20, 21-40, 41-60, 60 and above. */
Proc Format;
    value salesfmt
		.='Missing'
        low -< 100 = '< $100'
        100 -< 500 = '$100-$500'
        500 -< 800 = '$500-$800'
        800 - high = '$800 and Above';
        
    value agefmt
		.='Missing'
        low -< 20 = '< 20'
        20 -< 41 = '21-40'
        41 -< 61 = '41-60'
        61 - high = '60 and Above';
Run;
* Method #1 ;
Title "Segment the customers based on age, province and sales amount - Method: Proc Tabulate";
Proc Tabulate data=Alexia.Status_act_deact;
    class Status Age Province Sales;
    format Age agefmt. Sales salesfmt.;
    tables Status, Age*(n) Province*(n) Sales*(n);
Run;

* Method #2 ;
Title "Segment the customers based on age, province and sales amount - Method: Proc Report";
Proc Report data=Alexia.Status_act_deact nowd;
    column Status Age Province Sales;
	format Age agefmt. Sales salesfmt.;
    define Status / group;
    define Age / across 'Age';
    define Province / across 'Province';
    define Sales / across 'Sales Segment';
Run;
/*==========================================================================================================*/


/* 1.4 Statistical Analysis:*/
/* 1) Calculate the tenure in days for each account and give its simple statistics.*/
Title "Calculate the tenure in days for each account  --[From 01/20/1999 To 01/20/2001]";
Data Alexia.Tenure_Days;
	set Alexia.Status_act_deact;
	if not missing(Deactdt) then Tenure = Deactdt - Actdt;
	else if not missing(Actdt) and missing(Deactdt) then Tenure = '20JAN2001'd - Actdt; 
Run;
Proc Print data=Alexia.Tenure (obs=20);
Run;
*Because EarliestActivationDate is: 01/20/1999, 
 LatestActivationDate and LatestDeactivationDate both are 01/20/2001
 and this CRM data of a wireless company is for 2 years, so I put '20JAN2001'd in there;
Proc Means data=Alexia.Tenure Missing Exclusive;
	var Tenure;
	class Status;
	output out=Alexia.Tenure_stats mean=Mean median=Median min=Min max=Max p25=Q1 p75=Q3 std=StdDev;
Run;
Proc Print data=Alexia.Tenure_stats;
Run;

*There has min=0, check the observation whose Tenure=0;
Data Alexia.MinTenure_Observations;
	set Alexia.Tenure;
	where Tenure = 0;
Run;
Proc Print data=Alexia.MinTenure_Observations(obs=20);
Run;

Title "Tenure of active account";
Proc Sgplot data=Alexia.Tenure;
	histogram Tenure;
	density Tenure;
	where Status = 'Activated';
Run;
Title "Tenure of deactivate account";
Proc Sgplot data=Alexia.Tenure;
	histogram Tenure;
	density Tenure;
	where Status = 'Deactivated';
Run;
* These two charts are both descending trends, which might be caused by the following reasons:
  1. Account Lifespan: 
	 The descending trend in the chart might suggest that most accounts have relatively short durations of usage. 
	 This could be due to many customers opting to deactivate their accounts 
     within a short period or perhaps the product lifecycle is short,
	 such as temporary subscriptions or events, resulting in accounts becoming inactive quickly.
  2. Customer Loyalty: 
	 Short account tenures could imply lower customer loyalty. 
	 Customers deactivating their accounts in a short span might indicate dissatisfaction with the service or product 
	 or switching to other providers in a competitive market.
  3. Market Dynamics: 
	 In certain cases, short-term account deactivations could reflect the intensity of market competition. 
	 Competition might lead to more frequent switching of providers or services by customers, 
	 resulting in shorter account durations.;
/*==========================================================================================================*/


/* 2) Calculate the number of accounts deactivated for each month.*/
Title "Calculate the number of accounts deactivated for each month";
Data Alexia.Tenure_Month;
	set Alexia.Tenure_Days;
	if not missing(Deactdt) then Tenure_Month = intck('month',Actdt,Deactdt);
	else if not missing(Actdt) and missing(Deactdt) then 
		Tenure_Month = intck('month',Actdt,'21Jan2001'd); 
Run;
Proc Print data=Alexia.Tenure_Month(obs=10);
Run;
Proc Freq data=Alexia.Tenure_Month;
    tables Deactdt / out=Alexia.Deact_MonthCounts;
	format Deactdt monyy7.;
Run;
Data Alexia.Deact_MonthCounts;
	set Alexia.Deact_MonthCounts;
	if _n_ ne 1;
Run;
Proc Print data=Alexia.Deact_MonthCounts;
Run;

/* Forecast the deactivation trends for the next 6 months */
Title "Forecast the deactivation trends for the next 6 months";
Data Alexia.Future_6_Month;
	input Deactdt monyy7.;
	format Deactdt monyy7.;
cards;
FEB2001
MAR2001
APR2001
MAY2001
JUN2001
JUL2001
;
Run;
Proc Print data=Alexia.Future_6_Month;
Run;
Data Alexia.Deact_MonthCounts_Seq;
	set Alexia.Deact_MonthCounts Future_6_Month;
	if _n_ = 1 then do;
		if 0 then set Alexia.Deact_MonthCounts_Seq nobs=n_rows;
	end;
	Sequence = _n_ - 1;
Run;
Proc Print data=Alexia.Deact_MonthCounts_Seq;
Run;
Proc Corr data = Alexia.Deact_MonthCounts_Seq  plots=matrix(histogram);
	var Sequence COUNT ;
Run;
Proc Reg data=Alexia.Deact_MonthCounts_Seq;
	model COUNT=Sequence;
Run;
* Parameter Estimate: B0=-269.78769, B1=87.93231;
Data Alexia.Forecast;
	set Alexia.Deact_MonthCounts_Seq;
	Predicted = -269.78769 + 87.93231*(Sequence);
Run;
Proc Print data=Alexia.Forecast;
Run;

Proc Means data=Alexia.Forecast mean;
	var Predicted;
Run;
Proc Means data=Alexia.Deact_MonthCounts mean;
	var COUNT;
Run;
/*==========================================================================================================*/


/* 3) Segment the account, first by account status “Active” and “Deactivated”, then by
Tenure: < 30 days, 31---60 days, 61 days--- one year, over one year. 
Report the number of accounts of percent of all for each segment. */
*Check if the observation have missing value;
Data Alexia.MissingTenure;
	set Alexia.Tenure_Month;
	where Tenure = .; 
Run;
Proc Print data=Alexia.MissingTenure;
Run;
* The data set ALEXIA.MISSINGTENURE has 0 observations and 12 variables, which means there are no missing values;

Title "Report the number of accounts as a percent of all for each segment";
Data Alexia.Account_Segments;
	set Alexia.Tenure_Month; 
	if Tenure < 30 then Tenure_Segment = '< 30 days                            ';
	else if Tenure <= 60 then Tenure_Segment = '31 - 60 days';
	else if Tenure <= 365 then Tenure_Segment = '61 days - one year';
	else Tenure_Segment = 'over one year';
Run;
Proc Freq data=Alexia.Account_Segments;
	table Status * Tenure_Segment / out=Alexia.Segmented_Counts outpct  norow nocol;
Run;
Proc Print data=Alexia.Segmented_Counts noobs;
	var Status Tenure_Segment Count Percent;
Run;
/*==========================================================================================================*/


/* 4) Test the general association between the tenure segments and “Good Credit” “RatePlan ” and “DealerType” */
Title "Test the general association between the tenure segments and “Good Credit” “RatePlan ” and “DealerType.”";
Proc Freq data=Alexia.Account_Segments;
	tables Tenure_Segment * GoodCredit / chisq expected norow nocol;
	tables Tenure_Segment * RatePlan / chisq expected norow nocol;
	tables Tenure_Segment * DealerType / chisq expected norow nocol;
Run;
* H0: There is no significant association between the Tenure segments and GoodCredit, RatePlan, DealerType.
  All the Chi-Square Probability are <.0001, indicating that we can reject this null hypothesis, 
  and conclude that there is an ASSOCIATION between the Tenure segments and GoodCredit, RatePlan, DealerType, 
  rather than just random differences.;
/*==========================================================================================================*/


/* 5) Is there any association between the account status and the tenure segments?
Could you find out a better tenure segmentation strategy that is more associated with the account status? */
Title "Is there any association between the account status and the tenure segments?";
Proc Freq data=Alexia.Account_Segments;
	tables Status * Tenure_Segment / chisq expected;
Run;
* H0: There is no significant association between the account status and Tenure segments.
  All the Chi-Square Probability are <.0001, which indicates that we can reject this null hypothesis, 
  and conclude that there is an ASSOCIATION between the account status and Tenure segments, 
  rather than just random differences.;

/* Better Tenure Segmentation */
Title "Better tenure segmentation strategy";
Data Alexia.Account_Segments_better;
	set Alexia.Account_Segments;
	if Tenure = 0 then Tenure_Segment_B = '0 days                            ';
	else if Tenure < 7 then Tenure_Segment_B = '1 - 7 days';
	else if Tenure < 30 then Tenure_Segment_B = '7 - 30 days';
	else if Tenure <= 90 then Tenure_Segment_B = '31 - 90 days';
	else if Tenure <= 180 then Tenure_Segment_B = '91 - 180 days';
	else if Tenure <= 365 then Tenure_Segment_B = '180 days - one year';
	else Tenure_Segment_B = 'over one year';
Run;
Proc Print data=Alexia.Account_Segments_better (obs=10);
Run;
Proc Freq data=Alexia.Account_Segments_better;
	tables Status * Tenure_Segment_B / chisq expected;
Run;
Proc Sgplot data=Alexia.Account_Segments_better;
	vbar Tenure_Segment_B /  stat=sum group=Status 
		groupdisplay=cluster dataskin=gloss;
	xaxis display=(nolabel);
	yaxis grid;
Run;
* After dividing the age groups more finely, it can be observed that among all deactivated accounts, 
  the largest proportion of Tenure is  '180 days - one year' accounting for 30.82%. 
  Following this, there are the '91 - 180 days'  at 20.84%, and 'over one year' at 19.65%. 
  This indicates that accounts with a usage duration exceeding 90 days are more prone to churn, 
  demonstrating a lack of strong attachment among long-term users. 
  Specific marketing strategies should be devised for these long-term users to enhance their loyalty.;
/*==========================================================================================================*/


/* 6) Does Sales amount differ among different account status, GoodCredit, and customer age segments? */
Title "Does Sales amount differ among different account status, GoodCredit, and customer age segments?";
Data Alexia.Formatt_Segments;
	set Alexia.Account_Segments;
	Sales_Segment = put(Sales, salesfmt.);
	Age_Segment = put(Age, agefmt.);
Run;
Proc Print data=Alexia.Formatt_Segments (obs=10);
Run;
Proc Freq data=Alexia.Formatt_Segments;
	table Sales_Segment;
Run;

* Sales and Status;
Proc GLM data=Alexia.Formatt_Segments;
	class Status;
	model Sales = Status;
	means Status / hovtest=levene(type=abs) welch;
Run;
* H0: There is no significant difference in the sales amount among different account statuses.
  The Levene's Test p-value= 0.0505, higher than 0.05, which indicates that we can not reject the Null Hypotheses,
  we haven't found strong evidence to conclude that 
  there are significant differences in sales amount among different account statuses.;
Proc ANOVA data=Alexia.Formatt_Segments;
	class Status;
	model Sales = Status;
	means Status;
Run;
Quit;
* H0: There is no significant association between Sales and account status.
  The p-value= 0.3997, higher than 0.05, which indicates that we can not reject the Null Hypotheses
  and conclude that there is no association between the Sales and account status.;

proc ttest data=Alexia.Formatt_Segments;
var Sales;
class Status;
run;


* Sales and GoodCredit;
Proc GLM data=Alexia.Formatt_Segments;
	class GoodCredit;
	model Sales = GoodCredit;
	means GoodCredit / hovtest=levene(type=abs) welch;
Run;
* H0: There is no significant difference in the sales amount among different GoodCredit.
  The Levene's Test p-value= 0.6795, higher than 0.05, which indicates that we can not reject the Null Hypotheses,
  we haven't found strong evidence to conclude that 
  there are significant differences in sales amount among different GoodCredit.;
Proc ANOVA data=Alexia.Formatt_Segments;
	class GoodCredit;
	model Sales = GoodCredit;
	means GoodCredit;
Run;
Quit;
* H0: There is no significant association between the Sales and GoodCredit.
  The p-value= 0.7788, higher than 0.05, which indicates that we can not reject the Null Hypotheses
  and conclude that there is no association between the Sales and GoodCredit.;

* Sales and Age segments;
Proc GLM data=Alexia.Formatt_Segments;
	class Age_Segment;
	model Sales = Age_Segment;
	means Age_Segment / hovtest=levene(type=abs) welch;
Run;
* H0: There is no significant difference in the sales amount among different age segments.
  The Levene's Test p-value= 0.2328, higher than 0.05, which indicates that we can not reject the Null Hypotheses,
  we haven't found strong evidence to conclude that 
  there are significant differences in sales amount among different age segments.;
Proc ANOVA data=Alexia.Formatt_Segments;
	class Age_Segment;
	model Sales = Age_Segment;
	means Age_Segment;
Run;
Quit;
* H0: There is no significant association between the Sales and age segments.
  The p-value= 0.7583, higher than 0.05, which indicates that we can not reject the Null Hypotheses
  and conclude that there is no association between the Sales and age segments.;

* Sales and Status, GoodCredit, Age segments;
Proc GLM data=Alexia.Formatt_Segments;
	class Status GoodCredit Age_Segment;
	model Sales = Status GoodCredit Age_Segment;
	means Status GoodCredit Age_Segment / hovtest=levene(type=abs) welch;
Run;
* H0: There is no significant difference in the sales amount among different account status, GoodCredit, and age segments.
  All the p-values are higher than 0.05, which indicates that we can not reject the Null Hypotheses,
  we haven't found strong evidence to conclude that there are significant differences 
  in sales amount among different account statuses, GoodCredit, and age segments.;
Proc ANOVA data=Alexia.Formatt_Segments;
	class Status GoodCredit Age_Segment;
	model Sales = Status GoodCredit Age_Segment;
	means Status GoodCredit Age_Segment;
Run;
Quit;
* H0: There is no significant association between Sales and account status, GoodCredit, or age segments.
  All the p-values are higher than 0.05, which indicates that we can not reject the Null Hypotheses
  and conclude that there is no association between the Sales and account status, GoodCredit, and age segments.;
/*==========================================================================================================*/
/*==========================================================================================================*/


/* Analysis Data -1: Exploring Data: Categorical Variables */
Title "Exploring Data: Categorical Variablrs";
Proc Freq data=Alexia.Formatt_Segments nlevels;
	tables DeactReason GoodCredit RatePlan DealerType Province ;
Run;
* About GoodCredit
  1 represents good credit, 0 represents bad credit, 
  there have 69.44% of accounts are good credit, and 30.56% of accounts are bad credit.
  The proportion of bad credit accounts is too high. 
  In the future, when opening an account, the customer’s credit rate should be properly checked.;

* About RatePlan
  66.69% of accounts are RatePlan#1, 19.74% of accounts are RatePlan#2, 13.57% of accounts are RatePlan#3.
  The proportion of RatePlan#1 to the overall data is twice the sum of RatePlan#2 and RatePlan#3. 
  This means that RatePlan#1 is more popular, and we can consider launching  more plans like RatePlan#1 in the future.;

* About DealerType
  There 54.87% of accounts are A1, more than all other DealerTypes combined.
  It may be because the deals provided by this dealer are cost-effective, 
  or it may be that the dealer provides a variety of deals and covers a wider range of areas.;

* About Province
  There 44.11% of accounts are in the ON province, more than all other DealerTypes combined.
  This may be because the population of ON Province is the most populous province in Canada. 
  If we want to analyze the relationship between accounts and provinces, 
  we also need to refer to the population distribution of each province.;
/*==========================================================================================================*/


/* Analysis Data -2: Exploring Data: Continuous Variables */
Title "Exploring Data: Continuous Variablrs";
Proc Means data=Alexia.Formatt_Segments;
	var Age Sales;
Run;
Proc Univariate data=Alexia.Formatt_Segments normal;
    var Age Sales;
    histogram Age Sales / normal;
Run;

* About Age
  The mean of age is 47.6, the overall age is mainly concentrated in the middle-aged crowd.
  The maximum age is 99, and the minimum is 0 which is very abnormal and needs further inspection.
  Missing data accounted for 7.54% of the total data.
  The Skewness value is 0.03053421, very close to zero, suggesting that the data is roughly symmetric and exhibits minimal skewness.
  The Kurtosis value is -0.4201847, which is less than 3, indicating a relatively flatter distribution without a pronounced peak. 
  Based on the Skewness and Kurtosis values, the distribution for the "Age" variable appears to be relatively symmetric and flat. ;
Title "Exploring Data: Continuous Variablrs (About Age)";
Proc SQL;
  select count(*)
  from Alexia.Formatt_Segments
  where Age = .;
Quit;
* Age has 7708 observations with missing values;
Proc SQL;
  select count(*)
  from Alexia.Formatt_Segments
  where Age = 0;
Quit;
* Age = 0 have 13 observations;
Proc SQL;
  select count(*)
  from Alexia.Formatt_Segments
  where Age = 1;
Quit;
* Age = 1 have 55 observations;
Proc Freq data = Alexia.Telecom nlevels;
	table Age;
Run;
* The age under 5 has 691 observations.
  This could be due to two reasons:
  1. It is mandatory to provide a valid ID when opening an account and many parents open accounts for their children. 
     When the baby is under one year old, the system will input age=0.
	 Maybe new users have a better deal, Parents open an account in the name of the child, and the parents use it themselves
  2. It is not mandatory to provide a valid ID when opening an account. Many people fill in their age at will or even don’t fill in it.

* About Sales
  The mean of sales is 47.6, the maximum sales are 1200, and the minimum is 0.
  Missing data accounted for 8.42% of the total data.
  The Skewness value is 2.36652039(positive) which indicates the distribution is skewed to the right, with a longer tail on the right side.
	A positive skewness value suggests a right-skewed distribution of sales amounts. 
	This means that most sales amounts are relatively small, but there are also some larger sales amounts 
	(Potentially representing a few significant transactions or orders). 
	This could indicate that most transactions have smaller amounts, 
	but a few transactions with higher amounts impact the overall distribution.
  The Kurtosis value is 5.28183679, which is significantly greater than 3. 
	A high kurtosis value could indicate that the distribution of sales amounts has a relatively sharp and pronounced peak. 
	This suggests the presence of transactions with very high amounts. 
	It might imply the existence of outliers or large orders within the sales amounts, 
	or that certain transaction amounts are relatively concentrated.;
Title "Exploring Data: Continuous Variablrs (About Sales)";
Proc SQL;
  select count(*)
  from Alexia.Formatt_Segments
  where Sales = .;
Quit;
* Sales has 8605 observations with missing values;
/*==========================================================================================================*/


/* Analysis Data -3: Outliers and Missing values */
*Outliers for Sales;
Title "Outliers for Sales";
Proc Sgplot data=Alexia.Formatt_Segments;
	vbox Sales / category=Status;
Run;
* These outliers represent transactions with unusually high values, and might have the following practical meanings: 
  1. Outliers in sales amounts could be indicative of data entry errors, measurement inaccuracies.
  2. Outliers on the high end could represent large orders, significant contracts, or high-value customers. 
	These transactions might have strategic importance or unique requirements, 
    which might influence business decisions or sales strategies.;

*Outliers for Age;
Title "Outliers for Age (Before replacing missing values)";
Proc Sgplot data=Alexia.Formatt_Segments;
	vbox Age / category=Status;
Run;
* From this box plot, I can't find any outliers, there may be 2 reasons for this
	1. There are no outliers here
	2. There are Outliers here, but they are affected by other reasons, such as being affected by missing values
		Age has 7708 observations with missing values.
  First, I replace the missing values with the mean (mean of age is 47.6) and then find the outliers again.;
Title "Outliers for Age (After replacing missing values)";
Data Alexia.Replace_AgeMissing; 
	set Alexia.Formatt_Segments;
	if Age = . then Age=47.6;
Run;
Proc Sgplot data=Alexia.Replace_AgeMissing;
	vbox Age / category=Status;
Run;
* Outliers in age may reflect data entry errors or exceptional cases in the dataset.
  Exceptional cases may have the following two situations:
  1. Some parents open accounts for young children if a valid ID is mandatory for account opening. 
  2. Some people fill in the age at will or even don't fill it in if a valid ID is not mandatory for account opening.;
/*==========================================================================================================*/


/* Analysis Data -4: Association between variables */
%macro Association(table1, table2);
    Proc Freq data=Alexia.Formatt_Segments;
        table &table1*&table2/ chisq expected norow nocol;
    Run;
%mend;

%Association(Age_Segment, Province);
%Association(Age_Segment, Status);
%Association(Age_Segment, GoodCredit);
%Association(Age_Segment, RatePlan);
%Association(Age_Segment, DealerType);
%Association(Age_Segment, Sales_Segment);
* H0: There is no significant relationship between the Age segments 
  and Province, Status, GoodCredit, RatePlan, DealerType, Sales segment.
  All the Chi-Square Probability are >0.05, indicates that we can not reject this null hypothesis, 
  and conclude that there is no association between Age segment and Province, Status, GoodCredit, RatePlan, DealerType, Sales segment.;
%Association(Sales_Segment, Province);
%Association(Sales_Segment, Status);
%Association(Sales_Segment, GoodCredit);
%Association(Sales_Segment, DealerType);
* H0: There is no significant relationship between the Sales segments and Province, Status, GoodCredit, DealerType.
  All the Chi-Square Probability are >0.05, indicates that we can not reject this null hypothesis, 
  and conclude that there is no association between Sales segment and Province, Status, GoodCredit, DealerType.;
%Association(Sales_Segment, RatePlan);
* H0: There is no significant relationship between the Sales segment and RatePlan.
  The Chi-Square Probability=0.0302 is less than 0.05, indicates that we can reject this null hypothesis, 
  and conclude that there is an ASSOCIATION between Sales segment and RatePlan.;
%Association(Tenure_Segment, Province);
%Association(Tenure_Segment, Age);
%Association(Tenure_Segment, Sales);
* H0: There is no significant relationship between the Tenure segments and Province, Age, Sales.
  All the Chi-Square Probability are >0.05, indicates that we can not reject this null hypothesis, 
  and conclude that there is no association between the Tenure segments and Province, Age, Sales, rather than just random differences.;
%Association(GoodCredit, RatePlan);
%Association(GoodCredit, DealerType);
%Association(GoodCredit, Status);
%Association(RatePlan, DealerType);
%Association(RatePlan, Status);
%Association(DealerType, Status);
* H0: There is no significant relationship between them.
  All the Chi-Square Probability are less than 0.0001, indicates that we can reject this null hypothesis, 
  and conclude that there is an ASSOCIATION between them.;

