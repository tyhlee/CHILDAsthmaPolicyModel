# include("abstractModule.jl")
# include("../utils.jl")

# estimated num of newborn + proprotion of male
# birth_project = CSV.read("../processed_data/brith_projection.csv",DataFrame)

struct Emigration <: Emigration_Module
    projected_rate
    age_distribution
end

function process(ag_age::Int,b::Emigration)
    rand(Bernoulli(b.projected_rate*b.age_distribution.percentage[searchsortedfirst(b.age_distribution.age_upper,ag_age)]))
end
