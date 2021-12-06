# include("abstractModule.jl")
# include("../utils.jl")

# estimated num of newborn + proprotion of male
# birth_project = CSV.read("../processed_data/brith_projection.csv",DataFrame)

struct Birth <: Birth_Module
    trajectory
    initial_population
end


function process(cal_year_index::Int,b::Birth)
    # sex = (isnothing(sex) ? rand(Bernoulli((b.trajectory.prop_male[cal_year_index]))) : sex)
    # if age == 0
    #     return Agent(sex,age,cal_year_index,true,0,false,nothing,nothing,nothing,[0,0])
    # else
    #     # ABT exposure
    #     # asthma incidence
    #         # asthma control
    #         # asthma exacerbation
    #         # asthma severity
    #         #asthma exac history
    #     return Agent(sex,age,cal_year_index,true,0,false,nothing,nothing,nothing,[0,0])
    # end
    # prop_male = b.trajectory.prop_male[cal_year_index] ; assume fixed
    return Agent(rand(Bernoulli(0.512)),0,cal_year_index,true,0,false,nothing,nothing,nothing,[0,0])
end


function process(cal_year_index::Int,b::Birth,sex,age)
    # sex = (isnothing(sex) ? rand(Bernoulli((b.trajectory.prop_male[cal_year_index]))) : sex)
    # if age == 0
    #     return Agent(sex,age,cal_year_index,true,0,false,nothing,nothing,nothing,[0,0])
    # else
    #     # ABT exposure
    #     # asthma incidence
    #         # asthma control
    #         # asthma exacerbation
    #         # asthma severity
    #         #asthma exac history
    #     return Agent(sex,age,cal_year_index,true,0,false,nothing,nothing,nothing,[0,0])
    # end
    return Agent(sex,age,cal_year_index,true,0,false,nothing,nothing,nothing,[0,0])
end



function process_initial_population(b::Birth,n::Int)
    wsample(1:(nrow(b.initial_population)),b.initial_population.prop,n,replace=true)
end

function process!(ag::Agent,cal_year_index::Int,b::Birth)
    @set! ag.sex = rand(Bernoulli(b.trajectory.prop_male[cal_year_index]))
    @set! ag.cal_year = cal_year_index
    ag
end
# use symbols for dic keys to represent them as variables
# birth = Birth(nothing)

# @set! birth.trajectory = choose_bp(birth_projection,simulation.population_growth_type,2015)
# process!(agent,2020-2015,birth)
# @show agent.sex



# birth = Birth(Dict(parameter_names .=> ),birth_process)

# module Birth_Module
#
#         function initiate(cal_year_index)
#                 tmp_prop_male = birth_project.prop_male[cal_year_index]
#                 set_agent!(rand(Bernoulli(tmp_prop_male)),0,cal_year,cal_year,true,0,false,0,0,[0,0])
#         end
#
# end
#
# function process(age::Agent,birth::Birth_Module_Type,)
#
#         set!(ag)
# end


# function Birth(ag::Agent,cal_year_index::Int64;option="default")
#         if option=="default"
#
#         end
#         function initiate(cal_year_index)
#                 tmp_prop_male = birth_project.prop_male[cal_year_index]
#                 set_agent!(ag,rand(Bernoulli(tmp_prop_male)),0,cal_year,cal_year,true,0,false,0,0,[0,0])
#         end
#
#         process() = println("hello")
#
#         return SimulationModel(initiate,process)
# end

# include("module.jl")

# mutable struct birth_module <: Birth_Module
#
# end
#
# Birth = birth_module(agent::Agent)
#
# birth =
