todo:

  ☐ check pid==21352001 (other real estate)
  ☐ deflate wealth variables
  ☐ model 2020 wealth properly 
  ☐ try cnorm and other models in TRAJ

modeling long run: 

  ☐ longitudinal clustering (done in stata traj+trajplot)
    ☐ understand better the modeling
  
  ☐ modelling long run:
    ☐ model with avg and sd health scores on wealth. (reg_dynamic)
    ☐ why only 67k obs (from +90k universe?)  


modelling short run:
  ☐ run logit: decease on wealth_deciles + controls (age, education, gender, +)


robustness models:
  
  ✘ survival model (mortality rate) @not_doing @cancelled (22-09-01 14:02)
  ☐ grip strength (check on physical health)

done: 

  ✔ gather panel data structure (Stata) @done (22-09-01 13:41)
  ✔ check how to deal with wealth data from OwnCloud scripts @done (22-09-01 13:41)
  ✔ merge with health module @done (22-09-01 13:41)
  ✘ ask Grabka about health modules, how they construct the SF-12v2 variables @cancelled (22-09-01 14:01)
  done, but no answer



summary of meeting (19 Jul, Johannes, Carsten):

 ☐ **Carsten**: Dataset: SOEP 2002, 2007, 2012, 2017, 2019 Excluding rich sample in 2019 Analyses:
  ☐ 1) For every year, descriptive statistics of core variables: Mean, SD, share of missings 
  ☐ 2) Box plots of satisfaction with health 
    a. by net wealth quartiles
    b. by age groups
    c. for each age group: by net wealth quartiles 
  ☐ 3) xtLogit: dummy of having a certain disease on: net wealth quartiles, age dummies …. + Margins Margins plot 
  ☐ 4) xtologit (or xtreg) of health satisfaction on: net wealth quartiles, having a certain disease, interaction net wealth quartiles x having a certain disease, age dummies …. External validation of health variables: Compare pop shares in SOEP with a certain disease and external admin statistics

good point: Say, a diagnosis has been detected, how does health (life) satisfaction evolve over time for differnt wealth groups



☐ - talk about miopia instead of more general irrationality 
☐ - condition on having X, how health satisfaction across wealth distr. 
☐ - check private/statutory insurance
☐ - check against external statistics for validity of self-response  
  ☐ - **Johannes**: Nr. of sick days seems to hold

data sources:

 ☐ IAB: https://www.iab.de/en/ueberblick.aspx
 ☐ INKAR: geographical indicators at _(Land/)Kreis_ level



/* 
TODO: (JKönig on 7 Sept 2021)
 - 2002, 2007, 2012, 17 19
 - pull wealth for those years, 
 - make w_diff 
 - convince that it does not change over time. 
 - in thous. in logs, 
 - show kdensity for every year 
 - plot
    - average change of w_diff over age (~~> life cycle savings model)

- dont do interpolation 
    -> 2012 wealth into 2011, disregard 2015
--> make sure w_diff h_diff follow same structure

*/


### older

/*  Discussed with johannes
Main points:
  - sample at risk with baseline in 2011
  - track changes into sickness (for each disease) on 17 and 19
  - drop P, M and L samples 
    - why drop L?
  - have a look at resources (britton_french2021, xlsx, fossen_könig2017)
  - run logit: decease on wealth_deciles + controls (age, education, gender, +)
*/
