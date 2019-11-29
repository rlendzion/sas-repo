libname LOANS oracle path=PROD01.PWJ.COM schema='MY_SCHEMA';
libname REVENUES ODBC datasrc=RPT password=123;

data INPUT_DATA; set LOANS.DATA (where=(as_of_date=201901 and business_area='Loans')); 
run;

ods output ExtremeObs = OUT1;
prod univariate data=WORK.INPUT_DATA
nextrobs=10
plots; format _numeric_ num20.;
var RWA; histogram / normal;
id posting_counterparty_id trade_balance_id;
class business_area;
output out=OUT2 pctlpts=1 99 min=min max=max pctlpre=p;
run;
ods output close;

proc sql; create table WORK.EXTREMES_APPR1 as select OUT1.* from WORK.OUT1;
proc sql noprint; select trade_balance_id_high into :list separated by "','" from WORK.EXTREMES_APPR1; 
quit;
data _null_; call symput ( 'xtr',"'"||"&list."||"'"); 
run;

proc univariate data=WORK.INPUT_DATA (where=(trade_balance_id not in (&xtr.)))
plots; format _numeric_ num20.;
var RWA; histogram / normal;
run;

data WORK.NTHDEGREE; set WORK.OUT2 (where=(not missing(max)));
pn= (p99-p1)/99;
p0=max(p1-pn,min);
p100=min(p99+pn,max);
run;

proc sql;
create table extremes_appr2 as select b.* from WORK.NTHDEGREE a left join WORK.INPUT_DATA b on a.business_area eq b.business_area
and ((a.min LE b.RWA LT x.p0) OR (a.p100 LT b.RWA LE x.max))
order by b.RWA desc; 
quit;

proc sql noprint; select trade_balance_id into :list2 separated by "','" from WORK.extremes_appr2; 
quit;
data _null_; call symput ('xtr2',"'"||"&list2."||"'"); 
run;

proc univariate data=WORK.INPUT_DATA (where=(trade_balance_id not in (&xtr2.)))
plots; format _numeric_ num20.;
var RWA; histogram / normal;
run;

proc sql noprint; select trade_balance_id_high into :high separated by "','" from WORK.EXTREMES_APPR1; 
quit;
data _null_; call symput ('highxtr1',"'"||"&high."||"'"); 
run;
%put &highxtr1.;
data TEST; set REVENUES.FACT_REV_REPORT (where=(AS_ON_DATE between '01JAN2019'd and '31JAN2019'd and TRAN_NO in (&highxtr1.)));
AS_ON_DATE=dhms('31JAN2019'd,0,0,0);
run;