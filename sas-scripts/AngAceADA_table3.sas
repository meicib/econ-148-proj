
********************************************;
* PROGRAM: AngAceADA_table3					;
* PROGRAMMER: Simone Schaner				;
* PURPOSE: Recreates Table 3 of 2001 ADA	;
*	paper									;
* DATE CREATED: 8/1/07						;
********************************************;

************************************************;
* NOTE: This code contains a minor correction 	;
*	which only retains cells which allow the	;
*	estimation of all parameters presented		;
*	in table 4. And adjusts for the fact that	;
*	not all cells are used in the dd estimate.	;
*	 To enable the correction choose			;
*	the 'correct' options for the %let 			;
*	statements. To use the old methodology,  	;
*	choose the 'oldway' options.				;
************************************************;
  %let flag=correct;
*  %let flag=oldway;
  %let marker='correct';
*  %let marker='oldway';
************************************************;

* CREATE EXTRACT WITH NECESSARY VARIABLES;

libname save '/bbkinghome/sschaner/Angrist Work/Web Papers/AcemogluAngrist_2001/sasdata';

data one;
 set save.marcps_w;

 if (21<=age<=58);

 if age<40 then sample='young'; else sample='old';

 ** corrected 12-27 **;

 if ((wkswork>0) and (wsal_val>0)) then lnwkwage=log(wsal_val/wkswork);
 if ((wkswork>0) and (wsal_val>0)) then wkwage=wsal_val/wkswork;
 totwage=wsal_val;
 jobwage=ern_val;

 **;

 agegrp=10*int(age/10);
 age20=(agegrp=20);
 age30=(agegrp=30);
 age40=(agegrp=40);
 age50=(agegrp=50);

 if race=>3 then racegrp=3; else racegrp=race;

 if lesshs=1 then educgrp=1;
    else if hsgrad=1 then educgrp=2;
    else if (someco=1 or colgrad=1) then educgrp=3;

 workly=(wkswork>0);

 length age20 age30 age40 age50 workly 3;

 if (wkswork=0) then lfin1=working;
   else lfin1=.;
 if (wkswork<50) then lfin2=working;
   else lfin2=.;
 if (wkswork=>50) then lfout1=(1-working);
   else lfout1=.;
 if (wkswork=0) then changer=.;

 length agegrp age20 age30 age40 age50 educgrp region 3;

 trend=(year-87);
 trend2=trend**2;
 
 dis_trend= trend*disabl1;
 dis_yr89=(year=89)*disabl1;
 dis_yr90=(year=90)*disabl1;
 dis_yr91=(year=91)*disabl1;
 dis_yr92=(year=92)*disabl1;
 dis_yr93=(year=93)*disabl1;
 dis_yr94=(year=94)*disabl1; 
 dis_yr95=(year=95)*disabl1;
 dis_yr96=(year=96)*disabl1;
 dis_yr97=(year=97)*disabl1;

 dyr_9497=(94<=year<=97)*disabl1;

 %macro code(var,num);
	dis_&var.&num.= disabl1*(&var.=&num.);
	%mend;
	
	%code(racegrp,1); %code(racegrp,2); %code(racegrp,3);
	%code(region,1); %code(region,2); %code(region,3);
		%code(region,4); %code(region,5); %code(region,6);
		%code(region,7); %code(region,8); %code(region,9);
	%code(agegrp,20); %code(agegrp,30); %code(agegrp,40); %code(agegrp,50);	
	%code(educgrp,1); %code(educgrp,2); %code(educgrp,3);
	
%macro code2(var,num);
	&var._d&num.= (&var.=&num.);
	%mend;
	
	%code2(year,89); %code2(year,90); %code2(year,91); %code2(year,92);
	%code2(year,93); %code2(year,94); %code2(year,95); %code2(year,96);
	%code2(year,97);
	
length dis_yr89-dis_yr97 trend trend2 3;

  **** kill wage outliers ****;

  ** code CPI-W from actuaries web page **;
  ** gopher.ssa.gov/OACT/STATS/cpiw.htm **;

  if year=88 then cpiw=117;
   else if year=89 then cpiw=122.6;
   else if year=90 then cpiw=129.0;
   else if year=91 then cpiw=134.3;
   else if year=92 then cpiw=138.2;
   else if year=93 then cpiw=142.1;
   else if year=94 then cpiw=145.6;
   else if year=95 then cpiw=149.8;
   else if year=96 then cpiw=154.1;
   else if year=97 then cpiw=157.6;
   cpiw88=(cpiw/117);

 rlwkwage=wkwage/cpiw88;

 if ((rlwkwage<25) or (rlwkwage>2000)) then do; lnwkwage=.; wkwage=.; end; 


 **;

 * ID VARS FOR LATER;
classid= 1000*agegrp+100*racegrp+10*educgrp+region;
sampsex= sample||sex;
classid2= classid||sample||sex;
count=1;	
	
 keep age agegrp year sex disabl1 totwage jobwage sample
      working unempl nilf jobloser wkswork workly
      hsgrad someco colgrad region centralc balmsa trend 
      dis_yr89-dis_yr97 dyr_9497 fnlwgt dis_racegrp1-dis_racegrp3
	  dis_region1-dis_region9 dis_educgrp1-dis_educgrp3 dis_agegrp20-dis_agegrp50
      age20 age30 age40 age50 noweeks racegrp lnwkwage region
      hg_st60 lesshs hsgrad someco colgrad dis_trend count
      cpiw cpiw88 rlwkwage wkwage fnlwgt2 educgrp classid 
	  sampsex classid2 year_d89-year_d96;
run;	  
	  
proc means data=one;
title 'descriptive statistics';

proc sort data=one; by sample descending year descending disabl1;
run;

*********************************************;
* REGRESSIONS;
*********************************************;

* COLUMN 1 -- BASELINE;
proc glm data=one order=data;
where sex=1;
weight fnlwgt2; 
title 'Men, Baseline of Table 3';
class year agegrp racegrp educgrp region disabl1  ;
model wkswork =  
      year agegrp racegrp educgrp region year*agegrp year*racegrp
      year*educgrp year*region
      disabl1 dis_yr92-dis_yr97/solution;
by sample;

proc glm data=one order=data;
where sex=2 & sample='young';
weight fnlwgt2; 
title 'Women, Baseline of Table 3';
class year agegrp racegrp educgrp region disabl1  ;
model wkswork =  
      year agegrp racegrp educgrp region year*agegrp year*racegrp
      year*educgrp year*region
      disabl1 dis_yr92-dis_yr97/solution;
run;

* COLUMN 2 -- NO CONTORL;
proc glm data=one order=data;
where sex=1;
weight fnlwgt2; 
title 'Men, No Control of Table 3';
class year agegrp racegrp educgrp region disabl1  ;
model wkswork =  
     year disabl1 dis_yr92-dis_yr97/solution;
by sample; 

proc glm data=one order=data;
where sex=2 & sample='young';
weight fnlwgt2; 
title 'Women, No Control of Table 3';
class year agegrp racegrp educgrp region disabl1  ;
model wkswork =  
      year disabl1 dis_yr92-dis_yr97/solution;
run;

* COLUMN 3 -- REGRESSION CONTROL;
proc glm data=one order=data;
where sex=1 & sample='young';
weight fnlwgt2; 
title 'Men, Baseline of Table 3 - young group';
class year agegrp racegrp educgrp region disabl1  ;
model wkswork =  
      year agegrp racegrp educgrp region year*agegrp year*racegrp
      year*educgrp year*region
	  dis_racegrp1-dis_racegrp2
	  dis_region1-dis_region8 dis_educgrp1-dis_educgrp2 dis_agegrp20
	  disabl1 dis_yr92-dis_yr97/solution;
run;

proc glm data=one order=data;
where sex=1 & sample='old';
weight fnlwgt2; 
title 'Men, Baseline of Table 3 - older group';
class year agegrp racegrp educgrp region disabl1  ;
model wkswork =  
      year agegrp racegrp educgrp region year*agegrp year*racegrp
      year*educgrp year*region
	  dis_racegrp1-dis_racegrp2
	  dis_region1-dis_region8 dis_educgrp1-dis_educgrp2 dis_agegrp40
	  disabl1 dis_yr92-dis_yr97/solution;
run;

proc glm data=one order=data;
where sex=2 & sample='young';
weight fnlwgt2; 
title 'Women, Baseline of Table 3';
class year agegrp racegrp educgrp region disabl1  ;
model wkswork =  
        year agegrp racegrp educgrp region year*agegrp year*racegrp
      year*educgrp year*region
	  dis_racegrp1-dis_racegrp2
	  dis_region1-dis_region8 dis_educgrp1-dis_educgrp2 dis_agegrp20
	  disabl1 dis_yr92-dis_yr97/solution;
run;

**********************************;
* COLUMN 4;
* SORT BY BY-GROUP;
**********************************;
proc sort data=one; 
	by classid2; 
	where sex=1 | (sex=2 & sample='young');
	run;
	
proc reg data=one outest=ests outseb noprint;
weight fnlwgt2; 
model wkswork =  year_d89-year_d96 disabl1 dis_yr92-dis_yr97;
by classid2;
run;

* MAKE TWO DATASETS -- ONE WITH STANDARD ERRORS AND ONE WITH COEFF ESTS;
data coeffs (keep=_TYPE_ classid2 sampsex disabl1 dis_yr92-dis_yr97) 
	 ses    (keep=_TYPE_ classid2 sampsex disabl1 dis_yr92-dis_yr97);
set ests;
	if _TYPE_='PARMS' then output coeffs;
	if _TYPE_='SEB' then output ses;
	run;

* GET SHARE OF DISABLED WHO LIVE IN EACH CLASS;
proc summary data=one;
	weight fnlwgt2;
	where disabl1=1 & (88<=year<=91);
	by classid sampsex;
	var count; output out=wtds sumwgt=diswt;
	run;
	
proc sort data=one; by sampsex; run;

proc summary data=one; 
	weight fnlwgt2;
	where disabl1=1 & (88<=year<=91);
	by sampsex;
	var count;
	output out=totals sumwgt=totdiswt
	run;

proc sort data=wtds; by sampsex; 
proc sort data=totals; by sampsex; run;	

data wtds2;
	merge wtds totals;
	by sampsex; run;
data wtds2;
	set wtds2;
	if diswt=. then diswt=0;
	diswt=diswt/100;
		totdiswt=totdiswt/100;
		fracdis=diswt/totdiswt;
	drop _FREQ_ _TYPE_;
	classid2=classid||sampsex;
	run;

* MERGE ONTO REGRESSION AND STANDARD ERROR RESULTS;
proc sort data=wtds2; by classid2;
proc sort data=coeffs; by classid2;
proc sort data=ses; by classid2; 
run;

data makeests;
	merge wtds2 (in=a) coeffs (in=b) ses (in=c rename=(disabl1=disabl1_s dis_yr92=dis_yr92_s dis_yr93=dis_yr93_s
			dis_yr94=dis_yr94_s dis_yr95=dis_yr95_s dis_yr96=dis_yr96_s dis_yr97=dis_yr97_s));
	by classid2; 
	if a & b & c;
	* SQUARE UP TO VARIANCE TO DO WEIGHTING;
	disabl1_s=disabl1_s**2; dis_yr92_s=dis_yr92_s**2; dis_yr93_s=dis_yr93_s**2; 
	dis_yr94_s=dis_yr94_s**2; dis_yr95_s=dis_yr95_s**2;
	dis_yr96_s=dis_yr96_s**2; dis_yr97_s=dis_yr97_s**2;
	run;
	
proc sort data=makeests;
	by sampsex;
	run;
	
data finalests (keep=disabl1_c dis_yr92_c dis_yr93_c dis_yr94_c dis_yr95_c 
			dis_yr96_c dis_yr97_c disabl1_se dis_yr92_se dis_yr93_se dis_yr94_se dis_yr95_se 
			dis_yr96_se dis_yr97_se disabl1_wt dis_yr92_wt dis_yr93_wt dis_yr94_wt dis_yr95_wt 
			dis_yr96_wt dis_yr97_wt sampsex);
	set makeests;
	by sampsex;
	retain disabl1_c 0 dis_yr92_c 0 dis_yr93_c 0 dis_yr94_c 0 dis_yr95_c 0 
			dis_yr96_c 0 dis_yr97_c 0
		disabl1_se 0 dis_yr92_se 0 dis_yr93_se 0 dis_yr94_se 0 dis_yr95_se 0 
			dis_yr96_se 0 dis_yr97_se 0
		disabl1_wt 0 dis_yr92_wt 0 dis_yr93_wt 0 dis_yr94_wt 0 dis_yr95_wt 0 
			dis_yr96_wt 0 dis_yr97_wt 0;
			
	correct= (disabl1_s ne . & dis_yr92_s ne . & dis_yr93_s ne . & 
			  dis_yr94_s ne . & dis_yr95_s ne . & dis_yr96_s ne . & 
			  dis_yr97_s ne .);
	
 if first.sampsex then do;
	disabl1_c=0; dis_yr92_c=0; dis_yr93_c=0; dis_yr94_c=0; dis_yr95_c=0; 
		dis_yr96_c=0; dis_yr97_c=0;
	disabl1_se=0; dis_yr92_se=0; dis_yr93_se=0; dis_yr94_se=0; dis_yr95_se=0; 
		dis_yr96_se=0; dis_yr97_se=0;
	disabl1_wt=0; dis_yr92_wt=0; dis_yr93_wt=0; dis_yr94_wt=0; dis_yr95_wt=0; 
		dis_yr96_wt=0; dis_yr97_wt=0;
	%macro rep(var);
		oldway=0; if &var._s ne . then oldway=1;  
		 if &flag=1 then &var._c= &var._c+fracdis*&var.;
		 if &flag=1 then &var._se= &var._se+(fracdis**2)*&var._s;
		 if &flag=1 then &var._wt= &var._wt+fracdis;
	%mend;
	%rep(disabl1); 	%rep(dis_yr92); %rep(dis_yr93); %rep(dis_yr94);
	%rep(dis_yr95); %rep(dis_yr96); %rep(dis_yr97);
	end;
	
 else do;
  	%rep(disabl1); 	%rep(dis_yr92); %rep(dis_yr93); %rep(dis_yr94);
	%rep(dis_yr95); %rep(dis_yr96); %rep(dis_yr97);
    end;
	
if last.sampsex then output;
	run;
	
data finalests (keep=disabl1_c dis_yr92_c dis_yr93_c dis_yr94_c dis_yr95_c 
			   dis_yr96_c dis_yr97_c disabl1_se dis_yr92_se dis_yr93_se 
			   dis_yr94_se dis_yr95_se dis_yr96_se dis_yr97_se sampsex);
	set finalests;
	test='correct';
%macro runit(var);
		if test=&marker then do;
		&var._c=&var._c/&var._wt;
		&var._se=(&var._se/(&var._wt**2))**.5;
		end;
	%mend;
	%runit(disabl1); 	%runit(dis_yr92); %runit(dis_yr93); %runit(dis_yr94);
	%runit(dis_yr95); %runit(dis_yr96); %runit(dis_yr97);
run;
	
proc print data=finalests;  run;

* LOOK AT SAMPLE SIZES;
proc freq data=one;
table sampsex;
	where fnlwgt2>0;
run;