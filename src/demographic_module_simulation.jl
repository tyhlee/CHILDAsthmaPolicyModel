using Revise
using JLD
using JLD2
using Asthma_Julia
using Setfield
using ShiftedArrays

simulation = set_up()

@set! simulation.time_horizon = 150;
@set! simulation.n = 1000;
@set! simulation.antibioticExposure.parameters[:βcal_year] = 0;
@set! simulation.incidence.parameters[:βcal_year] = 0;
@set! simulation.incidence.parameters[:βcal_yearM] = 0;
@set! simulation.death.parameters[:β1] =0;
look2 = Asthma_Julia.process_simulator(simulation,false)
look = copy(look2)
save("src/simulation_output/simple_demo_output_1000_150_Nov21.jld","output",look)

min_index = 110
max_index = 150

yr= 150
look["asthma_prevalence"][:,:,yr]
tmp = look["alive"] .+ look["death"]
tmp[:,:,yr]
look["asthma_prevalence"][:,:,yr] ./ tmp[:,:,yr]
sum(look["asthma_prevalence"],dims=3) ./ (sum(look["alive"],dims=3) .+ sum(look["death"],dims=3))
sum(look["asthma_prevalence"]) ./ (sum(look["alive"]) .+ sum(look["death"]))


(63165+121952+156233)/2285253

look["antibiotic_exposure"] ./ tmp
look["antibiotic_exposure"] ./ tmp

save("src/simulation_output/simple_demo_output_1000_150_Nov21.jld","output",look)

demo_data = load("src/simulation_output/simple_demo_output_500000.jld")["output"]

init_data = Dict{Any,Any}()

alive = copy(demo_data["alive"])

alive[1,:] = circshift(alive[1,:],(1))
alive[2,:] = circshift(alive[2,:],(1))
alive[:,1] = sum(demo_data["n"],dims=1)
alive[:,112] = [1,1]

# sanity check
(alive[1,:] - lead(alive[1,:]))[1:5] == demo_data["death"][1,1:5]
tmp_alive = copy(alive)
tmp_alive[1,:] = tmp_alive[1,:] .+ circshift(alive[1,:],(1))
tmp_alive[2,:] = tmp_alive[2,:] .+ circshift(alive[2,:],(1))

prev = copy(demo_data["asthma_prevalence"])
prev[1,:] = prev[1,:] .- circshift(prev[1,:],(1))
prev[2,:] = prev[2,:] .- circshift(prev[2,:],(1))
prev = prev .+ demo_data["asthma_incidence"]

inc = demo_data["asthma_incidence"]
init_data["has_asthma"] = prev ./ alive

init_data["has_asthma"] = demo_data["asthma_prevalence"] ./ tmp_alive
init_data["has_asthma"] = demo_data["asthma_incidence"] ./ tmp_alive

init_data["has_asthma"] = demo_data["asthma_prevalence"] ./ cumsum(alive,dims=2)

@show demo_data["antibiotic_exposure"]
init_data["antibiotic_exposure"] = demo_data["antibiotic_exposure"] ./ (alive .- demo_data["asthma_incidence"])

init_data["control"] = demo_data["control"] ./ sum(demo_data["control"],dims=3)

init_data["exacerbation"] = demo_data["exacerbation"] ./ demo_data["asthma_prevalence"]

function asthma_age(age)
    demo_data["asthma_incidence"][:,1:(age+1)] ./ demo_data["asthma_prevalence"][:,age+1]
end

tmp_result = Dict{Any,Any}()
for i in 0:110
    tmp_result[i+1] = asthma_age(i+1)
end

init_data["asthma_age"] = tmp_result

save("src/processed_data/init_data_Nov21.jld","output",init_data)

# init_data = JLD2.load("src/processed_data/init_data.jld2")["output"]
# #
JLD2.save("src/processed_data/init_data_Nov21.jld2","output",init_data)
