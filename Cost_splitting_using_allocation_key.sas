data _null_; 
	x = intnx('month',date(),-1,'end');
	y = intnx('month',date(),-2,'end');
	call symputx ('rm', substr(put(x,ddmmyy10.),4,2)||"/"||substr(put(x,date9.),1,2)||"/"||substr(put(x,date9.),6,4));
	call symputx ('yr_mnth', substr(put(x,ddmmyy10.),7,4)||substr(put(x,ddmmyy10.),4,2));
	call symputx ('ym_prev', substr(put(y,ddmmyy10.),7,4)||substr(put(y,ddmmyy10.),4,2));
run;
&put &rm.; %put &yr_mnth.; %put &ym_prev.;

data NEW; input yr_mnth val;
datalines;
201901 0
201902 150000
201903 150000
201904 150000
201905 150000
201906 100000
201907 100000
201908 100000
201909 120000
; run;

proc import datafile='\\production.net\data\UserName\UserFolder\allocation key.xlsx' 
dbms=xlsx out=WORK.KEY (keep=A D) replace; getnames=no; range="Sheet1$A5:D400"; /*A - common field, B--C - irrelevant fields, D - allocation percent*/
run;

%macro process(num,yr);
proc sql; create table TEMP&num. as select a.A, a.yr_mnth, a.D*val as allocated_val
from (select a.*, &yr. as yr_mnth from WORK.KEY a) a
left join (select * from WORK.NEW where yr_mnth = &yr.) b on a.yr_mnth = b.yr_mnth
%mend process;
%process(1,&yr_mnth.);
%process(2,&ym_prev.);

proc sql; create table merged as select a.A, a.allocated_val, sum(a.allocated_val,b.allocated_val)/2 as average from WORK.TEMP1 a full join WORK.TEMP2 b on a.A = b.A;
quit;

data _null_;
	call symputx ('txt',cats("\\production.net\data\UserName\UserFolder\allocated_amounts_","&yr_mnth.","xlsx")); 
run;
	
proc export data=WORK.merged dbms=xlsx outfile="&txt." replace; 
run;