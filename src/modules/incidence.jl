# default incidence
# incidence_rate = CSV.read("../processed_data/incidence_rate.csv",DataFrame)
incidence_rate = filter(Row -> Row.year==2018,incidence_rate)
incidence_rate.age_max[incidence_rate.age_max .== Inf] .= 111
rep_num = convert.(Int,incidence_rate.age_max) .- incidence_rate.age_min .+ 1
# 1:10 female
# 11:20 male
incidence_prob_female = collect(Iterators.flatten(broadcast((x,y) -> fill(x,y),incidence_rate.prob[1:10],rep_num[1:10])))
incidence_prob_male = collect(Iterators.flatten(broadcast((x,y) -> fill(x,y),incidence_rate.prob[11:20],rep_num[11:20])))

struct Incidence <: Incidence_Module
    hyperparameters::Union{AbstractDict,Nothing}
    parameters::Union{AbstractDict,Nothing}
    initial_distribution
end

function incidence_process_simple(ag::Agent,parameters::Union{AbstractDict,Nothing}=nothing)::Bool
    if ag.sex == true # male
        return rand(Bernoulli(incidence_prob_male[ag.age+1])) # index starts at 1 for julia
    elseif ag.sex == false
        return rand(Bernoulli(incidence_prob_female[ag.age+1]))
    else
        error("$(ag.sex) is not supported.")
    end
end

function process(ag::Agent,inc::Incidence)
    rand(Bernoulli(incidence_logit_prob(ag.sex,ag.age,ag.cal_year,ag.num_antibiotic_use, inc.parameters)))
    # multiply by 0.55
    # tmp_index = Int(ag.sex)+1
    # rand(Bernoulli(inc.initial_distribution[tmp_index].prop[searchsortedfirst(cumsum(inc.initial_distribution[tmp_index].age_upper),ag.age)]))
    # 0
end

function process_initial(ag::Agent,inc::Incidence)
    tmp_index = Int(ag.sex)+1
    rand(Bernoulli(inc.initial_distribution[tmp_index].prop[searchsortedfirst(cumsum(inc.initial_distribution[tmp_index].age_upper),ag.age)]))
end

# function process_initial(ag::Agent,inc::Incidence,data;has_asthma::Bool=false)
#     if has_asthma
#         if ag.age==0
#             return false
#         else
#             return StatsBase.sample(Weights(dat[ag.age][ag.sex+1,:]))-1
#         end
#     else
#         return Bool(rand(Bernoulli(dat[ag.sex+1,ag.age+1])))
#     end
# end

# function process_initial(ag::Agent,inc::Incidence,dat;has_asthma::Bool=false)
#     if has_asthma
#         if ag.age==0
#             return 0
#         else
#             return StatsBase.sample(Weights(dat[ag.age][ag.sex+1,:]))-1
#         end
#     else
#         return 0
#     end
# end

# asthma_initial_distribution[1][5,:age_upper]
# @show asthma_initial_distribution
# rand(Bernoulli(rand(Beta(1,1))))
# asthma_initial_distribution[1][(searchsortedfirst(cumsum(inc.initial_distribution[!,:age]/100),20),:alpha]
# searchsortedfirst(cumsum(asthma_initial_distribution[1][:,:age_upper]),20)
# vec(asthma_initial_distribution[1][2,[:age_lower,:age_upper]])

function incidence_logit_prob(sex::Bool,age::Int64,cal_year::Int64,CABE::Int64,parameters::AbstractDict)
    # age = min(age,70)
    StatsFuns.logistic( parameters[:β0] +
     parameters[:βsex] * sex +
     parameters[:βage] * age +
     parameters[:βage2] * age^2 +
     parameters[:βage3] * age^3 +
     parameters[:βage4] * age^4 +
     parameters[:βage5] * age^5 +
     parameters[:βageM] * age * sex+
     parameters[:βage2M] * age^2 * sex +
     parameters[:βage3M] * age^3 *sex  +
     parameters[:βage4M] * age^4 * sex +
     parameters[:βage5M] * age^5  * sex+
     parameters[:βcal_year] * cal_year +
     parameters[:βcal_yearM] * cal_year * sex +
     parameters[:βCABE] * CABE * (age < 18) +
     parameters[:β0_correction] * (age < 18) +
     parameters[:β0_overall_correction])
     # with 0
end


function random_parameter_initialization!(inc::Incidence)
    inc.parameters[:β0] = rand(Normal(inc.hyperparameters[:β0_μ], inc.hyperparameters[:β0_σ]))
end

# use symbols for dic keys to represent them as variables
# hyperparameters_names = [:β0_μ,:β0_σ]
# parameter_names = [:β0,:βage,:βage2,:βage3,:βage4,:βage5,:βsex,:βcal_year,:βCABE,:βageM,:βage2M,:βage3M,:βage4M,:βage5M,:βcal_yearM]
#
#
# incidence = Incidence(Dict_initializer(hyperparameters_names), Dict_initializer(parameter_names))
