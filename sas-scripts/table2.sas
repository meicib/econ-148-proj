options ls=80 ps=500 nocenter;

/* 
   jdatbl2.sas -- check table 2 for JPE -- 10-18-00

   Revision of table 2, 10/25/98  */

/* Using revised basic CPS weights for 1990-93 */


libname save 'DIRECTORY HERE';

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

 keep age agegrp year sex disabl1 totwage jobwage sample
      working unempl nilf jobloser wkswork workly
      hsgrad someco colgrad region centralc balmsa trend 
      dis_yr89-dis_yr97 dyr_9497 fnlwgt 
      age20 age30 age40 age50 noweeks racegrp lnwkwage region
      hg_st60 lesshs hsgrad someco colgrad dis_trend
      cpiw cpiw88 rlwkwage wkwage fnlwgt2 educgrp;

proc means data=one;
title 'descriptive statistics';

proc sort data=one; by sample descending year descending disabl1;

/* results using new weights */

proc glm data=one order=data;
where sex=1;
weight fnlwgt2; 
title 'outcomes for  -- men -- NO trend -- add 89-91 year dummies';
class year agegrp racegrp educgrp region disabl1  ;
model wkswork lnwkwage =  
      year agegrp racegrp educgrp region year*agegrp year*racegrp
      year*educgrp year*region
      disabl1 dis_yr89-dis_yr97/solution;
by sample;

proc glm data=one order=data;
where sex=2;
weight fnlwgt2; 
title 'outcomes for  -- women  -- NO trend -- add 89-91 year dummies';
class year agegrp racegrp educgrp region disabl1  ;
model wkswork lnwkwage =  
      year agegrp racegrp educgrp region year*agegrp year*racegrp
      year*educgrp year*region
      disabl1 dis_yr89-dis_yr97/solution;
by sample;
run;

*************************************************;
* WITH A TREND;
*************************************************;

proc glm data=one order=data;
where sex=1;
weight fnlwgt2; 
title 'outcomes for  -- men -- trend';
class year agegrp racegrp educgrp region disabl1  ;
model wkswork lnwkwage =  
      year agegrp racegrp educgrp region year*agegrp year*racegrp
      year*educgrp year*region
      disabl1 dis_yr92-dis_yr97 dis_trend/solution;
by sample;

proc glm data=one order=data;
where sex=2;
weight fnlwgt2; 
title 'outcomes for  -- women  -- trend';
class year agegrp racegrp educgrp region disabl1  ;
model wkswork lnwkwage =  
      year agegrp racegrp educgrp region year*agegrp year*racegrp
      year*educgrp year*region
      disabl1 dis_yr92-dis_yr97 dis_trend/solution;
by sample;
run;
