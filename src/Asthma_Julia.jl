module Asthma_Julia

# Write your package code here
using DataFrames, CSV, JLD2, FileIO
using Setfield, Distributions, StatsFuns, StatsBase
using TimerOutputs, Printf

# using Plots

include("simulation.jl")

export
    # functions
    process,
    process_initial,
    process_initial_population,
    set_up,
    # global datasets
    life_table,
    birth_projection,
    incidence_rate,
    prevalence_rate,
    initial_population_table,
    emigration_rate,
    emigration_distribtuion,
    immigration_projection_table,
    immigration_distribution,
    immigration_rate_per_birth,
    asthma_initial_distribution,
    init_data
end # module
