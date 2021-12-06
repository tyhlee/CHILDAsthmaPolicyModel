# Asthma incidence module 
* Input: sex, age, calendar year (cal_year), the cumulated number of antibiotic drug doses (CABE)
* We used a logistic regression model to determine whether an agent gets asthma. The parameter estimates were obtained using the asthma incidence rates provided by SickKids, Toronto, Ontario, Canada (here is the [link](https://lab.research.sickkids.ca/oasis/data-tables/)).
* An estimate of the effect of antibiotic drug use was extracted from Patrick, et al., Lancet Respiratory, 2020. We assume that the effect  is only present for age < 11 years.
* Here is the equation for agent $i$:
$$logit(p_i) = \beta_{0,i} + \beta_{sex} \times sex + \beta_{age} \times age + \beta_{sex,age} \times (sex * age) +\\ \beta_{cal\_year} \times cal\_year + \beta_{sex,cal\_year} \times sex * cal\_year + \beta_{CABE} \times (CABE * \mathbf{1}[age < 11]),$$ where $\beta_{0,i} \sim Normal(\mu_0,\sigma^2_0).$

