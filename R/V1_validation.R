# Will use JuliaCall to write an R package
# It has been used at least 6 times to wrap a Juali package into an R package
# For examples, see:
# https://github.com/Non-Contradiction/JuliaCall/blob/master/README.md

# For a local version, you must add the Julia package via github in JULIA
# type ']' in Julia REPL and
# type 'add https://github.com/tyhlee/Asthma_Julia.git'
# Whenever there is an update to the repo,
# type 'up Asthma_Julia'

# import pre-calibrated data
library(JuliaCall)
julia <- JuliaCall::julia_setup()
julia_command("using JLD2")
julia_command("using JLD")


# import results ----------------------------------------------------------

# demographic module calibration:
# results <- julia_eval('JLD2.load("src/simulation_output/V1_demo_0.73.jld")["output"]')

# asthma prevalence/incidence
# results <- julia_eval('JLD2.load("src/simulation_output/V1_asthma.jld")["output"]')

# ABE
# constant ABE
# results <- julia_eval('JLD2.load("src/simulation_output/V1_ABE_constant.jld")["output"]')
# decreasing ABE
# results <- julia_eval('JLD2.load("src/simulation_output/V1_ABE_decreasing.jld")["output"]')
# constant + asthma
# results <- julia_eval('JLD2.load("src/simulation_output/V1_ABE_constant_asthma.jld")["output"]')

# control
# results <- julia_eval('JLD2.load("src/simulation_output/V1_control.jld")["output"]')

# exac
results <- julia_eval('JLD2.load("src/simulation_output/V1_exac.jld")["output"]')

# decreasing + asthma
# results <- julia_eval('JLD2.load("src/simulation_output/V1_ABE_decreasing_asthma.jld")["output"]')
# results <- julia_eval('JLD2.load("src/simulation_output/V1_ABE_decreasing_asthma_0.01.jld")["output"]')

# fig setetings -----------------------------------------------------------
fig_setting <- theme_classic() +
  theme(legend.position = 'top',
        text= element_text(size=25))


# setting
max_year <- nrow(results[[1]])
max_age <- ncol(results[[2]][[1]][[1]])

# helpe function
extract_df <- function(type,sex,year='all',age='all'){
  sex = ifelse(sex=='male',2,
               ifelse(sex=='female',1,
                      sex))
  if(year[1]=='all'){
    year <- 1:max_year
  }
  if(age[1]=='all'){
    age <- 1:max_age
  }
  
  if(sex=='both'){
    return(results[[2]][[type]][[1]][year,age]+results[[2]][[type]][[2]][year,age]) 
  } else{
    return(results[[2]][[type]][[sex]][year,age])
  }
}

total_n <- sum(results[[2]]$alive)
initial_newborns <- 500
baseline_year <- 2020

#sanity check
true_N <- results[[1]] %>% rowSums() %>% cumsum()
alive <- rowSums(extract_df(type = 'alive',sex='both',age='all'))
death <- rowSums(extract_df(type = 'death',sex='both',age='all'))
immi <- rowSums(extract_df(type = 'immigration',sex='both',age='all'))
emi <- rowSums(extract_df(type = 'emigration',sex='both',age='all'))

library(tidyverse)
pop <- read_csv("data-raw/demographic/pop_projection/17100057.csv")
colnames(pop) <- gsub(' ','_',colnames(pop))

pop.canada <- pop %>%
  select(REF_DATE,GEO,Projection_scenario,Sex,Age_group,VALUE) %>% 
  mutate(Projection_scenario = str_remove(Projection_scenario,"Projection scenario "),
         Projection_scenario = str_remove(Projection_scenario, "\\:.*")) %>% 
  filter(GEO=='Canada' &Projection_scenario =='LG') %>% 
  select(-GEO,-Projection_scenario) %>% 
  filter(Sex=='Both sexes') %>% 
  select(-Sex) %>% 
  rename(year=REF_DATE,
         age=Age_group) %>% 
  filter(!str_detect(age,"to|All")) %>% 
  mutate(age=if_else(str_detect(age,"Under"),"0",age),
         age= if_else(str_detect(age,"over"),"100",age),
         age = str_remove(age," years| year"),
         age = as.numeric(age)) %>% 
  filter(year>=baseline_year)



# fig direcotry
library(here)
library(gridExtra)
library(ggpubr)

fig_dir <- here("src","simulation_studies","V1","figures")
save_plot <- function(gg_obj,nam,fig.width=10,fig.height=7,fig.dpi=600,save=F){
  if(save){
    ggsave(paste0(fig_dir,'/',nam),gg_obj,width = fig.width,height=fig.height,dpi = fig.dpi)
  } else{
    "plot not saved"
  }
}
fig_theme <- theme_classic() + 
  theme(legend.position='top')
  
# Number of population generated ------------------------------------------
n_generated <- cbind(Female=extract_df('alive','female',age=1)+extract_df('death','female',age=1),
                     Male=extract_df('alive','male',age=1)+extract_df('death','male',age=1)) %>% 
  as.data.frame() %>% 
  mutate(year=row_number()+baseline_year-1,
         Both=Female+Male) 

ggplot(data=n_generated%>% 
         pivot_longer(cols=-year,names_to='Sex',values_to="n"),
       aes(x=year,y=n,colour=Sex))+
  geom_point() +
  geom_line() + 
  ylab("Number of Newborns") +
  fig_theme -> fig.newborns
save_plot(fig.newborns,"demo_newborns.png")

# assumed
true_prop_male <- 0.512

true_prop <- read_csv(here("src","processed_data","birth_projection.csv")) %>% 
  filter(Projection_scenario=='LG') %>% 
  filter(REF_DATE %in% n_generated$year) %>% 
  select(relative_change)

initial_n <- n_generated$Both[1]
ggplot(data=n_generated%>% 
         mutate(Female=Female/Both,
                Male=Male/Both) %>% 
         select(-Both) %>% 
         pivot_longer(cols=-year,names_to='Sex',values_to="prop"),
       aes(x=year,y=prop,colour=Sex))+
  geom_point() +
  geom_line() + 
  geom_hline(yintercept=0.512)+
  geom_hline(yintercept=1-0.512) +
  ylab("Proportion") +
  ylim(0,0.6)+
  fig_theme -> fig.prop.sex
save_plot(fig.prop.sex,"demo_nb_prop_sex.png")

ggplot(data=n_generated%>% 
         mutate(Both=Both/initial_n) %>% 
         rename(Observed = Both) %>% 
         select(-Female,-Male) %>%
         cbind(True = true_prop$relative_change) %>% 
         pivot_longer(cols=-year,names_to='Type',values_to="prop"),
       aes(x=year,y=prop,colour=Type))+
  geom_point() +
  geom_line() + 
  ylab("Proportion") +
  fig_theme +
  theme(legend.title=element_blank()) -> fig.prop.overall
save_plot(fig.prop.overall,"demo_nb_prop_overall.png")


# immigration -------------------------------------------------------------




# population growth -------------------------------------------------------
n_alive_female <- rowSums(extract_df('alive','female',age='all'))
n_alive_male <- rowSums(extract_df('alive','male',age='all'))
n_alive_both <- n_alive_female + n_alive_male

pop.growth.sex <- data.frame(year=1:length(n_alive_female)+baseline_year-1,
                             Male = n_alive_male,
                             Female = n_alive_female,
                             Both = n_alive_both)

prop.growth.sex <- pop.growth.sex %>% 
  mutate(Male=Male/pop.growth.sex$Male[1],
         Female=Female/pop.growth.sex$Female[1],
         Both=Both/pop.growth.sex$Both[1]) %>% 
  pivot_longer(cols=-year,names_to='sex',values_to="prop") %>% 
  mutate(type='Observed')

pop.baseline <- pop.canada %>% 
  filter(year==baseline_year)
pop.baseline$VALUE[1]

n_pop <- initial_newborns/(pop.baseline$VALUE[1]/sum(pop.baseline$VALUE))


pop.canada.sex <- pop %>%
  select(REF_DATE,GEO,Projection_scenario,Sex,Age_group,VALUE) %>% 
  mutate(Projection_scenario = str_remove(Projection_scenario,"Projection scenario "),
         Projection_scenario = str_remove(Projection_scenario, "\\:.*")) %>% 
  filter(GEO=='Canada' &Projection_scenario =='LG') %>% 
  select(-GEO,-Projection_scenario) %>% 
  rename(year=REF_DATE,
         age=Age_group,
         sex=Sex) %>% 
  filter(!str_detect(age,"to|All")) %>% 
  mutate(age=if_else(str_detect(age,"Under"),"0",age),
         age= if_else(str_detect(age,"over"),"100",age),
         age = str_remove(age," years| year"),
         age = as.numeric(age)) %>% 
  filter(year>=baseline_year) %>% 
  group_by(year,sex) %>% 
  summarise(n=sum(VALUE)) %>% 
  ungroup() %>% 
  mutate(sex=str_sub(sex,1,1),
         sex= case_when(sex=="F"~"Female",
                        sex=="M"~"Male",
                        T~'Both'))

unique.sex <- unique(pop.canada.sex$sex)
pop.baseline.n <- sapply(unique.sex,function(x){
  pop.canada.sex %>% 
    filter(year==baseline_year & sex==x) %>% 
    select(n) %>% 
    unlist()
})
names(pop.baseline.n) <- unique.sex
  

prop.canada.sex <- pop.canada.sex %>% 
  mutate(n=n/pop.baseline.n[match(sex,names(pop.baseline.n))],
         type="True")

prop.canada <- rbind(prop.growth.sex,prop.canada.sex %>% 
                       rename(prop=n))

ggplot(data=prop.canada,
       aes(x=year,y=prop,colour=sex,linetype=type))+
  geom_line(size=2) + 
  ylab("Relative size to the 2020 population") +
  fig_theme +
  xlab("Year")+
  xlim(baseline_year,max_year+baseline_year)+ 
  fig_setting +
  theme(legend.title=element_blank()) +
  guides(linetype = FALSE)-> fig.prop.growth
save_plot(fig.prop.growth,"demo_growth_prop.png")

# validation pop immigration distribution
pop_immigration_projection_2019 <- read_csv("src/processed_data/pop_immigration_projection_2019.csv")
pop_immigration_distribution_2018 <- read_csv("src/processed_data/pop_immigration_distribution_2018.csv")

df_n_growth <- rbind(prop.canada.sex %>% 
  filter(sex=="Both") %>% 
  mutate(n=n*n_pop) %>% 
  select(-sex), pop.growth.sex[,c(1,4)] %>% 
  rename(n=Both) %>% 
  mutate(type='Observed'))

ggplot(data=df_n_growth,
       aes(x=year,y=n,linetype=type))+
  geom_line(size=1) + 
  ylab("Number of population") +
  fig_theme +
  xlim(baseline_year,max_year+baseline_year)+
  theme(legend.title=element_blank()) -> fig.growth
save_plot(fig.growth,"demo_growth_n.png")

# population 'pyramid' ------------------------------------------------------
comparsion <- function(chosen_year=baseline_year){
  chosen_year_index <- chosen_year - baseline_year + 1
  est <- total_n[chosen_year_index,] 
  est[101] <- sum(est[101:length(est)])
  est <- est[1:101]
  true <- pop.canada %>% 
    filter(year==chosen_year)
  

  true$VALUE <- true$VALUE/sum(true$VALUE)
  est <- est/sum(est)
  true <- cbind(true,estimated=est)
  ggplot(data=true %>% 
           rename(True=VALUE,
                  Observed=estimated) %>% 
           pivot_longer(cols=-c(year:age),names_to='Type',values_to="prop"),
         aes(x=age,y=prop,linetype=Type))+
    geom_line() + 
    ggtitle(ifelse(chosen_year==2059,2060,chosen_year),)+
    xlab("")+
    ylab("") +
    fig_theme +
    theme(legend.title=element_blank()) +
    theme(plot.title = element_text(hjust = 0.5))
}

pop_years <- c(seq(baseline_year,2055,by=5),2059)
fig.pryamid <- do.call("ggarrange", c(lapply(pop_years,function(x){comparsion(x)}), 
                       nrow=3,ncol=3,common.legend=T,legend='none'))
library(grid)
fig.pryamid <- annotate_figure(fig.pryamid, left = textGrob("Proportion", rot = 90, vjust = 1,
                                                            gp=gpar(fontsize=25)),
                bottom = textGrob("Age (year)", gp = gpar(fontsize = 25)))
save_plot(fig.pryamid,'demo_pop_pyramid.png')


# death -------------------------------------------------------------------
life_table <- read_csv(here("src","processed_data","life_table.csv")) %>% 
  rename(Female=prob_death_female,
         Male=prob_death_male,
         Age = age) %>% 
  pivot_longer(cols=-Age,values_to='prop',names_to='sex') %>% 
  mutate(Type='True')

df_death <- data.frame(Age=1:max_age,
                       f_n=colSums(extract_df(type = 'death',sex='female',age='all')),
                       f_N = colSums(extract_df(type = 'alive',sex='female',age='all'))+
                              colSums(extract_df(type = 'death',sex='female',age='all')),
                       m_n=colSums(extract_df(type = 'death',sex='male',age='all')),
                       m_N = colSums(extract_df(type = 'alive',sex='male',age='all'))+
                         colSums(extract_df(type = 'death',sex='male',age='all'))) %>% 
  mutate(Female=f_n/f_N,
         Male=m_n/m_N,
         Age = Age-1) %>% 
  select(Age,Female,Male) %>% 
  pivot_longer(cols=-Age,values_to='prop',names_to='sex') %>% 
  mutate(Type='Observed')

ggplot(data=rbind(df_death,life_table) %>% 
         filter(Age<=100),
       aes(x=Age,y=prop,colour=sex,linetype=Type)) +
  geom_line(alpha=0.5)+
  ylab("Probability")+
  xlab('Age') +
  fig_theme +
  theme(legend.title=element_blank())-> fig.death

save_plot(fig.death,'demo_death.png')



# asthma incidence --------------------------------------------------------
df_asthma_inc <- data.frame(Year=1:max_year,
                            n=rowSums(extract_df(type = 'asthma_incidence',sex='both',age='all')),
                            N = rowSums(extract_df(type = 'alive',sex='both',age='all'))+
                              rowSums(extract_df(type = 'death',sex='both',age='all'))) %>% 
  mutate(rate=n/N*100000,
         prop=n/N*100)

ggplot(data=df_asthma_inc %>% 
         mutate(Year=Year+baseline_year)) +
  geom_line(aes(y=prop,x=as.numeric(Year)))+
  theme_classic() +
  fig_theme+
  ylab("Asthma incidence (%)")+
  geom_hline(yintercept = 8.7,col='red')+
  xlab('Year') -> fig.asthma.inc.prop

scaler <- round(max(1/(df_asthma_inc$rate/df_asthma_inc$n)))+5
ggplot(data=df_asthma_inc %>% 
         mutate(Year=Year+baseline_year)) +
  geom_line(aes(y=rate,x=as.numeric(Year),linetype='solid'))+
  geom_col(aes(y=n/scaler,x=as.numeric(Year),fill="#bdbdbd")) +
  scale_y_continuous(sec.axis=sec_axis(~(.)*scaler,name="Number of asthma incidence")) +
  theme_classic() +
  scale_linetype_identity(name=NULL,labels=c("Rate"),guide='legend')+
  scale_fill_identity(name=NULL,labels="Number",guide='legend')+
  fig_theme+
  ylab("Rate of asthma incidence per 100,000")+
  xlab('Year') -> fig.asthma.inc

save_plot(fig.asthma.inc,'asthma_inc.png')

# asthma prevalence -------------------------------------------------------
# df_asthma_prevalence <- data.frame(Year=1:max_year,
#                             n=rowSums(extract_df(type = 'asthma_prevalence',sex='both',age='all')),
#                             N = rowSums(extract_df(type = 'alive',sex='both',age='all'))+
#                               rowSums(extract_df(type = 'death',sex='both',age='all'))) %>% 
df_asthma_prevalence <- data.frame(Year=1:max_year,
                                     n=rowSums(extract_df(type = 'asthma_prevalence',sex='both',age='all')),
                                     N = rowSums(extract_df(type = 'alive',sex='both',age='all'))+
                                       rowSums(extract_df(type = 'death',sex='both',age='all'))) %>% 
  mutate(rate=n/N*100000,
         prop = n/N*100)

# df_asthma_prevalence <- data.frame(Year=1:max_year,
#                                    n=rowSums(extract_df(type = 'asthma_prevalence',sex='both',age=0:18)),
#                                    N = rowSums(extract_df(type = 'alive',sex='both',age=0:18))+
#                                      rowSums(extract_df(type = 'death',sex='both',age=0:18))) %>% 
#   mutate(rate=n/N*100000,
#          prop = n/N*100)

# ggplot(data=df_asthma_prevalence %>% 
#          mutate(Year=Year+baseline_year)) +
#   geom_line(aes(y=prop,x=as.numeric(Year)))+
#   theme_classic() +
#   fig_theme+
#   ylab("Asthma prevalence (%)")+
#   geom_hline(yintercept = 8.7,col='red')+
#   xlab('Year') -> fig.asthma.prev

scaler <- max(1/(df_asthma_prevalence$rate/df_asthma_prevalence$n)) + 0.01

ggplot(data=df_asthma_prevalence %>%
         mutate(Year=Year+baseline_year)) +
  geom_line(aes(y=rate,x=as.numeric(Year),linetype='solid'))+
  geom_col(aes(y=n/scaler,x=as.numeric(Year),fill="#bdbdbd")) +
  scale_y_continuous(sec.axis=sec_axis(~(.)*scaler,name="Number of asthma prevalence")) +
  theme_classic() +
  scale_linetype_identity(name=NULL,labels=c("Rate"),guide='legend')+
  scale_fill_identity(name=NULL,labels="Number",guide='legend')+
  fig_theme+
  ylab("Rate of asthma prevalence per 100,000")+
  fig_setting +
  geom_hline(yintercept =9500,linetype='dashed')+
  # ylim(0,10000) + 
  # geom_hline(yintercept = 8000,col='red')+
  xlab('Year') -> fig.asthma.prev

# ggplot(data=df_asthma_prevalence %>% 
#          mutate(Year=Year+baseline_year)) +
#   geom_line(aes(y=rate,x=as.numeric(Year)))+
#   geom_col(aes(y=n/scaler,x=as.numeric(Year),fill="#bdbdbd")) +
#   scale_y_continuous(sec.axis=sec_axis(~(.)*scaler,name="Number of asthma prevalence")) +
#   theme_classic() +
#   scale_linetype_identity(name=NULL,labels=c("Rate"),guide='legend')+
#   scale_fill_identity(name=NULL,labels="Number",guide='legend')+
#   fig_theme+
#   # ylab("Asthma prevalence per 100,000")+
#   # geom_hline(yintercept = 8000,col='red')+
#   xlab('Year') +
#   fig_setting +
#   geom_hline(yintercept =9500,linetype='dashed')+
#   ylim(0,10000)-> fig.asthma.prev  # geom_col(aes(y=n/scaler,x=as.numeric(Year),fill="#bdbdbd")) +

save_plot(fig.asthma.prev,'asthma_prev.png')

# antibiotic exposure ------------------------------------------------------
df_ABE <- data.frame(Year=1:max_year,
                                   n=rowSums(extract_df(type = 'antibiotic_exposure',sex='both',age='all')),
                                   N = rowSums(extract_df(type = 'alive',sex='both',age='all'))+
                       rowSums(extract_df(type = 'death',sex='both',age='all'))) %>% 
  mutate(rate=n/N*100000)
scaler <- round(max(1/(df_ABE$rate/df_ABE$n)))
ggplot(data=df_ABE %>% 
         mutate(Year=Year+baseline_year)) +
  geom_line(aes(y=rate,x=as.numeric(Year)))+
  # geom_col(aes(y=n/scaler,x=as.numeric(Year),fill="#bdbdbd")) +
  # scale_y_continuous(sec.axis=sec_axis(~(.)*scaler,name="Number of antibotics")) +
  theme_classic() +
  # scale_linetype_identity(name=NULL,labels=c("Rate"),guide='legend')+
  # scale_fill_identity(name=NULL,labels="Number",guide='legend')+
  ylab("Antibiotic prescriptions per 100,000")+
  ylim(0,40000) +
  geom_hline(yintercept = 32000,linetype='dashed')+
  xlab('Year') +
  fig_setting -> fig.ABE

save_plot(fig.ABE,'ABE.png')

# exacerbation ------------------------------------------------------------
df_exac <- data.frame(Year=1:max_year,
                     n=rowSums(extract_df(type = 'exacerbation',sex='both',age='all')),
                     # N = cumsum(rowSums(extract_df(type = 'asthma_incidence',sex='both',age='all')))) %>% 
                     N = rowSums(extract_df(type = 'asthma_prevalence',sex='both',age='all'))) %>%
  mutate(rate=n/N)

scaler <- round(max(1/(df_exac$rate/df_exac$n))) + 10

ggplot(data=df_exac %>% 
         mutate(Year=Year+baseline_year)) +
  geom_line(aes(y=rate,x=as.numeric(Year)))+
  # geom_col(aes(y=n/scaler,x=as.numeric(Year),fill="#bdbdbd")) +
  # scale_y_continuous(sec.axis=sec_axis(~(.)*scaler,name="Number of exacerbation")) +
  # theme_classic() +
  # scale_linetype_identity(name=NULL,labels=c("Rate"),guide='legend')+
  # scale_fill_identity(name=NULL,labels="Number",guide='legend')+
  fig_theme+
  geom_hline(yintercept = 0.357,linetype='dashed')+
  ylim(0,0.4)+
  ylab("Annual rate of exacerbation")+
  xlab('Year') +
  fig_setting-> fig.exac

save_plot(fig.exac,'asthma_exac.png')

# control -----------------------------------------------------------------
df_control <- data.frame(Year=1:max_year,
                      n1=rowSums(extract_df(type = 'control1',sex='both',age='all')),
                      n2=rowSums(extract_df(type = 'control2',sex='both',age='all')),
                      n3=rowSums(extract_df(type = 'control3',sex='both',age='all'))) %>% 
  mutate(N=n1+n2+n3,
         rate1=n1/N,
         rate2=n2/N,
         rate3=n3/N)

ggplot(data=df_control %>% 
         select(Year,rate1:rate3) %>% 
         mutate(Year = Year+baseline_year) %>% 
         pivot_longer(cols=-Year,names_to="Type",values_to='prop') %>% 
         mutate(Type = case_when(Type=='rate1' ~ 'controlled',
                                 Type=='rate2' ~ 'partially controlled',
                                 TRUE ~ 'uncontrolled')),
       aes(x=Year,y=prop,color=Type)) +
  geom_line()+
  fig_theme+
  theme(legend.title=element_blank())+
  ylim(0,1)+
  geom_hline(yintercept = 0.499,col='green',linetype='dashed')+
  geom_hline(yintercept = 0.329,col='red',linetype='dashed')+
  geom_hline(yintercept = 0.172,col='blue',linetype='dashed')+
  ylab("Proportion")+
  xlab('Year') +
  fig_setting +
  theme(legend.title=element_blank())-> fig.control

save_plot(fig.control,'asthma_control.png')

fig.prop.growth
# fig.pryamid
fig.asthma.inc
fig.asthma.prev
fig.ABE
fig.control
fig.exac