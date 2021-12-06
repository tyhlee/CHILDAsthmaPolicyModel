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

# you can check whether this object exists in "Julia"
julia_exists('simulation')

# you can re-set any of the fields in the struct using @set!
# this is the pkg allowing us to change the struct fields easily
julia_command("using Setfield")
julia_command("@set! simulation.n = 5000;")
julia_command("@set! simulation.time_horizon = 46;")

julia_command("results = Asthma_Julia.process_demographic(simulation)")

results <- julia_eval("results")

total_n <- sum(results[[2]]$alive)

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
  filter(year>=2020)

comparsion <- function(chosen_year=2020){
  chosen_year_index <- chosen_year - 2020 + 1
  est <- total_n[chosen_year_index,] 
  est[101] <- sum(est[101:length(est)])
  est <- est[1:101]
  true <- pop.canada %>% 
    filter(year==chosen_year)
  
  true$VALUE <- true$VALUE/sum(true$VALUE)
  est <- est/sum(est)
  with(true,plot(true$age,est,type='l',col='red',main=paste0(chosen_year),xlab='age (year)',ylab='proportion'))
  lines(true$age,true$VALUE,col='black')
}

par(mfrow=c(2,3))

comparsion(2020)
comparsion(2030)
comparsion(2040)
comparsion(2050)
comparsion(2060)
comparsion(2065)

# TODO: process and visualize control data