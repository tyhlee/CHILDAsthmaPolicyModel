# include("abstractModule.jl")
# include("../utils.jl")

# estimated num of newborn + proprotion of male
# birth_project = CSV.read("../processed_data/brith_projection.csv",DataFrame)

struct Immigration <: Immigration_Module
    sex_ratio
    age_distribution
    overall_rate
end

function process(cal_year_index,b::Immigration)
    sex = rand(Bernoulli(b.sex_ratio))
    age = searchsortedfirst(cumsum(b.age_distribution[!,:percentage]/100),rand())-1
    # TODO
    Agent(sex,age,cal_year_index,true,0,false,nothing,nothing,nothing,[0,0])
end

# ag.sex = sex
# ag.age= age
# ag.cal_year = cal_year
# ag.alive = alive
# ag.num_antibiotic_use=num_antibiotic_use
# ag.has_asthma = has_asthma
# ag.asthma_age = asthma_age
# ag.severity = asthma_severity
# ag.control = asthma_control
# ag.exac_hist = asthma_exac_hist
