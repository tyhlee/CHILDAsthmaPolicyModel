# include("abstractModule.jl")
# include("utils")

# prob of death by age and sex
# life_table = CSV.read("../processed_data/life_table.csv",DataFrame);

struct Death <: Death_Module
    parameters
end

function process(ag::Agent,d::Death)
    # rand(Bernoulli(death_prob))
    p = life_table[ag.age+1,3-ag.sex]
    if p==1
        return true
    end
    or = p/(1-p)*exp(d.parameters[:β0]+d.parameters[:β1]*ag.cal_year+d.parameters[:β2]*ag.age)
    p = max(min(or/(1+or),1),0)
    return(rand(Bernoulli(p)))
end
