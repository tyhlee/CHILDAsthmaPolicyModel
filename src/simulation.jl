# using DataFrames, CSV
# using Setfield, Distributions, StatsFuns
# using TimerOutputs
# using Plots

# TODO: fix the directory
# cd("/home/dlxodbs100/Dropbox/Asthma_Julia/src/")

#TODO: remove reptitions & turn this whole frame work into actual Modules
# order is important !
include("global_variables.jl")
include("modules/abstractModule.jl")
include("utils.jl")

include("modules/agent.jl")
include("modules/birth.jl")
include("modules/emigration.jl")
include("modules/immigration.jl")
include("modules/death.jl")
include("modules/antibioticExposure.jl")
include("modules/incidence.jl")
include("modules/control.jl")
include("modules/exacerbation.jl")

# subtypetree(Simulation_Module)

mutable struct Simulation <: Simulation_Module
    max_age::Int
    starting_calendar_year::Int
    time_horizon::Union{Missing,Int,Vector{Int}}
    n::Union{Nothing,Int}
    population_growth_type::Union{Missing,String}
    agent::Agent_Module
    birth::Birth_Module
    emigration::Emigration_Module
    immigration::Immigration_Module
    death::Death_Module
    antibioticExposure::AntibioticExposure_Module
    incidence::Incidence_Module
    control::Control_Module
    exacerbation::Exacerbation_Module
    initial_distribution
    outcomeMatrix
end


# set_agent!(simulation.Agent,simulation.Birth.process(1),0,2020,2025,true,0,false,0,0,[1,0])
# set_agent!(simulation.Agent,true,0,2019,2025,true,0,false,0,0,[0,0])

function process(simulation::Simulation,until_all_die=false)
    # TODO: write a function to check all the parameters are initialized; returns warning in such a case

    max_age = simulation.max_age
    min_cal_year = simulation.starting_calendar_year
    max_cal_year = min_cal_year + simulation.time_horizon - 1

    # if n is not provided, use a default value, 100
    simulation.n = (ismissing(simulation.n) ? 100 : simulation.n)

    # if simulation.population_growth_type is not provided, use the low growth "LG"
    simulation.population_growth_type = (ismissing(simulation.population_growth_type) ? "LG" : simulation.population_growth_type)

    # birth projection
    @set! simulation.birth.trajectory = choose_bp(birth_projection,simulation.population_growth_type,min_cal_year)
    max_time_horizon = (until_all_die ? typemax(Int) : simulation.time_horizon)

    # initiate some variables to collect results
    cal_years = min_cal_year:max_cal_year

    # store the event matrix following this order
    n_list = zeros(Int,simulation.time_horizon,2)
    event_list= ["antibiotic_exposure", "asthma_incidence", "asthma_prevalence", "death","alive","control1","control2","control3","exacerbation","emigration","immigration"]
    # TODO: change this into a dict
    # event_matrix = Dict{Any,Any}() # calendar year by age by num of events
    # event_matrix["antibiotic_exposure"] = zeros(Int,2,max_age+1)
    # event_matrix["asthma_incidence"] = zeros(Int,2,max_age+1)
    # event_matrix["asthma_prevalence"] = zeros(Int,2,max_age+1)
    # event_matrix["death"] = zeros(Int,2,max_age+1)
    # event_matrix["alive"] = zeros(Int,2,max_age+1)
    # event_matrix["control"] = zeros(Int,2,max_age+1,3)
    # event_matrix["exacerbation"] = zeros(Int,2,max_age+1)
    event_matrix = zeros(Int,length(cal_years)+(until_all_die ? max_age : 0),max_age+1,2,length(event_list)) # calendar year by age by num of events

    # asthma age data for initialization
    @set! simulation.incidence.parameters[:β0] = simulation.incidence.hyperparameters[:β0_μ]
    asthma_age_data = asthma_age_weights_generator(max_age,simulation.incidence.parameters)

    @set! simulation.antibioticExposure.parameters[:β0] = simulation.antibioticExposure.hyperparameters[:β0_μ]
    ABE_prob_data = ABE_probs_generator(max_age, simulation.antibioticExposure.parameters,simulation.time_horizon+1)

    # time the performance
    to = TimerOutput()

    # baby agent
    # baby_agent = Agent(false,0,2015,true,0,false,0,0,nothing,[0,0])

    number_ABE = 0

    @timeit to "sleep" sleep(0.02)
    for cal_year in cal_years
        # for each calendar year
        @timeit to "calendar year $cal_year" begin

        tmp_cal_year_index = cal_year - min_cal_year + 1
        num_new_born = ceil(Int, simulation.n*simulation.birth.trajectory.relative_change[tmp_cal_year_index])
        num_immigrants = ceil(Int, num_new_born * simulation.immigration.overall_rate[tmp_cal_year_index])
        # the total number of agents simulated in the cal year
        # for the first/initial year, we generate the initial population
        n_cal_year = (cal_year==min_cal_year ? ceil(Int,num_new_born / sum(filter(:age=> ==(0),simulation.birth.initial_population).prop)) : num_new_born + num_immigrants)
        initial_pop_index = Int[]

        if cal_year == min_cal_year
            initial_pop_index = process_initial_population(simulation.birth,n_cal_year)
        end
        tmp_index = 1

        for i in 1:n_cal_year

            # simulate an agent

            # generate agent-specific random effects
            random_parameter_initialization!(simulation.antibioticExposure)
            random_parameter_initialization!(simulation.incidence)
            random_parameter_initialization!(simulation.control)
            random_parameter_initialization!(simulation.exacerbation)

            # simulation.agent = process!(baby_agent,tmp_cal_year_index,simulation.birth)
            if cal_year == min_cal_year
                tmp_index = initial_pop_index[i]
                simulation.agent = process(tmp_cal_year_index,simulation.birth,simulation.birth.initial_population.sex[tmp_index],simulation.birth.initial_population.age[tmp_index])
            else
                if rand(Bernoulli(num_new_born/n_cal_year))
                    # new born
                    simulation.agent = process(tmp_cal_year_index,simulation.birth)
                else
                    # immigrant
                    simulation.agent = process(tmp_cal_year_index,simulation.immigration)
                    event_matrix[simulation.agent.cal_year,simulation.agent.age+1,simulation.agent.sex+1,11] += 1
                end
            end

            # immigrants and Canadians are assumed to have the same distributions over the following factors
            # really need a joint distribution
            if simulation.agent.age != 0
                @set! simulation.agent.num_antibiotic_use = process_initial(simulation.agent,simulation.antibioticExposure,ABE_prob_data)
                # @set! simulation.agent.has_asthma = process_initial(simulation.agent,simulation.incidence,simulation.initial_distribution["has_asthma"])
                @set! simulation.agent.has_asthma = process_initial(simulation.agent,simulation.incidence)
                if simulation.agent.has_asthma == 1
                    # assumption
                    # event_matrix[simulation.agent.cal_year,simulation.agent.age+1,simulation.agent.sex+1,2] += 1
                    # @set! simulation.agent.asthma_age = process_initial(simulation.agent,simulation.incidence,simulation.initial_distribution["asthma_age"],has_asthma=true)
                    @set! simulation.agent.asthma_age = process_initial(simulation.agent,asthma_age_data)
                    # @set! simulation.agent.control = process_initial(simulation.agent,simulation.control,simulation.initial_distribution["control"])
                    @set! simulation.agent.control = process(simulation.agent,simulation.control)
                    # @set! simulation.agent.exac_hist = process_initial(simulation.agent,simulation.exacerbation,simulation.initial_distribution["exacerbation"])
                    @set! simulation.agent.exac_hist = process_initial(simulation.agent,simulation.exacerbation)
                end
            end

            # TODO: update outcome matrix
            n_list[tmp_cal_year_index,simulation.agent.sex+1] +=1

            # go through event processes for each agent
            while(simulation.agent.alive && simulation.agent.age <= max_age && simulation.agent.cal_year <= max_time_horizon)

                # run asthma incidence if agent does not have asthma
                if !simulation.agent.has_asthma # no asthma case
                    # antibotic expsoure first since this is assumed to affect asthma incidence only
                    number_ABE = process(simulation.agent,simulation.antibioticExposure)
                    # update the event matrix for antibiotic exposure
                    event_matrix[simulation.agent.cal_year,simulation.agent.age+1,simulation.agent.sex+1,1] += number_ABE
                    # simulation.Agent.num_antibiotic_use = simulation.AntibioticExposure.process(simulation.Agent,simulation.AntibioticExposure.parameters)
                    if tmp_cal_year_index==1
                        @set! simulation.agent.has_asthma = process(simulation.agent,simulation.incidence)
                    else
                        @set! simulation.agent.has_asthma = process(simulation.agent,simulation.incidence)
                    end

                    if simulation.agent.has_asthma
                        # record the asthma dx year
                        @set! simulation.agent.asthma_age = copy(simulation.agent.age)
                        # update asthma incidence event matrix
                        event_matrix[simulation.agent.cal_year,simulation.agent.age+1,simulation.agent.sex+1,2] += 1
                        # update asthma prevalaence event matrix
                        event_matrix[simulation.agent.cal_year,simulation.agent.age+1,simulation.agent.sex+1,3] += 1

                        # # TODO: initialize asthma asthma control
                        @set! simulation.agent.control = process(simulation.agent,simulation.control)

                        # asthma exacerbation
                        # patient-specific variable for asthma exac
                        @set! simulation.agent.exac_hist[1] = process(simulation.agent,simulation.exacerbation)

                        # store control & exacerbation
                        event_matrix[simulation.agent.cal_year,simulation.agent.age+1,simulation.agent.sex+1,5+findmax(simulation.agent.control)[2]] += 1
                        event_matrix[simulation.agent.cal_year,simulation.agent.age+1,simulation.agent.sex+1,9] += simulation.agent.exac_hist[1]
                    end
                else
                    # has asthma, so update asthma prevalence event matrix
                    event_matrix[simulation.agent.cal_year,simulation.agent.age+1,simulation.agent.sex+1,3] += 1

                    #  update control
                    @set! simulation.agent.control = process(simulation.agent,simulation.control)

                    # update exacerbation
                    @set! simulation.agent.exac_hist[2] = copy(simulation.agent.exac_hist[1])
                    @set! simulation.agent.exac_hist[1] = process(simulation.agent,simulation.exacerbation)

                    # store control and exacerbation
                    event_matrix[simulation.agent.cal_year,simulation.agent.age+1,simulation.agent.sex+1,5+findmax(simulation.agent.control)[2]] += 1
                    event_matrix[simulation.agent.cal_year,simulation.agent.age+1,simulation.agent.sex+1,9] += simulation.agent.exac_hist[1]
                end

                # death - the last process
                if process(simulation.agent,simulation.death)
                    @set! simulation.agent.alive = false
                    # everyone dies in the end... Inevitable
                    event_matrix[simulation.agent.cal_year,simulation.agent.age+1,simulation.agent.sex+1,4] += 1
                # emigration
                elseif process(simulation.agent.age,simulation.emigration)
                    @set! simulation.agent.alive = false
                    event_matrix[simulation.agent.cal_year,simulation.agent.age+1,simulation.agent.sex+1,10] += 1
                else
                    # record whether alive or not
                    event_matrix[simulation.agent.cal_year,simulation.agent.age+1,simulation.agent.sex+1,5] += 1
                    # update the patient stats
                    @set! simulation.agent.age += 1
                    @set! simulation.agent.num_antibiotic_use += number_ABE
                    @set! simulation.agent.cal_year += 1
                end

            end # end while loop
        end # end for loop: agents
        # println(cal_year)
        end # end of begin timeit
    end # end for loop: cal year

    print_timer(to::TimerOutput)

    tmp_event_dict = Dict()
    for jj in 1:length(event_list)
        tmp_event_dict[event_list[jj]] = [event_matrix[:,:,1,jj],event_matrix[:,:,2,jj]]
    end

    # reshape event matrix into a dictionry of list of matrices
    @set! simulation.outcomeMatrix = (; n = n_list, outcome_matrix = tmp_event_dict)

    print("\n Simulation finished. Check your simulation object for results.")
    return simulation.outcomeMatrix;
end

function process_simulator(simulation::Simulation,until_all_die=true)
    # TODO: write a function to check all the parameters are initialized; returns warning in such a case

    ### extract variables from simulation that will be used more than once
    max_age = simulation.max_age
    min_cal_year = simulation.starting_calendar_year
    max_cal_year = min_cal_year + simulation.time_horizon - 1
    # if n is not provided, use a default value, 100
    simulation.n = (ismissing(simulation.n) ? 100 : simulation.n)

    # if simulation.population_growth_type is not supported, use the low growth "LG"
    simulation.population_growth_type = (ismissing(simulation.population_growth_type) ? "LG" : simulation.population_growth_type)
    # birth projection
    @set! simulation.birth.trajectory = choose_bp(birth_projection,simulation.population_growth_type,min_cal_year)
    max_time_horizon = (until_all_die ? typemax(Int) : simulation.time_horizon)

    # initiate some variables to collect results
    cal_years = min_cal_year:max_cal_year

    # store the event matrix following this order
    n_list = zeros(Int,simulation.time_horizon,2)
    event_list= ["antibiotic_exposure", "asthma_incidence", "asthma_prevalence", "death","alive","control1","control2","control3","exacerbation"]
    # TODO: change this into a dict
    event_matrix = Dict{Any,Any}() # calendar year by age by num of events
    event_matrix["antibiotic_exposure"] = zeros(Int,2,max_age+1,max_time_horizon)
    event_matrix["asthma_incidence"] = zeros(Int,2,max_age+1,max_time_horizon)
    event_matrix["asthma_prevalence"] = zeros(Int,2,max_age+1,max_time_horizon)
    event_matrix["death"] = zeros(Int,2,max_age+1,max_time_horizon)
    event_matrix["alive"] = zeros(Int,2,max_age+1,max_time_horizon)
    event_matrix["control"] = zeros(Int,2,max_age+1,3,max_time_horizon)
    event_matrix["exacerbation"] = zeros(Int,2,max_age+1,max_time_horizon)

    number_ABE = 0
    to = TimerOutput()

    # @timeit to "sleep" sleep(0.02)
    for cal_year in cal_years
        # for each calendar year
        tmp_cal_year_index = cal_year - min_cal_year + 1

        # afterwards, only do it for newborns
        n_cal_year = simulation.n
        initial_pop_index = Int[]

        tmp_index = 1

        for i in 1:n_cal_year
            # simulate an agent

            # agent-specific random effects
            random_parameter_initialization!(simulation.antibioticExposure)
            random_parameter_initialization!(simulation.incidence)
            random_parameter_initialization!(simulation.control)
            random_parameter_initialization!(simulation.exacerbation)

            # simulation.agent = process!(baby_agent,tmp_cal_year_index,simulation.birth)
            simulation.agent = process(tmp_cal_year_index,simulation.birth)

            # TODO: update outcome matrix
            n_list[tmp_cal_year_index,simulation.agent.sex+1] +=1

            # go through event processes for each agent
            while(simulation.agent.alive && simulation.agent.age <= max_age && simulation.agent.cal_year <= max_time_horizon)

                # run asthma incidence if agent does not have asthma
                if !simulation.agent.has_asthma # no asthma case
                    # antibotic expsoure first since this is assumed to affect asthma incidence only
                    number_ABE = process(simulation.agent,simulation.antibioticExposure)
                    # update the event matrix for antibiotic exposure

                    @set! simulation.agent.num_antibiotic_use += number_ABE

                    event_matrix["antibiotic_exposure"][simulation.agent.sex+1,simulation.agent.age+1,simulation.agent.cal_year] += simulation.agent.num_antibiotic_use

                    @set! simulation.agent.has_asthma = process(simulation.agent,simulation.incidence)

                    if simulation.agent.has_asthma
                        # record the asthma dx year
                        @set! simulation.agent.asthma_age = copy(simulation.agent.age)
                        # update asthma incidence event matrix
                        event_matrix["asthma_incidence"][simulation.agent.sex+1,simulation.agent.age+1,simulation.agent.cal_year] += 1
                        # update asthma prevalaence event matrix
                        event_matrix["asthma_prevalence"][simulation.agent.sex+1,simulation.agent.age+1,simulation.agent.cal_year] += 1

                        # # TODO: initialize asthma asthma control
                        @set! simulation.agent.control = process(simulation.agent,simulation.control)

                        # asthma exacerbation
                        # patient-specific variable for asthma exac
                        @set! simulation.agent.exac_hist[1] = process(simulation.agent,simulation.exacerbation)

                        # store control & exacerbation
                        event_matrix["control"][simulation.agent.sex+1,simulation.agent.age+1,findmax(simulation.agent.control)[2],simulation.agent.cal_year] += 1
                        event_matrix["exacerbation"][simulation.agent.sex+1,simulation.agent.age+1,simulation.agent.cal_year] += simulation.agent.exac_hist[1]
                    end
                else
                    # has asthma, so update asthma prevalence event matrix
                    event_matrix["asthma_prevalence"][simulation.agent.sex+1,simulation.agent.age+1,simulation.agent.cal_year] += 1

                    #  update control
                    @set! simulation.agent.control = process(simulation.agent,simulation.control)

                    # update exacerbation
                    @set! simulation.agent.exac_hist[2] = copy(simulation.agent.exac_hist[1])
                    @set! simulation.agent.exac_hist[1] = process(simulation.agent,simulation.exacerbation)

                    # store control and exacerbation
                    event_matrix["control"][simulation.agent.sex+1,simulation.agent.age+1,findmax(simulation.agent.control)[2],simulation.agent.cal_year] += 1
                    event_matrix["exacerbation"][simulation.agent.sex+1,simulation.agent.age+1,simulation.agent.cal_year] += simulation.agent.exac_hist[1]
                end

                # death - the last process
                if process(simulation.agent,simulation.death)
                    @set! simulation.agent.alive = false
                    # everyone dies in the end... Inevitable
                    event_matrix["death"][simulation.agent.sex+1,simulation.agent.age+1,simulation.agent.cal_year] += 1
                else
                    # record whether alive or not
                    event_matrix["alive"][simulation.agent.sex+1,simulation.agent.age+1,simulation.agent.cal_year] += 1
                    # update the patient stats
                    @set! simulation.agent.age += 1
                    # @set! simulation.agent.num_antibiotic_use += number_ABE
                    @set! simulation.agent.cal_year += 1
                end

            end # end while loop
        end # end for loop: agents
    end # end for loop: cal year

    print_timer(to::TimerOutput)

    event_matrix["n"] = n_list

    # reshape event matrix into a dictionry of list of matrices
    # @set! simulation.outcomeMatrix = event_matrix

    print("\n Simulation finished. Check your simulation object for results.")
    return event_matrix;
end





function process_demographic(simulation::Simulation,until_all_die=false)
    #TODO: write a function to check all the parameters are initialized; returns warning in such a case

    ### extract variables from simulation that will be used more than once
    max_age = simulation.max_age
    min_cal_year = simulation.starting_calendar_year
    max_cal_year = min_cal_year + simulation.time_horizon - 1
    # if n is not provided, use a default value, 100
    simulation.n = (ismissing(simulation.n) ? 100 : simulation.n)

    # if simulation.population_growth_type is not supported, use the low growth "LG"
    simulation.population_growth_type = (ismissing(simulation.population_growth_type) ? "LG" : simulation.population_growth_type)
    # birth projection
    @set! simulation.birth.trajectory = choose_bp(birth_projection,simulation.population_growth_type,min_cal_year)
    max_time_horizon = (until_all_die ? typemax(Int) : simulation.time_horizon)

    # initiate some variables to collect results
    cal_years = min_cal_year:max_cal_year

    # store the event matrix following this order
    n_list = zeros(Int,simulation.time_horizon,2)
    event_list= ["antibiotic_exposure", "asthma_incidence", "asthma_prevalence", "death","alive","control1","control2","control3","exacerbation","emigration","immigration"]
    # TODO: change this into a dict
    event_matrix = zeros(Int,length(cal_years)+(until_all_die ? max_age : 0),max_age+1,2,length(event_list)) # calendar year by age by num of events

    # time the performance
    to = TimerOutput()

    # baby agent
    # baby_agent = Agent(false,0,2015,true,0,false,0,0,nothing,[0,0])

    number_ABE = 0

    @timeit to "sleep" sleep(0.02)
    for cal_year in cal_years
        # for each calendar year
        @timeit to "calendar year $cal_year" begin
        tmp_cal_year_index = cal_year - min_cal_year + 1

        # for the first calendar year, do the simulation for the initial population
        # afterwards, only do it for newborns
        num_new_born = ceil(Int, simulation.n*simulation.birth.trajectory.relative_change[tmp_cal_year_index])
        num_immigrants = ceil(Int, num_new_born * simulation.immigration.overall_rate[tmp_cal_year_index])
        n_cal_year = (cal_year==min_cal_year ? ceil(Int,num_new_born / sum(filter(:age=> ==(0),simulation.birth.initial_population).prop)) : num_new_born + num_immigrants)
        initial_pop_index = Int[]

        if cal_year == min_cal_year
            initial_pop_index = process_initial_population(simulation.birth,n_cal_year)
        end

        tmp_index = 1
        tmp_age = 0
        tmp_sex = false

        for i in 1:n_cal_year
            # simulate agents
            # simulation.agent = process!(baby_agent,tmp_cal_year_index,simulation.birth)
            if cal_year == min_cal_year
                tmp_index = initial_pop_index[i]
                tmp_age = simulation.birth.initial_population.age[tmp_index]
                tmp_sex = simulation.birth.initial_population.sex[tmp_index]
                if tmp_age == 0
                    simulation.agent = process(tmp_cal_year_index,simulation.birth,tmp_sex,tmp_age)
                else
                    simulation.agent = process(tmp_cal_year_index,simulation.birth,tmp_sex,tmp_age)
                    # @set! simulation.agent.num_antibiotic_use = 1
                    # @set! simulation.agent.has_asthma = 1
                    # if simulation.agent.has_asthma == 1
                    #     @set! simulation.agent.control
                    #     @set! simulation.agent.exac_hist = 1
                    # end
                end
            else
                if rand(Bernoulli(num_new_born/n_cal_year))
                    # new born
                    simulation.agent = process(tmp_cal_year_index,simulation.birth)
                else
                    # immigrant
                    simulation.agent = process(tmp_cal_year_index,simulation.immigration)
                    event_matrix[simulation.agent.cal_year,simulation.agent.age+1,simulation.agent.sex+1,11] += 1
                end
            end

            # TODO: update outcome matrix
            n_list[tmp_cal_year_index,simulation.agent.sex+1] +=1

            # go through event processes for each agent
            while(simulation.agent.alive && simulation.agent.age <= max_age && simulation.agent.cal_year <= max_time_horizon)
                # death - the last process
                if process(simulation.agent,simulation.death)
                    @set! simulation.agent.alive = false
                    # everyone dies in the end... Inevitable
                    event_matrix[simulation.agent.cal_year,simulation.agent.age+1,simulation.agent.sex+1,4] += 1
                elseif process(simulation.agent.age,simulation.emigration)
                    @set! simulation.agent.alive = false
                    event_matrix[simulation.agent.cal_year,simulation.agent.age+1,simulation.agent.sex+1,10] += 1
                else
                    # record whether alive or not
                    event_matrix[simulation.agent.cal_year,simulation.agent.age+1,simulation.agent.sex+1,5] += 1
                    # update the patient stats
                    @set! simulation.agent.age += 1
                    @set! simulation.agent.cal_year += 1
                end

            end # end while loop

        end # end for loop: agents
        # println(cal_year)
    end # end of begin timeit

    end # end for loop: cal year
    print_timer(to::TimerOutput)

    tmp_event_dict = Dict()
    for jj in 1:length(event_list)
        tmp_event_dict[event_list[jj]] = [event_matrix[:,:,1,jj],event_matrix[:,:,2,jj]]
    end

    # reshape event matrix into a dictionry of list of matrices
    @set! simulation.outcomeMatrix = (; n = n_list, outcome_matrix = tmp_event_dict)

    print("\n Simulation finished. Check your simulation object for results.")
    return simulation.outcomeMatrix;
    # return println("all done")
end
