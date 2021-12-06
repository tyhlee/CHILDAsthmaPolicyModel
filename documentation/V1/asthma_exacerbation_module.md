# Asthma exacerbation module 
* Input: sex, age, time since asthma diagnosis (Dx), asthma control, and previous asthma exacerbations
* We used a Poisson model for the number of asthma exacerbations using the Economic Burden of Asthma study and the Gaining Asthma controL (GOAL) study.
* For V1, we only incorporated the effect of asthma control.
* From the EBA study, we obtained the annnnnnnnnual exacerbation rate, which was 0.347/year. Next, from the GOAL study, we obtained the probability of exacerbation given the control levels. Combining both, we obtained the unique rate of exacerbation given the control level. For details, see [here](../../issues/3).
* For agent $i$, let $Y_{i,t}$ be the number of exacerbations in year $t$:
$$Y_{i,t} = Poisson(\lambda_{i,t}),$$ where
$$\lambda_{i,t}=\lambda(X_{i,t}) = \exp(\beta_{0,i}+ \beta_{sex} \times sex + \beta_{age} \times age + \beta_{Dx} \times Dx + \beta_{prev\_exac} \times prev\_exac + \beta_{control} \times control)$$ with $\beta_{0,i} \sim Normal(\mu_0,\sigma^2_0).$