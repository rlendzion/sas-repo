%let x=0;
%put &x;
%macro validate;
%if &x.<1 %then %do;
%goto exit;
%end;
%else %do; %put execute macro;
%end;
%exit:
%mend validate;
%validate;