# Rough calibration based on a grid search
using Revise
using Asthma_Julia
using JLD2
using JLD
using Setfield

# demographic module: inspect pop growth and age pyramid
# calibrate the pop growth by immigration
simulation = set_up()
@set! simulation.time_horizon = 40;
@set! simulation.n = 500;
@set! simulation.immigration.overall_rate = Asthma_Julia.overall_rate_calculator(0.73,immigration_projection_table,immigration_rate_per_birth,simulation.population_growth_type,simulation.starting_calendar_year)
@set! simulation.death.parameters[:β1] =-0.01;
@set! simulation.antibioticExposure.parameters[:βcal_year] = 0;
@set! simulation.incidence.parameters[:βcal_year] = 0;
@set! simulation.incidence.parameters[:βcal_yearM] = 0;
look = Asthma_Julia.process(simulation)
save("src/simulation_output/V1_demo_0.73.jld","output",look)

# asthma incidence and prevalence
# calibrate the asthma incidence so that prevalence is constant at about 8%
simulation = set_up()
@set! simulation.time_horizon = 40;
@set! simulation.n = 500;
@set! simulation.antibioticExposure.parameters[:βcal_year] = 0;
@set! simulation.incidence.parameters[:βcal_year] = 0;
@set! simulation.incidence.parameters[:βcal_yearM] = 0;
@set! simulation.incidence.parameters[:βCABE] = 0;
@set! simulation.incidence.hyperparameters[:β0_μ] = -4.85;
look = Asthma_Julia.process(simulation)
save("src/simulation_output/V1_asthma.jld","output",look)

# ABE
simulation = set_up()
@set! simulation.time_horizon = 40;
@set! simulation.n = 500;
# constant
@set! simulation.incidence.parameters[:βCABE] = 0;
@set! simulation.antibioticExposure.parameters[:βcal_year] = -0.00;
look = Asthma_Julia.process(simulation)
save("src/simulation_output/V1_ABE_constant.jld","output",look)
# decreasing
@set! simulation.incidence.parameters[:βCABE] = 0;
@set! simulation.antibioticExposure.parameters[:βcal_year] = -0.01;
look = Asthma_Julia.process(simulation)
save("src/simulation_output/V1_ABE_decreasing.jld","output",look)
# constant & asthma
@set! simulation.incidence.parameters[:βCABE] = log(1.5);
@set! simulation.antibioticExposure.parameters[:βcal_year] = -0.00;
@set! simulation.incidence.parameters[:β0_correction] = -1.0;
@set! simulation.incidence.parameters[:β0_overall_correction] = -0.0;
look = Asthma_Julia.process(simulation)
save("src/simulation_output/V1_ABE_constant_asthma.jld","output",look)

# control
# calibrate contro level cutoffs in the ordinal model
simulation = set_up()
@set! simulation.time_horizon = 40;
@set! simulation.n = 500;
@set! simulation.incidence.parameters[:βCABE] = log(1.5);
@set! simulation.antibioticExposure.parameters[:βcal_year] = -0.00;
@set! simulation.incidence.parameters[:β0_correction] = -1.0
@set! simulation.control.parameters[:θ] =  [-0.60; 2.1];
look = Asthma_Julia.process(simulation)
save("src/simulation_output/V1_control.jld","output",look)

# exacerbation
simulation = set_up()
@set! simulation.time_horizon = 40;
@set! simulation.n = 500;
@set! simulation.incidence.parameters[:βCABE] = log(1.5);
@set! simulation.antibioticExposure.parameters[:βcal_year] = -0.00;
@set! simulation.incidence.parameters[:β0_correction] = -1.0
@set! simulation.exacerbation.parameters[:βprev_exac1] = 0.1;
@set! simulation.exacerbation.parameters[:βprev_exac2] = 0.1/2;
look = Asthma_Julia.process(simulation)
save("src/simulation_output/V1_exac.jld","output",look)

# NOT VALIDATION
# Projection decreasing & asthma
simulation = set_up()
@set! simulation.time_horizon = 40;
@set! simulation.n = 500;
@set! simulation.incidence.parameters[:β0_correction] = -1.0
@set! simulation.exacerbation.parameters[:βprev_exac1] = 0.1;
@set! simulation.exacerbation.parameters[:βprev_exac2] = 0.1/2;
@set! simulation.incidence.parameters[:βCABE] = log(1.5);
@set! simulation.antibioticExposure.parameters[:βcal_year] = -0.01;
look = Asthma_Julia.process(simulation)
save("src/simulation_output/V1_ABE_decreasing_asthma_0.01.jld","output",look)
