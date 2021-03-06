# Display the entire type hierarchy starting from the specified `roottype`
function subtypetree(roottype, level = 1, indent = 4)
    level == 1 && println(roottype)
    for s in subtypes(roottype)
    println(join(fill(" ", level * indent)) * string(s))
    subtypetree(s, level + 1, indent)
    end
end

function Dict_initializer(parameter_names::Union{Nothing,Vector{Symbol}})
    isnothing(parameter_names) ? nothing : Dict(parameter_names .=> missing)
end

function choose_bp(bp::DataFrame,projection_scenario::String,min_year::Int64)
    filter!(row -> ((row.Projection_scenario == projection_scenario) & (row.calendar_year>=min_year)),bp)
end

function vec_to_dict(v::AbstractArray, ll::AbstractVector)::AbstractDict
    d = Dict()
        for i = 1:length(ll)
            d[ll[i]] = v[i]
        end
    return d
end


function asthma_age_weights_generator(max_age,parameters::AbstractDict)
    tmp_result = zeros(max_age+1,2)
    tmp_result[:,1] = map((x) -> Asthma_Julia.incidence_logit_prob(false,x,0,0,parameters),0:max_age)
    tmp_result[:,2] = map((x) -> Asthma_Julia.incidence_logit_prob(true,x,0,0,parameters),0:max_age)
    tmp_result
end

function ABE_probs_generator(max_age,parameters::AbstractDict,total_cal_years)
    tmp_result = zeros(max_age+1,2,total_cal_years)
    for cal in 1:total_cal_years
        tmp_result[:,1,cal] = map((x) -> Asthma_Julia.antibioticExposure_logit_prob(false,x,cal-1,parameters),0:max_age)
        tmp_result[:,2,cal] = map((x) -> Asthma_Julia.antibioticExposure_logit_prob(true,x,cal-1,parameters),0:max_age)
    end
    tmp_result
end

function overall_rate_calculator(adjust,immigration_projection_table,immigration_rate_per_birth,population_growth_type,starting_year)
    tmp = filter(:Projection_scenario => ==(population_growth_type), immigration_rate_per_birth)
    filter!(:REF_DATE => >=(starting_year),tmp)
    tmp2 = filter(:year => >=(starting_year),immigration_projection_table)
    select!(tmp2,:year,:L_per_thousand)
    return tmp.reference_to_birth .* tmp2.L_per_thousand ./ 1000 .* adjust
end

function set_up(max_age=111,starting_year=2020,time_horizon=20,n=100,population_growth_type="LG")

    agent = Agent(false,0,2015,true,0,false,0,0,nothing,[0,0])

    birth = Birth(nothing,nothing)
    @set! birth.trajectory = choose_bp(birth_projection,population_growth_type,starting_year)
    @set! birth.initial_population = initial_population_table

    death = Death(Dict_initializer([:??0,:??1,:??2]))

    emigration = Emigration(nothing, nothing)
    @set! emigration.projected_rate = emigration_rate.value_per_thousand[1]/1000
    @set! emigration.age_distribution = emigration_distribtuion
    immigration_rate_per_birth
    immigration = Immigration(nothing, nothing, nothing)
    @set! immigration.sex_ratio = 0.5
    # 0.75 is from the calibration (uncalibrated value is 0)
    @set! immigration.overall_rate = overall_rate_calculator(0.73,immigration_projection_table,immigration_rate_per_birth,population_growth_type,starting_year)
    @set! immigration.age_distribution = immigration_distribution

    antibioticExposure = AntibioticExposure(Dict_initializer([:??0_??,:??0_??]),Dict_initializer([:??0,:??age,:??sex,:??cal_year]))

    incidence = Incidence(Dict_initializer([:??0_??,:??0_??]),
    Dict_initializer( [:??0,:??age,:??age2,:??age3,:??age4,:??age5,:??sex,:??cal_year,:??CABE,:??ageM,:??age2M,:??age3M,:??age4M,:??age5M,:??cal_yearM,:??0_correction,:??0_overall_correction]),nothing)

    control = Control(Dict_initializer([:??0_??,:??0_??]), Dict_initializer( [:??0,:??age,:??sex,:??sexage,:??sexage2,:??age2, :??Dx2,:??Dx3,:??]), Dict_initializer([:ctl_ped,:ctl_adult]))

    exacerbation = Exacerbation(Dict_initializer([:??0_??,:??0_??]),
    Dict_initializer([:??0,:??age,:??sex,:??asthmaDx,:??prev_exac1,:??prev_exac2,:??control_C,:??control_PC,:??control_UC]),
    0)

    sim = Simulation(max_age,starting_year,time_horizon,n,population_growth_type,
    agent,
    birth,
    emigration,
    immigration,
    death,
    antibioticExposure,
    incidence,
    control,
    exacerbation,
    init_data,
    (;))


    @set! sim.incidence.initial_distribution = asthma_initial_distribution;

    @set! sim.death.parameters[:??0] =0;
    @set! sim.death.parameters[:??1] =-0.01;
    @set! sim.death.parameters[:??2] =0;

    @set! sim.antibioticExposure.hyperparameters[:??0_??] =-0.6; # about 35%
    @set! sim.antibioticExposure.hyperparameters[:??0_??] =0.1;
    @set! sim.antibioticExposure.parameters[:??age] = -0.0;
    @set! sim.antibioticExposure.parameters[:??sex] = 0.0;
    @set! sim.antibioticExposure.parameters[:??cal_year] = -0.01;

    # correct: age min
    # @set! sim.incidence.hyperparameters[:??0_??] = -4.539;
    # @set! sim.incidence.hyperparameters[:??0_??] = 1.678e-1;
    # @set! sim.incidence.parameters[:??age] = -2.644e-01;
    # @set! sim.incidence.parameters[:??age2] =  1.177e-02;
    # @set! sim.incidence.parameters[:??age3] = -2.627e-04;
    # @set! sim.incidence.parameters[:??age4] =  2.983e-06;
    # @set! sim.incidence.parameters[:??age5] =  -1.343e-08;
    # @set! sim.incidence.parameters[:??ageM] =  -6.563e-02;
    # @set! sim.incidence.parameters[:??age2M] = -6.207e-04;
    # @set! sim.incidence.parameters[:??age3M] =  1.285e-04;
    # @set! sim.incidence.parameters[:??age4M] = -2.744e-06;
    # @set! sim.incidence.parameters[:??age5M] = 1.723e-08;
    # @set! sim.incidence.parameters[:??sex] = 3.972e-01;

    # correct: age_mid
    # -1 is the calibration value
    @set! sim.incidence.hyperparameters[:??0_??] = -3.796215-1;
    @set! sim.incidence.hyperparameters[:??0_??] = 1.494e-1;
    @set! sim.incidence.parameters[:??age] = -3.092102e-01;
    @set! sim.incidence.parameters[:??age2] =  1.302142e-02;
    @set! sim.incidence.parameters[:??age3] =  -2.723386e-04;
    @set! sim.incidence.parameters[:??age4] =   2.833027e-06;
    @set! sim.incidence.parameters[:??age5] =  -1.142214e-08;
    @set! sim.incidence.parameters[:??ageM] =   -8.795666e-02;
    @set! sim.incidence.parameters[:??age2M] =1.388347e-03;
    @set! sim.incidence.parameters[:??age3M] =   3.462900e-05;
    @set! sim.incidence.parameters[:??age4M] = -9.415178e-07;
    @set! sim.incidence.parameters[:??age5M] = 5.509083e-09;
    @set! sim.incidence.parameters[:??sex] = 5.818913e-01;

    # wrong - rate per 100 when its actually rate per 100000
    # @set! sim.incidence.hyperparameters[:??0_??] = -1.935;
    # @set! sim.incidence.hyperparameters[:??0_??] = 0.1594;
    # @set! sim.incidence.parameters[:??age] = -2.850e-01;
    # @set! sim.incidence.parameters[:??sex] = 4.504e-01;
    # @set! sim.incidence.parameters[:??age2] = 1.315e-02;
    # @set! sim.incidence.parameters[:??age3] = -3.042e-04;
    # @set! sim.incidence.parameters[:??age4] =  3.550e-06;
    # @set! sim.incidence.parameters[:??age5] =   -1.630e-08;
    # @set! sim.incidence.parameters[:??ageM] = -7.732e-02;
    # @set! sim.incidence.parameters[:??age2M] =   1.719e-04 ;
    # @set! sim.incidence.parameters[:??age3M] =  1.050e-04;
    # @set! sim.incidence.parameters[:??age4M] =  -2.428e-06 ;
    # @set! sim.incidence.parameters[:??age5M] =  1.566e-08 ;
    # calendar effect!!!
    # @set! sim.incidence.parameters[:??cal_year] = -0.02549;
    # @set! sim.incidence.parameters[:??cal_yearM] = -0.02594;
    @set! sim.incidence.parameters[:??cal_year] = -0.0;
    @set! sim.incidence.parameters[:??cal_yearM] = -0.0;
    # incidence quite low; assume RR = OR = 1.5
    # => log(1.5) ~= 0.4
    # Murk et al., Nov 2021: Pooled OR = 1.5 => log(1.5)~ 0.406
    @set! sim.incidence.parameters[:??CABE] = 0.406;
    @set! sim.incidence.parameters[:??0_correction] = 0;
    @set! sim.incidence.parameters[:??0_overall_correction] = 0;

    # @set! sim.control.hyperparameters[:??0_??] = 0;
    # @set! sim.control.hyperparameters[:??0_??] = 1.67;
    # @set! sim.control.parameters[:??age] = 3.6395;
    # @set! sim.control.parameters[:??age2] = -3.9046;
    # @set! sim.control.parameters[:??sexage] = -1.8910;
    # @set! sim.control.parameters[:??Dx2] = -0.5931;
    # @set! sim.control.parameters[:??Dx3] =  -0.0455 ;
    # @set! sim.control.parameters[:??sex] =  0.4111;
    # @set! sim.control.parameters[:??] =  [-1.1043; 2.0709];
    # Random effects:
    #              Var  Std.Dev
    # studyid 2.739373 1.655105
    #
    # Location coefficients:
    #                Estimate Std. Error z value Pr(>|z|)
    # sex1            0.2181   0.5378     0.4055 0.6851349
    # age             3.0863   2.0707     1.4905 0.1361014
    # age_sq         -3.2447   2.3724    -1.3677 0.1714029
    # time_since_Dx2 -0.6003   0.2325    -2.5820 0.0098216
    # time_since_Dx3 -0.0586   0.2489    -0.2353 0.8139478
    # sex1:age       -0.5362   3.0131    -0.1779 0.8587682
    # sex1:age_sq    -1.6929   3.7129    -0.4560 0.6484169
    #
    # No scale coefficients
    #
    # Threshold coefficients:
    #     Estimate Std. Error z value
    # 1|2 -0.7905   0.4174    -1.8939
    # 2|3  2.3606   0.4201     5.6190
    #
    # log-likelihood: -2742.187
    # AIC: 5504.374
    # Condition number of Hessian: 18723.36
    @set! sim.control.hyperparameters[:??0_??] = 0;
    @set! sim.control.hyperparameters[:??0_??] = 1.655105;
    @set! sim.control.parameters[:??age] = 3.0863;
    @set! sim.control.parameters[:??age2] = -3.2447;
    @set! sim.control.parameters[:??sexage] = -0.5362;
    @set! sim.control.parameters[:??sexage2] = -1.6929;
    @set! sim.control.parameters[:??Dx2] = -0.6003;
    @set! sim.control.parameters[:??Dx3] =  -0.0586;
    @set! sim.control.parameters[:??sex] =  0.2181;
    # @set! sim.control.parameters[:??] =  [-0.7905; 2.3606];
    # use a calibrated value
    @set! sim.control.parameters[:??] =  [-0.60; 2.1];
    @set! sim.control.initial_parameters[:ctl_ped] = [0.38,0.46,0.16];
    @set! sim.control.initial_parameters[:ctl_adult] = [0.33,0.48,0.19];

    @set! sim.exacerbation.initial_rate = 0.357;
    @set! sim.exacerbation.hyperparameters[:??0_??] = 0;
    @set! sim.exacerbation.hyperparameters[:??0_??] = 0.0011;
    @set! sim.exacerbation.parameters[:??age] = 0;
    @set! sim.exacerbation.parameters[:??sex] = 0;
    @set! sim.exacerbation.parameters[:??asthmaDx] = 0;
    @set! sim.exacerbation.parameters[:??prev_exac1] = 0;
    @set! sim.exacerbation.parameters[:??prev_exac2] = 0;
    @set! sim.exacerbation.parameters[:??control_C] =  log(0.1896975);
    @set! sim.exacerbation.parameters[:??control_PC] =  log(0.3793949);
    @set! sim.exacerbation.parameters[:??control_UC] =  log(0.5690924);
    @set! sim.exacerbation.parameters[:??control] =  0;

    return sim
end
