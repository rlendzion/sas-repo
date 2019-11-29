data _null_; 
	call symputx ('yr_mnth',substr(put(intnx('month',date(),-1,'end'),ddmmyy10.),7,4)||substr(put(intnx('month',date(),-1,'end'),ddmmyy10.),4,2);
	call symputx ('ym_prev',substr(put(intnx('month',date(),-2,'end'),ddmmyy10.),7,4)||substr(put(intnx('month',date(),-2,'end'),ddmmyy10.),4,2);
run;

proc sql; select max(yr_mnth) into: max_ym from MY_SCHEMA.MY_TABLE_&ym_prev; 
quit;

data MY_SCHEMA.MY_TABLE_&yr_mnth.; set MY_SCHEMA.MY_TABLE_&ym_prev.; period=&yr_mnth.; /*Create a new object with the current reporting date*/
run;

%macro append(obj); /*Append new data from temporary objects into an existing one*/
%if &max_ym.<&yr_mnth. %then %do;
proc append base=MY_SCHEMA.MY_TABLE_&yr_mnth. data=WORK.&obj. force;
run;
%end;
%else
%exit:
%mend append;
%append(INPUT_TAB1_&yr_mnth.);
%append(INPUT_TAB2_&yr_mnth.);
%append(INPUT_TAB3_&yr_mnth.);

proc export data=MY_SCHEMA.MY_TABLE_&yr_mnth. dbms=csv outfile="C:\Users\UserName\Downloads\output.csv" replace; delimiter=",";
run;

proc delete data=MY_SCHEMA.MY_TABLE_&ym_prev.;
run;

/*purge WORK schema*/
proc datasets library=WORK; save _prodsavail;
run;