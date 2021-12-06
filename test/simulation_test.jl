using Revise
using JLD, JLD2
using Setfield
using Asthma_Julia

simulation = set_up()
# @set! simulation.antibioticExposure.parameters[:βage] = -0.0;
# @set! simulation.antibioticExposure.parameters[:βsex] = 0.0;
# @set! simulation.antibioticExposure.parameters[:βcal_year] = -0.01;
@set! simulation.time_horizon = 40;
@set! simulation.n = 500;
look = Asthma_Julia.process(simulation)

JLD2.save("src/simulation_output/V1_run_Nov23_ABE_calendar.jld","output",look)

# pop calibration
@set! simulation.immigration.overall_rate = Asthma_Julia.overall_rate_calculator(0.75,immigration_projection_table,immigration_rate_per_birth,simulation.population_growth_type,simulation.starting_calendar_year)
look2 = Asthma_Julia.process(simulation)
JLD2.save("src/simulation_output/V1_run_Nov12_calibrated_0.75.jld","output",look2)


parameters = simulation.incidence.parameters
@set! parameters[:β0] =0.1
max_age=110
Asthma_Julia.asthma_age_weights_generator(3,parameters)
tmp_result = Dict{Any,Any}()
for i in 1:max_age
    tmp_result[i] =[map((x) -> Asthma_Julia.incidence_logit_prob(false,x,0,0,parameters),0:i),map((x) -> Asthma_Julia.incidence_logit_prob(true,x,0,0,parameters),0:i)]
end
tmp_result


# check death rate
lt = Asthma_Julia.life_table
dr = (lt.prob_death_male .+ lt.prob_death_female)/2
tot = ceil(Int,1000 / sum(filter(:age=> ==(0),simulation.birth.initial_population).prop))
look = process_initial_population(simulation.birth,tot)
tmp_sex=simulation.birth.initial_population.sex[look]
tmp_age = simulation.birth.initial_population.age[look]
using StatsBase
countmap(tmp_age)
num = collect(values((sort(countmap(tmp_age), by = last, rev=false))))
look
sum(num/sum(num) .* dr[1:101])
freqtable

look = Asthma_Julia.process_simulator(simulation)
@set! simulation.time_horizon = 40;
@set! simulation.n = 5e5;

control
@show look[2]["alive"][1][1,:]
look[2]["death"][1]
sum(look.n)/1000*2.9
sum.(look[2]["emigration"])

sum(look[2]["alive"])[1,:]

@show tmp.n
@show tmp.outcome_matrix

using BenchmarkTools

mutable struct mut_Agent  <: Agent_Module
    sex::Bool # true: male
    age::Int
    cal_year::Int
    alive::Bool # true: alive
    num_antibiotic_use::Int
    has_asthma::Bool # true: has asthma
    asthma_age::Union{Nothing,Int} # asthma dx age
    severity::Union{Nothing,Int} # asthma severity level: 1 (mild), 2 (severe)
    control::Union{Nothing,Vector{Float64}} # asthma control level: 1 (controlled), 2 (partially controlled), 3 (fully controlled)
    exac_hist::Union{Nothing,Vector{Int}}
end

test_agent = mut_Agent(false,0,2015,true,0,false,0,0,nothing,[0,0])

function test1(agent)
    for i in 1:50
        @set! agent.has_asthma = process(simulation.agent,simulation.incidence)
    end
end

function test2(agent)
    for i in 1:50
        agent.has_asthma = process(agent,simulation.incidence)
    end
end

function process(ag::mut_Agent,inc::Incidence)
    rand(Bernoulli( incidence_logit_prob(ag.sex,ag.age,ag.cal_year,ag.num_antibiotic_use, inc.parameters)))
end

@benchmark test1(agent)
@benchmark test2(test_agent)
@btime test1(agent)
@btime test2(test_agent)

@time test1(agent)
@time GC.gc()
@time test2(test_agent)
@time GC.gc()

#["antibiotic_exposure", "asthma_incidence", "asthma_prevalence", "death"]
# results["antibiotic_exposure"][1]

# check n

# check calenda

# # check prop of males
# # should be about 0.5122
# death_year_female = sum(results[:,:,1,4],dims=1)
# death_year_male = sum(results[:,:,2,4],dims=1)
# n_male = sum(death_year_male)
# n_female = sum(death_year_female)
# sum(n_male) / sum(n_male + n_female)


# # check incidence
# x = 1:size(results)[2]
# re_incidence_female = vec(sum(results[:,:,1,2],dims=1))
# re_incidence_male = vec(sum(results[:,:,2,2],dims=1))
# df_incidence_rate = convert(Matrix,Asthma_Julia.incidence_rate)
# true_incidence_female = df_incidence_rate[1:10,5]
# true_incidence_male = df_incidence_rate[11:20,5]
# plot(x,vec(re_incidence_female/n_female), label="female incidence",legend=:topright)
# plot!(df_incidence_rate[1:10,6],true_incidence_female,label="2017 data")

# plot(x,vec(re_incidence_male/n_male), label="male incidence",legend=:topright)
# plot!(df_incidence_rate[1:10,6],true_incidence_male,label="2017 data")

# # exposure
# xx = 1:20
# ABE_female = vec(sum(results[:,1:20,1,1],dims=1))
# ABE_male = vec(sum(results[:,1:20,2,1],dims=1))
# plot(xx,ABE_female/n_female, label="female ABE",legend=:topright)
# plot!(xx,ABE_male/n_male,label="male ABE")
# cumsum(ABE_female/n_female)[1:4]

# # check death
# life_table = convert(Matrix,Asthma_Julia.life_table)

# prop_male = 0.5122

# total_n = sim.n * (sim.time_horizon+1)
# n_male = prop_male * total_n
# n_female = (1-prop_male) * total_n

# death_generator = function(n::Real,prob_death::AbstractVector)
#     death = similar(prob_death)
#     alive = similar(prob_death)
#     alive[1] = n
#     death[1] = n*prob_death[1]
#     for i in 2:length(prob_death)
#         alive[i] = alive[i-1] - death[i-1]
#         death[i] = alive[i] * prob_death[i]
#     end
#     return death
# end

# true_death_female = death_generator(n_female,life_table[:,2])
# true_death_male = death_generator(n_male,life_table[:,3])

# plot(x,vec(death_year_female), label="female death",legend=:topleft)
# plot!(x,true_death_male,label="female true death")

# plot(x,vec(death_year_male), label="male death",legend=:topleft)
# plot!(x,true_death_female,label="male true death")

# struct test_mut
#     sex::Bool # true: male
#     age::Int
#     yay::Vector{Int}
# end
#
# meow = test_mut(false,10,[1;2;3])
#
# @set! meow.sex = 1
# meow = setproperties(meow,(sex=false,age=99,yay=[0;0]))
# @set! meow.yay[1] = 25
# @show meow
# meow = setproperties(meow,(sex=false,age=1))
#
# function test_my_mut(meow::test_mut)
#     meow = setproperties(meow,(sex=true,age=100,yay=[0]))
# end
#
# @show meow
# @show test_my_mut(meow)
