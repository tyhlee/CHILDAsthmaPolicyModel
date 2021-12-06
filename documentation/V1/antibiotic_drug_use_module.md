# Antibiotic drug use module
* Input: sex, age, and calendar year.
* We used a logistic regression to model whether an agent receives one dose of antibiotic drug.
* For ageint $i$,
$$logit(p_{antibiotic\_drug})=\beta_{0,i} + \beta_{sex} \times sex + \beta_{age} \times age + \beta_{cal\_year} \times cal\_year,$$ where $\beta_{i,0} \sim Normal(\mu_0,\sigma^2_0)$.
* Parameter estimates were based on the data provided in Patrick et al., Lancet Respiratory, 2020.
