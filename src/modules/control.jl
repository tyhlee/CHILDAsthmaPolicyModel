struct Control <: Control_Module
    hyperparameters::Union{AbstractDict,Nothing}
    parameters::Union{AbstractDict,Nothing}
    initial_parameters::Union{AbstractDict,Nothing}
end

function process(ag::Agent,ctl::Control)
    age_scaled = ag.age / 100
    control_prediction(ctl.parameters[:β0]+
    age_scaled*ctl.parameters[:βage]+
    ag.sex*ctl.parameters[:βsex]+
    age_scaled * ag.sex * ctl.parameters[:βsexage] +
    age_scaled^2 * ag.sex * ctl.parameters[:βsexage2] +
    age_scaled^2 * ctl.parameters[:βage2] +
    (5 <= ag.age-ag.asthma_age < 20) * ctl.parameters[:βDx2] +
    (20 <= ag.age-ag.asthma_age) * ctl.parameters[:βDx3] , ctl.parameters[:θ])
end

function process_initial(ag::Agent, ctl::Control,dat)
    rand(Distributions.Dirichlet(dat[ag.sex+1,ag.age+1,:]))
end

# pred function
function control_prediction(eta::Float64,theta::Union{Float64,Vector{Float64}};inv_link::Function=StatsFuns.logistic)::Union{Float64,Vector{Float64}}
    theta = [-1e5;theta;1e5]
    [inv_link(theta[j+1] - eta) - inv_link(theta[j] - eta) for j in 1:(length(theta)-1)]
end

# input: initialized hyperparameters, empty parameters
function random_parameter_initialization!(ctl::Control)
    ctl.parameters[:β0] = rand(Normal(ctl.hyperparameters[:β0_μ],ctl.hyperparameters[:β0_σ]))
end


# hyperparameters_names = [:β0_μ,:β0_σ]
#
# parameter_names = [:β0,:βage,:βsex,:βsexage,:βage2, :βDx2,:βDx3,:θ]
# control = Control(Dict_initializer(hyperparameters_names), Dict_initializer(parameter_names))

# using Setfields
# ag = Agent(false,25,2020,true,0,true,10,nothing,nothing,[1,1])
#
# ctl = Control(Dict_initializer([:β0_μ,:β0_σ]), Dict_initializer( [:β0,:βage,:βsex,:βsexage,:βage2, :βDx2,:βDx3,:θ]), Dict_initializer([:ctl_ped,:ctl_adult]))
#
# @set! ctl.hyperparameters[:β0_μ] = 0;
# @set! ctl.hyperparameters[:β0_σ] = 1.655;
# @set! ctl.parameters[:βsex] =  0.4003;
# @set! ctl.parameters[:βage] = 3.6288;
# @set! ctl.parameters[:βage2] = -3.903;
# @set! ctl.parameters[:βsexage] = -1.8656;
# @set! ctl.parameters[:βDx2] = -0.5893;
# @set! ctl.parameters[:βDx3] =  -0.0457 ;
# @set! ctl.parameters[:θ] =  [-0.6974; 2.4536];
# # @set! ctl.parameters[:θ] =  [-0.89; 2.3];
# @set! ctl.initial_parameters[:ctl_ped] = [0.38,0.46,0.16];
# @set! ctl.initial_parameters[:ctl_adult] = [0.33,0.48,0.19];
# using Distributions
# using StatsFuns
# using Printf
# # random_parameter_initialization!(ctl)
# @set! ctl.parameters[:β0]  = 0;
# @set! ag.asthma_age = 20;
# (process(ag,ctl))
