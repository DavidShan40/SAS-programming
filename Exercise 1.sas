* Tao Shan
Stat 466;

* Question 1;
* 1.a;
Option MergeNoBy=WARN MSGLevel=i nofmterr;

* 1.b;
%let path=/home/u44540533/assignment/;

* Question 2a;
%web_drop_table(WORK.RCT);
FILENAME REFFILE "&path.ExerciseRCT.xlsx";

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.RCT;
	GETNAMES=YES;
RUN;
%web_open_table(WORK.RCT);

DATA VO2max;
SET RCT;
VO2MAXV00_04 = VO2MAXV04 - VO2MAXV00;
VO2MAXV00_08 = VO2MAXV08 - VO2MAXV00;
VO2MAXV00_16 = VO2MAXV16 - VO2MAXV00;
VO2MAXV00_24 = VO2MAXV24 - VO2MAXV00;
run;

* 2b;
* data sort by GroupNum;
proc sort DATA = VO2max OUT=VO2max_sort;
BY GroupNum;
RUN;

* change the display of GroupNum variable;
proc Format;
value Group_Num
 	1 = 'Control'
 	2 = 'LALI'
 	3 = 'HALI'
	4 = 'HAHI';
run;

data VO2max_sort;
set VO2max_sort;
IF VO2MAXV00_24 ^= . then Nobs = 1;
	else Nobs = 0;
run;
	
PROC SGPANEL DATA=VO2max_sort;
PANELBY SEX;
format GroupNum Group_Num.; * change the display of GroupNum variable;
VBOX VO2MAXV00_24 / category = GroupNum;
ROWAXIS VALUES=(-1 to 1.5 by 0.5) GRID label = "24-week change in VO2max (L/min)";
COLAXIS label = "Treatment Group";
REfline 0 / axis=y LINEATTRS=(PATTERN=dot COLOR=red);
colaxistable Nobs/ STAT = SUM;
RUN;

* 2(c);

* data sort by GroupNum and SEX;
proc sort DATA = VO2max_sort OUT=VO2max_sort;
BY descending SEX GROUPNum;
RUN;

PROC TABULATE DATA=VO2max_sort ORDER=DATA;
format GroupNum Group_Num.; * change the display of GroupNum variable;
class GROUPNum SEX;
VAR VO2MAXV00 VO2MAXV00_04 VO2MAXV00_08 VO2MAXV00_16 VO2MAXV00_24;
TABLE ((ALL="Overall" SEX="By Sex") * (VO2MAXV00 VO2MAXV00_04 VO2MAXV00_08 VO2MAXV00_16 VO2MAXV00_24)),
	(ALL="Total" * N(GROUPNum)* (N MEAN STD = "SE")) / box="VO2max (L/min)" MISSTEXT='NA';
LABEL GROUPNum = 'Treatment Group'
	VO2MAXV00 = 'Baseline'
	VO2MAXV00_04 = 'Change at 4 weeks'
	VO2MAXV00_08 = 'Change at 8 weeks'
	VO2MAXV00_16 = 'Change at 16 weeks'
	VO2MAXV00_24 = 'Change at 24 weeks';
footnote "SE-Standard Error, LALI-low amount at low intensity, HALI-low amount at low intensity, HAHI-high amount at high intensity, NA-not assessed";
run;
* after question 2, before 3.1, delete footnote for further output;
footnote;
run;
* 3.1;
libname mylib "&path.";
proc sort DATA = mylib.clients OUT=cilents NODUPKEY;
BY LastName Firstname;
RUN;
* when sort clients, 2 records found and removed from the dataset (from 173 to 171);

proc sort DATA = mylib.projects OUT=projects NODUPKEY;
BY ProjectID;
RUN;
* when sort projects, 0 records found and removed from the dataset;

* 3.2;
proc means data=mylib.time Noprint NWAY;
var date hours;
class ProjectID;
output out = time_summary MAX(date)= MIN(date)= SUM(hours)=/ AUTONAME;
run;

data projects;
set time_summary;
MERGE projects (IN=in1) time_summary (IN=in2);
by ProjectID;
drop _TYPE_ _FREQ_;
if in2 =1;
output;
run;

title 'question 3.2';
proc print data = projects;
run;

* 3.3;
proc means data=projects Noprint NWAY;
var ProjectID hours_Sum;
class LastName Firstname;
output out = projects_summary N(ProjectID)= SUM(hours_Sum)= / AUTONAME;
run;

data clients;
set projects_summary;
MERGE mylib.clients (IN=in1) projects_summary (IN=in2);
by LastName Firstname;
if in2 =1;
output;
drop _TYPE_ _FREQ_;
run;

title 'question 3.3';
proc print data = clients;
run;

* 3.4;
* client.html;
DATA _NULL_;
   SET clients;
   FILE "&path.Clients.html";
   format days 8.1;
   days = round(hours_Sum_Sum/7.5, 0.1);
   IF _N_ = 1 THEN PUT '<b><h1 ALIGN=CENTER> Client Report </h1></b>';
   PUT '<a href="Projects.html#'Lastname FirstName +(-1)'"> '
   	   LastName +(-1) ', ' FirstName '</a> 'ProjectID_N 
   	   'project(s) totaling ' days 'days.' 
       '<br> ';
RUN;

* Projects.html;
proc sort DATA = projects;
BY LastName FirstName;
RUN;

DATA _NULL_;
   SET projects;
   FILE "&path.Projects.html";
   if missing(Lastname) | missing(FirstName) then delete;
   format days 8.1 date_Min date_Max WORDDATE.;
   days = round(hours_Sum/7.5, 0.1);
   IF _N_ = 1 THEN PUT '<b><h1 ALIGN=CENTER> Projects by Client </h1></b>';
   BY Lastname FirstName; 
   * only put name when it's the 1st occurance;
   IF first.Lastname & first.FirstName THEN PUT 
   	   '<a name="'Lastname FirstName +(-1) '"></a>'/
   	   '<h2>'Lastname +(-1) ', ' FirstName '</h2>';
   PUT '<b>' Title +(-1) ': </b>' days 'days between ' 
       date_Min 'and ' date_Max +(-1) ".<br> <br>" /;
run;

*4(a);
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
%local n mux muy stdx stdy rho n sims;

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
%let plot = %str('Yaaaa'); 

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
the relationship between x and y is closer than when correlation is 0.

