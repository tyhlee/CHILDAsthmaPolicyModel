# include("abstractModule.jl")
# include("../utils")

struct AntibioticExposure <: AntibioticExposure_Module
    hyperparameters::AbstractDict
    parameters::AbstractDict
end

function process(ag::Agent,anti::AntibioticExposure)
    rand(Bernoulli( antibioticExposure_logit_prob(ag.sex,ag.age,ag.cal_year,anti.parameters) ))
    # rand(Bernoulli(0.1))
end

function process_initial(ag::Agent,anti::AntibioticExposure,dat)
    # return rand(Poisson(dat[ag.sex+1,ag.age+1]))
    rand(PoissonBinomial(dat[1:(ag.age+1),Int(ag.sex)+1,ag.cal_year]))
end

# helper function for above
function antibioticExposure_logit_prob(sex::Bool,age::Int,cal_year::Int,parameters::AbstractDict)
    StatsFuns.logistic( parameters[:β0] +
     parameters[:βsex] * sex +
     parameters[:βage] * age +
     parameters[:βcal_year] * cal_year)
end

function random_parameter_initialization!(anti::AntibioticExposure)
    anti.parameters[:β0] = rand(Normal(anti.hyperparameters[:β0_μ], anti.hyperparameters[:β0_σ]))
end


# hyperparameters_names = [:β0_μ,:β0_σ]
#
# parameter_names = [:β0,:βage,:βsex,:βcal_year]
#
# antibioticExposure = AntibioticExposure(Dict_initializer(hyperparameters_names),Dict_initializer(parameter_names))
