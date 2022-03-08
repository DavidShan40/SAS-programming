*1(a);
%macro binorm(mux = 0, muy = 0, stdx = 1, stdy = 1, rho = 0, seed = 0, n = 100,
    sims = 1, outdata = binorm, plot = 'N');
data &outdata;
call STREAMINIT(&seed);
do simnum = 1 to &sims;
	do n = 1 to &n;
		x = rand('NORMAL', &mux, &stdx);
		y = rand('NORMAL', &muy, &stdy);
		y = &rho * x + sqrt(1 - &rho ** 2) * y;
		output;
	end;
end;
drop n;

* create scatter plots;
%local mux muy stdx stdy rho n sims;

if (substr(&plot,1,1) = 'Y' | substr(&plot,1,1) = 'y') then do;
call execute("title 'Plot of y vs. x';");
call execute("title2 'n=&n, X~N(&mux, &stdx), Y~N(&muy, &stdy), corr(x, y) = &rho';");
call execute("PROC SGPLOT DATA=&outdata;");
call execute("SCATTER X=x Y=y;");
call execute("BY simnum;");
call execute("run;");
end;
run;
%mend binorm;

* make sure file name for simulation and proc corr are the same;
%let binorm = %str(binorm); 
* change graph setting for all plots;
%let plot = %str('Yaaa'); 

* try a couple of settings;
*1);
%binorm(n = 100000, outdata = &binorm, plot = &plot);

proc corr data = &binorm SPEARMAN PEARSON;
VAR x y;
run;
* from Pearson Correlation Coefficients, for the first setting with default, 
the generated estimates are close to my parameter settings, since they are both close to 0.;

*2);

%binorm(n = 100000, sims = 2, outdata = &binorm,plot = &plot);

proc corr data = &binorm SPEARMAN PEARSON;
VAR x y;
run;
* from Pearson Correlation Coefficients, for the second setting with sims = 2, 
the generated estimates are close to my parameter settings, since they are both close to 0.;

*3);

%binorm(rho = 0.2,n = 100000, outdata = &binorm,plot = &plot);

proc corr data = &binorm SPEARMAN PEARSON;
VAR x y;
run;
* from Pearson Correlation Coefficients, for the third setting with rho = 0.2, 
the generated estimates are close to my parameter settings, since they are both close to 0.2.;

* From above, when x and y are standard normal variables, 
the generated estimates are close to my parameter settings.;

*default settings except turn the plot option,
run for correlations 0, 0.2, 0.5 and 0.9 respectively;
%binorm(rho = 0, plot = &plot);
%binorm(rho = 0.2, plot = &plot);
%binorm(rho = 0.5, plot = &plot);
%binorm(rho = 0.9, plot = &plot);
*five simulations of sample size 50 with plots for correlations 0 and 0.2;
%binorm(n = 50, sims = 5, rho = 0, plot = &plot);
%binorm(n = 50, sims = 5, rho = 0.2, plot = &plot);

* compare with the scatter plots between correlation is 0 or 0.2. 
When correlation is 0, it looks like there is no relationship between x and y.
When correlation is 0.2, though it still looks like a random pattern, 
the relationship between x and y is closer than when correlation is 0.;

*2;
%let path=/home/u44540533/assignment/;
libname mylib "&path.";

*2 a;
title "2a: total number of patients with at least one row in the FAOS table";
footnote "503 patients";
PROC SQL;
select count(distinct Patient_ID) as num_patients from mylib.faos;
run;
* 503 patients;

* 2.b);
title "2b: any patients in the FAOS table without an entry in the BASELINE table";
footnote "no patients in the FAOS table without an entry in the BASELINE table.";
PROC SQL;
select count(DISTINCT faos.Patient_ID) as num_patients_noentry
from mylib.faos as faos 
left join mylib.BASELINE as base
on faos.Patient_ID = base.Patient_ID
WHERE base.Patient_ID is NULL;
run;
* no patients in the FAOS table without an entry in the BASELINE table.;

* 2 c);
title "2c: number of patients in each treatment group with an observation in the BASELINE table but no 
non-missing 6-month value in the FAOS table";
footnote "number of people with FAO missing, for each group there is one record.";
PROC SQL;
select faos.TreatmentGroup, count(distinct faos.Patient_ID) as num_FAO_missing 
from mylib.faos as faos 
left join mylib.BASELINE as base
on faos.Patient_ID = base.Patient_ID
WHERE faos.FAOS is NULL
Group by faos.TreatmentGroup;
run;
* number of people with FAO missing, for each group there is one record;

* 2 d);
title "2d: Summary Statistics";
footnote "SQL is an excellent tool for identifying data errors. Incorrect dates are perhaps the most common data errors.";

PROC SQL;
select faos.TreatmentGroup as 'Treatment Group'n, faos.month, count(faos.FAOS) as 'N FAOS'n,
round(mean(faos.FAOS),0.1) as 'Mean FAOS'n format = 8.1, round(STD(faos.FAOS),0.1) as 'SD FAOS'n format = 8.1,
round(min(faos.FAOS),0.1) as 'MIN FAOS'n format = 8.1, ROUND(max(faos.FAOS),0.1) as 'MAX FAOS'n format = 8.1
from mylib.faos as faos 
left join mylib.BASELINE as base
on faos.Patient_ID = base.Patient_ID
Group by faos.month, faos.TreatmentGroup;
run;

* 2e;
title "2e: every row in the FAOS table where an Assessment_DT is less than the Triage_DT for a given patient";
footnote "totally 5 records with error";
PROC SQL;
select faos.Patient_ID, base.Triage_DT, faos.Assessment_DT, faos.month
from mylib.faos as faos 
left join mylib.BASELINE as base
on faos.Patient_ID = base.Patient_ID
where faos.Assessment_DT < base.Triage_DT;

* 2f;
title "2f: A count of the number of patients who have an inconsistency in the order of their Month and Assessment_DT variables in the FAOS table";
footnote "totally 5 records with error";
PROC SQL;
select count(unique faos.Patient_ID) as count_ID
from mylib.faos as faos
full join mylib.faos as faos_2 on faos.Patient_ID = faos_2.Patient_ID
where faos.month < faos_2.month and faos.Assessment_DT > faos_2.Assessment_DT;
run;

* 2g;
title "2g: Table for A count of the number of patients who have an inconsistency in the order of their Month and Assessment_DT variables in the FAOS table";
footnote "all records for patients with inconsistency error";
PROC SQL;
select Patient_ID, Month, Assessment_DT from mylib.faos
where Patient_ID in
	(select faos.Patient_ID
	from mylib.faos as faos
	full join mylib.faos as faos_2 on faos.Patient_ID = faos_2.Patient_ID
	where faos.month < faos_2.month and faos.Assessment_DT > faos_2.Assessment_DT)
order by Patient_ID, Assessment_DT;
run;

* 3a);
proc sql;
create table FAOS as
select faos_1.Patient_ID, faos_1.TreatmentGroup, faos_1.FAOS as FAOS_baseline, faos_2.FAOS as FAOS_6, (faos_2.FAOS - faos_1.FAOS) as change_FAOS
from mylib.faos as faos_1
full outer join (select * from mylib.faos
	where Month = 6) as faos_2 on faos_1.Patient_ID = faos_2.Patient_ID
where faos_1.Month = 0;
run;


* 3b);
proc corr data=FAOS plots=matrix(histogram) PEARSON;
var FAOS_baseline FAOS_6 change_FAOS;
run;

* 3c);
proc ttest data=FAOS;
    var FAOS_6 change_FAOS;
    class TreatmentGroup;
run;

* 3d);
*6-month FAOS: for F test for equality of variances is significant (p=0.0223) so we would
 reject equality of variances and use the Satterthwaite method
 for unequal variances (p=0.0343). This test is valid with unequal variances
 but still assumes the data is approximately normal in each group. 
 (support assumptions of approximate normality, valid with unequal variance);
 
*"6-month change in FAOS: for F test for equality of variances is not significant
(p = 0.5201) so we would support equality of variances and use the pooled method 
(p = 0.1296). This test rejected the data is approximately normal in each group.
(reject assumptions of approximate normality, reject assumption of unequal variance)";

* 3e);
proc npar1way data=FAOS WILCOXON;
    var change_FAOS;
    class TreatmentGroup;
run;
* two-sided p-values: 0.0670, 0.1339;

* 3f);
proc mixed data=FAOS;
class TreatmentGroup;
model change_FAOS= FAOS_baseline TreatmentGroup/ htype=2;*adjusted test;
lsmeans TreatmentGroup / DIFF;
run;
* the estimated adjusted difference between treatment groups, Control and Physio 
is 13.7502. The two-sided p-value is 0.0363.
*Physiotherapy appears to have worsened the treatment because Least Squares Means for 
the Physiotherapy group is worsened than the control group.
	














