
*****************************;
* PROGRAM: AceAng2001_Table4 ;
* PROGRAMMER: Simone Schaner ;
* PURPOSE: Recreates Table 4 ;
* 	of Acemoglu and Angrist	 ;
*	(2001).	(Columns 1-3)	 ;
* DATE CREATED: 8/6/07		 ;
* NOTES: This code is copied ;
*	from old code written by ;
*	Chris Mazingo			 ;
*****************************;

libname z1 '/bbkinghome/sschaner/Angrist Work/Web Papers/AcemogluAngrist_2001/sasdata/FromJoshsPC/';
libname z2 '/bbkinghome/sschaner/Angrist Work/Web Papers/AcemogluAngrist_2001/sasdata/';


 
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

************************************************;
* FEDERAL BENEFITS CODES						;
************************************************;

di= (ss_val/(cpiw*52))>75;
oas= ((ss_yn=1) and (di=0));
ssi= (ssi_yn=1);
ssiordi= ((ssi_yn=1) or (di=1));
oasdissi= ((ssi_yn=1) or (ss_yn=1));
	label ssi='Received SSI ly'
			di='(OASDI/wk)>75 ($88) ly'
			oas='ss_yn=1 and di=0'
			ssiordi='ssi=1 or di=1'
			oasdissi='ss_yn=1 or ssi_yn=1';
			
length oas ssi ssiordi oasdissi 3;

* KEEP STUFF;
keep age agegrp year sex disabl1 totwage jobwage sample
	working unempl nilf jobloser wkswork workly 
	hsgrad someco colgrad region centralc balmsa trend
	dis_yr92-dis_yr97 dyr_9497 fnlwgt 
	age20 age30 age40 age50 noweeks racegrp lnwkwage
	hg_st60 lesshs cpiw cpiw88 rlwkwage wkwage fnlwgt2 
	educgrp di ss_val oas ss_yn ssi ssiordi oasdissi;
run;

proc sort data=one; by sample descending year descending disabl1;
run;

* COLUMN 1;
proc glm data=one order=data;
	where sex=1 & oasdissi=0;
	weight fnlwgt2;
	title 'outcomes for men - no ssa recipients, no trend';
	class year agegrp racegrp educgrp region disabl1;
	model wkswork =
		year agegrp racegrp educgrp region year*agegrp year*racegrp
		year*educgrp year*region disabl1 dis_yr92-dis_yr97/solution;
	by sample;
	run;
proc glm data=one order=data;
	where sex=2 & oasdissi=0 & sample='young';
	weight fnlwgt2;
	title 'outcomes for women - no ssa recipients, no trend';
	class year agegrp racegrp educgrp region disabl1;
	model wkswork =
		year agegrp racegrp educgrp region year*agegrp year*racegrp
		year*educgrp year*region disabl1 dis_yr92-dis_yr97/solution;
	run;

* COLUMN 2;
proc glm data=one order=data;
	where sex=1 & oasdissi=0;
	weight fnlwgt2;
	title 'outcomes for men - no ssa recipients, trend';
	class year agegrp racegrp educgrp region disabl1;
	model wkswork =
		year agegrp racegrp educgrp region year*agegrp year*racegrp
		year*educgrp year*region trend trend*disabl1 disabl1 dis_yr92-dis_yr97/solution;
	by sample;
	run;
proc glm data=one order=data;
	where sex=2 & oasdissi=0 & sample='young';
	weight fnlwgt2;
	title 'outcomes for women - no ssa recipients, trend';
	class year agegrp racegrp educgrp region disabl1;
	model wkswork =
		year agegrp racegrp educgrp region year*agegrp year*racegrp
		year*educgrp year*region trend trend*disabl1 disabl1 dis_yr92-dis_yr97/solution;
	run;


* COLUMN 3;
proc glm data=one order=data;
	where sex=1;
	weight fnlwgt2;
	title 'outcomes for men - full sample,  no trend, OASDI/SSI dummy';
	class year agegrp racegrp educgrp region disabl1;
	model wkswork =
		year agegrp racegrp educgrp region year*agegrp year*racegrp
		year*educgrp year*region disabl1 dis_yr92-dis_yr97 oasdissi/solution;
	by sample;
	run;
proc glm data=one order=data;
	where sex=2 and sample='young';
	weight fnlwgt2;
	title 'outcomes for women - full sample, no trend, OASDI/SSI dummy';
	class year agegrp racegrp educgrp region disabl1;
	model wkswork =
		year agegrp racegrp educgrp region year*agegrp year*racegrp
		year*educgrp year*region disabl1 dis_yr92-dis_yr97 oasdissi/solution;
	run;	
