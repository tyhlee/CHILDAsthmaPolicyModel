# Will use JuliaCall to write an R package
# It has been used at least 6 times to wrap a Juali package into an R package
# For examples, see:
# https://github.com/Non-Contradiction/JuliaCall/blob/master/README.md

# For a local version, you must add the Julia package via github in JULIA
# type ']' in Julia REPL and
# type 'add https://github.com/tyhlee/Asthma_Julia.git'
# Whenever there is an update to the repo,
# type 'up Asthma_Julia'

library(JuliaCall)
julia <- JuliaCall::julia_setup()

# import the Julia pkg
julia_command("using Asthma_Julia")
# you might be missing some packages then do:
# julia$install_package("PKG_NAME")

# check the available variables/functions in the pkg
julia_command("names(Asthma_Julia)")

julia_command("simulation = set_up()")
# field names of Simulation (struct)
julia_command("fieldnames(Asthma_Julia.Simulation)")
look <- julia_eval("fieldnames(Asthma_Julia.Simulation)")
look <- julia_eval("simulation.incidence")
look <- julia_eval("simulation.n")

sim <- julia_eval("simulation")
tmp <- julia_eval("simulation.incidence")

# you can check whether this object exists in "Julia"
julia_exists('simulation')

# you can re-set any of the fields in the struct using @set!
# this is the pkg allowing us to change the struct fields easily
julia_command("using Setfield")
julia_command("@set! simulation.n = 1000;")
julia_command("results = process(simulation)")
look <- julia_eval("results")

# check whether it is indeed 1000
julia_eval("simulation.n")

# Set parameter values for antibotic exposure module
# let's say the baseline is 20%
julia_command('@set! simulation.AntibioticExposure.hyperparameters[:β0_μ] =-1.49;')
julia_command('@set! simulation.AntibioticExposure.hyperparameters[:β0_σ] =0.5;')
julia_command('@set! simulation.AntibioticExposure.parameters[:βage] = -1.0;')
julia_command('@set! simulation.AntibioticExposure.parameters[:βsex] = 0.0;')
julia_command('@set! simulation.AntibioticExposure.parameters[:βcal_year] = -0.01;')

# julia_command('@set! simulation.Incidence.hyperparameters[:β0_μ] = -3.953;')
julia_command('@set! simulation.Incidence.hyperparameters[:β0_μ] = -4.53;')
julia_command('@set! simulation.Incidence.hyperparameters[:β0_σ] = 1.678e-1;')
julia_command('@set! simulation.Incidence.parameters[:βage] = -2.334e-01;')
julia_command('@set! simulation.Incidence.parameters[:βage2] = 8.529e-03;')
julia_command('@set! simulation.Incidence.parameters[:βage3] = -1.283e-04;')
julia_command('@set! simulation.Incidence.parameters[:βage4] = 7.046e-07;')
julia_command('@set! simulation.Incidence.parameters[:βage5] =  -1.111e-10 ;')
julia_command('@set! simulation.Incidence.parameters[:βageM] = -6.904e-02 ;')
julia_command('@set! simulation.Incidence.parameters[:βage2M] = -6.840e-04;')
julia_command('@set! simulation.Incidence.parameters[:βage3M] = 1.375e-04;')
julia_command('@set! simulation.Incidence.parameters[:βage4M] = -2.964e-06 ;')
julia_command('@set! simulation.Incidence.parameters[:βage5M] = 1.883e-08;')
julia_command('@set! simulation.Incidence.parameters[:βsex] = 4.506e-1;')
julia_command('@set! simulation.Incidence.parameters[:βcal_year] = -0.02549;')
julia_command('@set! simulation.Incidence.parameters[:βcal_yearM] = -0.02594;')
# julia_command('@set! simulation.Incidence.parameters[:βcal_year] = -0.0;')
# julia_command('@set! simulation.Incidence.parameters[:βcal_yearM] = -0.0;')
# incidence quite low;') assume RR = OR = 1.5
# => log(1.5) ~= 0.4
julia_command('@set! simulation.Incidence.parameters[:βCABE] = 0.4;')

julia_command('@set! simulation.Control.hyperparameters[:β0_μ] = 0;')
julia_command('@set! simulation.Control.hyperparameters[:β0_σ] = 1.67;')
julia_command('@set! simulation.Control.parameters[:βage] = 3.6395;')
julia_command('@set! simulation.Control.parameters[:βage2] = -3.9046;')
julia_command('@set! simulation.Control.parameters[:βsexage] = -1.8910;')
julia_command('@set! simulation.Control.parameters[:βDx2] = -0.5931;')
julia_command('@set! simulation.Control.parameters[:βDx3] =  -0.0455 ;')
julia_command('@set! simulation.Control.parameters[:βsex] =  0.4111;')
julia_command('@set! simulation.Control.parameters[:θ] =  [-1.1043; 2.0709];')

julia_command('@set! simulation.Exacerbation.hyperparameters[:β0_μ] = 0;')
julia_command('@set! simulation.Exacerbation.hyperparameters[:β0_σ] = 0.0011;')
julia_command('@set! simulation.Exacerbation.parameters[:βage] = 0;')
julia_command('@set! simulation.Exacerbation.parameters[:βsex] = 0;')
julia_command('@set! simulation.Exacerbation.parameters[:βasthmaDx] = 0;')
julia_command('@set! simulation.Exacerbation.parameters[:βprev_exac1] = 0;')
julia_command('@set! simulation.Exacerbation.parameters[:βprev_exac2] = 0;')
julia_command('@set! simulation.Exacerbation.parameters[:βcontrol_C] =  log(0.1896975);')
julia_command('@set! simulation.Exacerbation.parameters[:βcontrol_PC] =  log(0.3793949);')
julia_command('@set! simulation.Exacerbation.parameters[:βcontrol_UC] =  log(0.5690924);')
julia_command('@set! simulation.Exacerbation.parameters[:βcontrol] =  0;')

# julia_command('@set! simulation.Exacerbation.hyperparameters[:β0_μ] = 0;')
# julia_command('@set! simulation.Exacerbation.hyperparameters[:β0_σ] = 1;')
# julia_command('@set! simulation.Exacerbation.parameters[:βage] = 0;')
# julia_command('@set! simulation.Exacerbation.parameters[:βsex] = log(1.22);')
# julia_command('@set! simulation.Exacerbation.parameters[:βasthmaDx] = log(0.94);')
# julia_command('@set! simulation.Exacerbation.parameters[:βprev_exac1] = log(2.28);')
# julia_command('@set! simulation.Exacerbation.parameters[:βprev_exac2] =  log(1.5) ;')
# julia_command('@set! simulation.Exacerbation.parameters[:βcontrol] =  log(1.20);')

julia_command("@set! simulation.n = 1000;")
julia_command("@set! simulation.max_age = 5;")
julia_command("@set! simulation.time_horizon = 20;")
look <- julia_eval("look = (; n=50,b=[1;2;3])")

julia_eval("results = Asthma_Julia.run(simulation);")
results <- julia_eval("simulation.OutcomeMatrix")

# TODO: process and visualize control data

# burn-in period: 5
# sex: 1 = F, 2 = M
fig.dir <-paste0("figures/March_9_2021")
dir.create(fig.dir)

library(tidyverse)
library(here)
total <- results$n
total <- total %>% 
  as.data.frame()
colnames(total) <- c("Female","Male")
total <- total %>% 
  mutate(Both=Female+Male) %>% 
  mutate(Year = row_number()+2015-1)
df_total <- total %>% 
  gather('sex','n',-Year)

ggplot(data=df_total,aes(x=Year,y=n,color=sex)) +
  geom_line() +
  theme_bw() +
  ylim(0,max(df_total$n)) -> gg.n
ggsave(here(fig.dir,"n.png"),plot = gg.n,device = 'png')

control_list <- list(controlled=results$outcome_matrix$control1,
                     partial= results$outcome_matrix$control2,
                     uncontrolled = results$outcome_matrix$control3)
burn_in_period <- 5
df_control <- lapply(control_list, function(x){
  rowSums((x[[1]] + x[[2]]))[-c(1:burn_in_period)]
})

df_control <- do.call(cbind,df_control) %>% 
  as.data.frame() %>%
  mutate(Year=row_number()+2015-1) %>% 
  group_by(Year) %>% 
  mutate(n=sum(controlled,partial,uncontrolled),
         controlled=controlled/n,
         partial = partial/n,
         uncontrolled=uncontrolled/n) %>% 
  gather("Control_level","Prob",1:3)

ggplot(data=df_control, aes(x=Year,y=Prob,colour=Control_level))+
  geom_line() +
  theme_bw()+
  ylim(0,1) -> gg.control
ggsave(here(fig.dir,"control.png"),plot = gg.control,device = 'png')

event_matrix_gather_helper <- function(event_matrix,event_index=1,sex=1,burn_in_period=5){
  # cal_year by age
  tmp <- event_matrix[[event_index]][[sex]]
  if(burn_in_period>0){
  tmp <- tmp[-c(1:burn_in_period),]
  }
  tmp <- tmp %>% 
    as.data.frame() %>% 
    mutate(Year=row_number()+2015-1+burn_in_period)
  colnames(tmp)[-ncol(tmp)] <- c(0:(ncol(tmp)-2))
  event_name <- as.character(names(event_matrix)[event_index])
  df_tmp <- tmp %>% 
    gather(key="age",value="value",-Year)
  df_tmp$outcome <- event_name
  df_tmp$sex <- sex
  return(df_tmp)
}

event_matrix_gather <- function(event_matrix,chosen_index,burn_in_period=5){
  tmp_df <- c()
  counter <<- 1
  for (j in 1:length(chosen_index)){
    tmp_index <- chosen_index[j]
    tmp_df[[counter]] <- event_matrix_gather_helper(event_matrix,tmp_index,1,burn_in_period)
    counter <<- counter + 1
    tmp_df[[counter]] <- event_matrix_gather_helper(event_matrix,tmp_index,2,burn_in_period)
    counter <<- counter + 1
  }
  tmp_df <- do.call(rbind,tmp_df)
  return(tmp_df)
}

df_outcome <- event_matrix_gather(results$outcome_matrix,
                                  setdiff(1:length(results$outcome_matrix),
                                          grep("control",names(results$outcome_matrix))))

df_outcome$age <- as.numeric(df_outcome$age)

# total
df_outcome %>% 
  group_by(Year,outcome) %>% 
  summarise(total=sum(value)) -> df_outcome_cal_year

outcome_all_plotter <- function(outcome_cal_year,outcome_name){
  tmp <- outcome_cal_year %>% 
    filter(outcome==outcome_name)
  ggplot(data=tmp,aes(x=Year,y=total)) +
    geom_line() +
    theme_bw()+
    ylab(outcome_name) +
    ylim(0,max(tmp$total))
}

save_plot <- function(gg,index,type='png',dir='figures'){
  ggsave(here(dir, paste0(outcome_name_list[index],'.','png') ),plot=gg,device=type)
}

for (j in 1:length(outcome_name_list)){
  save_plot(outcome_all_plotter(df_outcome_cal_year,outcome_name_list[[j]]),j,dir=fig.dir)
}

# exacerbation
(df_outcome_cal_year %>% filter(outcome=='exacerbation'))$total/look$n

gg_exac <- df_outcome_cal_year %>% filter(outcome=='exacerbation')
gg_exac$total <- gg_exac$total/(df_outcome_cal_year %>% filter(outcome=="asthma_prevalence"))$total
gg_exac <- ggplot(data=gg_exac,aes(x=Year,y=total)) +
  geom_line() +
  theme_bw()+
  ylab("Exacerbation rate for asthma patients") +
  ylim(0,max(gg_exac$total))
ggsave(here(fig.dir, paste0("exacerbation_rate",'.','png') ),plot=gg_exac,device='png')

age_limit <- 6

outcome_plotter <- function(outcome_matrix,age_limit,outcome_name){
  ggplot(data=outcome_matrix %>% 
           filter(age<=age_limit & outcome==outcome_name),
         aes(x=Year,y=value))+
    geom_line(aes(y=value))+
    facet_grid(sex~age) +
    ylab(outcome_name)
}

outcome_name_list <- df_outcome$outcome %>% unique()

gg_all <- lapply(df_outcome$outcome %>% unique(), function(x){
  outcome_plotter(df_outcome,age_limit,x)
})

names(gg_all) <- outcome_name_list
gg_all$antibiotic_exposure
gg_all$asthma_prevalence
gg_all$asthma_incidence
gg_all$exacerbation
gg_all$death

