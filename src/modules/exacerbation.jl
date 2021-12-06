struct Exacerbation <: Exacerbation_Module
    hyperparameters::Union{AbstractDict,Nothing}
    parameters::Union{AbstractDict,Nothing}
    initial_rate::Float64
end

function process(ag::Agent,exac::Exacerbation)
    parameters = exac.parameters
    # age_scaled::Float64 = ag.age
    # acq = ag.control[1] + ag.control[2]*3 + ag.control[3] * 5
    exacerbation_prediction(parameters[:β0]+
    ag.age * parameters[:βage]+
    ag.sex * parameters[:βsex]+
    ag.asthma_age * parameters[:βasthmaDx] +
    ag.exac_hist[1] * parameters[:βprev_exac1] +
    ag.exac_hist[2] * parameters[:βprev_exac2] +
    ag.control[1] * parameters[:βcontrol_C] +
    ag.control[2] * parameters[:βcontrol_PC] +
    ag.control[3] * parameters[:βcontrol_UC])
    # acq*parameters[:βcontrol])
end

function process_initial(ag::Agent,exac::Exacerbation)
    # from EBA
    if ag.age == 0
        return [rand(Poisson(exac.initial_rate)),0]
    else
        return rand.(Poisson.([exac.initial_rate,exac.initial_rate]))
    end
end

function random_parameter_initialization!(exac::Exacerbation)
    exac.parameters[:β0] = rand(Normal(exac.hyperparameters[:β0_μ], exac.hyperparameters[:β0_σ]))
end

# pred function: Poisson distribution
function exacerbation_prediction(eta::Float64;inv_link::Function=exp)
    rand(Poisson(inv_link(eta)))
end

# hyperparameters_names = [:β0_μ,:β0_σ]
#
# parameter_names = [:β0,:βage,:βsex,:βasthmaDx,:βprev_exac1,:βprev_exac2,:βcontrol_C,:βcontrol_PC,:βcontrol_UC]

# exacerbation = Exacerbation(Dict_initializer([:β0_μ,:β0_σ]),
# Dict_initializer([:β0,:βage,:βsex,:βasthmaDx,:βprev_exac1,:βprev_exac2,:βcontrol_C,:βcontrol_PC,:βcontrol_UC]))
