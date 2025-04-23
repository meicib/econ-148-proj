options ls=85 ps=500 nocenter;

/* jda1b.sas -- revised from newt1b 10-23-00
   for JPE
   Results for table 1 - descriptive statistics */
/* revised 11/16/98 */
/* using revised basic CPS weights for 1990-93 */

libname save '/bbkinghome/sschaner/Angrist Work/Web Papers/ada/sasdata';

*******************;
** basic recodes **;
*******************;

data one;
 set save.marcps_w;

 if 21<=age<=58; 

/* if sex=1; */

 if ((wkswork>0) and (wsal_val>0)) then lnwkwage=log(wsal_val/wkswork);
 if (wkswork>0) then wkwage=(wsal_val/wkswork);
 totwage=wsal_val;
 jobwage=ern_val;

 fnlwgt=fnlwgt/100;
 marsupwt=marsupwt/100;
 fnlwgt2=fnlwgt2/100;

 agegrp=10*int(age/10);
 age20=(agegrp=20);
 age30=(agegrp=30);
 age40=(agegrp=40);
 age50=(agegrp=50);

 if age<40 then sample='young'; else sample='old';

 if race=>3 then racegrp=3; else racegrp=race;
 white=(race=1);
 black=(race=2);
 other=(race=3);
 
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
   cpiw=(cpiw/117);

  rlwkwage=wkwage/cpiw;
  wkwage=wkwage/cpiw;

  if ((rlwkwage<25) or (rlwkwage)>2000) then do; lnwkwage=.;
  wkwage=.; end; 

*************************************;
****** federal benefits codes *******;
*************************************;

  di=(ss_val/(cpiw*52))>75;
  oas=((ss_yn=1) and (di=0)); 
  ssi=(ssi_yn=1);
  ssiordi=((ssi=1) or (di=1));
  oasdissi=((ss_yn=1) or (ssi_yn=1));

  label ssi='received SSI ly'
        di='(OASDI/wk)>75 (88 $) ly'
        oas='ss_yn=1 and di=0'
        ssiordi='ssi=1 or di=1'
        oasdissi='ss_yn=1 and ssi_yn=1';

otherdis=(dis_yn=1);

** va benefits **;

 vetcomp=(vet_typ1=1);
 vetsurv=(vet_typ2=1);                                 ** new in extracts;
 vetpens=(vet_typ3=1);                                 ** new in extracts;
 veteduc=(vet_typ4=1);
 vetothr=(vet_typ5=1);
 vetqva=(vet_qva=1);
 anyva=(vet_yn=1);

** other federal **;

 fgdi=((dis_sc1=3) or (dis_sc2=3));
 mildi=((dis_sc1=4) or (dis_sc2=4));
 usrrdi=((dis_sc1=6) or (dis_sc2=6));

/* afdc=(paw_typ=1); */

 afdc=0;

 otherfed=((fgdi=1) or (mildi=1) or (usrrdi=1) or (afdc=1));

** classifications **;

 anyfed=( (oasdissi=1) or (anyva=1) or (otherfed=1) );
 meanstst=( (oasdissi=1) or ((anyva=1) and (vetqva=1)) or (afdc=1) ); 

label anyfed='any federal stipend'
      meanstst='means-tested stiped';

*****************;
** instruments **;
*****************;

*>narrow: vetcomp;

vetcomp2=( (vetcomp=1) or ((fgdi=1) or (mildi=1) or (usrrdi=1)) );
vetcomp3= ( (anyva=1) and (vetqva=0));

label vetcomp='receives vets compensation'
      vetcomp2='vetcomp or fed except afdc'
      vetcomp3='vetcomp or vet educ';

************************;
*** new demographics ***;
************************;

married=(1<=marital<=3);
 widowed=(marital=4);
 divsep=(5<=marital<=6);
veteran=(1<=vet<=5);
 vietserv=(vet=1);
 koraserv=(vet=2);
 othrserv=(3<=vet<=5);

*************************;
*** working data step ***;
*************************;

  trend=(year-87);
  trend2=trend**2;
  dis_yr92=(year=92)*disabl1;
  dis_yr93=(year=93)*disabl1;
  dis_yr94=(year=94)*disabl1; 
  dis_yr95=(year=95)*disabl1;
  dis_yr96=(year=96)*disabl1;
  dis_yr97=(year=97)*disabl1;
 
  dyr_9497=disabl1*(94<=year<=97);

  yr89=(year=89); yr90=(year=90); yr91=(year=91);
  yr92=(year=92); yr93=(year=93); yr94=(year=94);
  yr95=(year=95); yr96=(year=96); yr97=(year=97);

 trend_d=trend*disabl1;

 age2=age**2;

posths=(someco=1 or colgrad=1);

south=(5=<region=<7);
west=(8=<region=<9);

if mod(year,2)=0;


length veteran vietserv koraserv othrserv veteduc vetsurv vetothr vetqva
       vetcomp vetpens anyva vetcomp2 vetcomp3 afdc posths
       di ssi ssiordi oas oasdissi racegrp agegrp age20 age30 age40 age50 
       white black other married widowed divsep  otherdis
       fgdi mildi usrrdi agegrp meanstst otherfed anyfed meanstst
       yr89-yr97 dis_yr92-dis_yr97 dyr_9497 trend trend2 trend_d 3;

  keep age age2 agegrp year sex disabl1 disabl2 disabl3 
       fnlwgt marsupwt dis_sc1 dis_sc2 wkwage lnwkwage
       age20 age30 age40 age50 racegrp hg_st60 otherdis
       working unempl nilf wkswork white black other posths
       hsgrad someco colgrad region centralc balmsa sample
       veteran vietserv koraserv othrserv dis_yn vet_yn afdc
       married widowed divsep vet_typ1 vet_typ2 vet_typ3
       vet_typ4 vet_typ5 veteduc vetsurv vetothr vetqva 
       vetcomp vetcomp2 vetcomp3 vetpens anyva vetcomp2
       di ssi ssiordi oas oasdissi meanstst otherfed anyfed
       yr89-yr97 dis_yr92-dis_yr97 dyr_9497 trend trend2 trend_d
       cpiw rlwkwage fnlwgt2 region south west;

******************************;
** yearly rates/nonsmoothed **;
******************************;

proc sort data=one;
 by descending disabl1 sex descending sample year;

proc summary data=one;
 weight fnlwgt2;
 var age white posths working  
     wkswork wkwage ssiordi;
 output out=two mean=;
 by descending disabl1 sex descending sample year;

proc print;
title 'descriptive statistics in even years';
run;




