# using CSV
# using DataFrames
# using GLM

birth_projection = CSV.read(joinpath(dirname(pathof(Asthma_Julia)), "processed_data","birth_projection.csv"),DataFrame)
# birth_projection = CSV.read(joinpath(Pkg.dir("Asthma_Julia"),"processed_data","birth_projection.csv"),DataFrame)
# birth_projection = CSV.read("processed_data/birth_projection.csv",DataFrame)
 joinpath(dirname(pathof(Asthma_Julia)))
# change to more intuitive column names
rename!(birth_projection,Dict(:REF_DATE => "calendar_year", :VALUE => "n"))
# correct the data type for n
birth_projection[!,:n] = convert.(Int64,round.(birth_projection.n,digits=0))

life_table = CSV.read(joinpath(dirname(pathof(Asthma_Julia)),"processed_data","life_table.csv"),DataFrame);

incidence_rate = CSV.read(joinpath(dirname(pathof(Asthma_Julia)),"processed_data","incidence_rate.csv"),DataFrame)
prevalence_rate = CSV.read(joinpath(dirname(pathof(Asthma_Julia)),"processed_data","prevalence_rate.csv"),DataFrame)
initial_population_table = CSV.read(joinpath(dirname(pathof(Asthma_Julia)),"processed_data","initial_pop_2020.csv"),DataFrame)
filter!(:sex=> !=("B"),initial_population_table)
initial_population_table.sex = (initial_population_table.sex .== "M")

emigration_rate = CSV.read(joinpath(dirname(pathof(Asthma_Julia)),"processed_data","pop_emigration_projection_2018.csv"),DataFrame)
emigration_distribtuion = CSV.read(joinpath(dirname(pathof(Asthma_Julia)),"processed_data","pop_emigration_age_distribution.csv"),DataFrame)

immigration_projection_table = CSV.read(joinpath(dirname(pathof(Asthma_Julia)),"processed_data","pop_immigration_projection_2019.csv"),DataFrame)
immigration_distribution = CSV.read(joinpath(dirname(pathof(Asthma_Julia)),"processed_data","pop_immigration_distribution_2018.csv"),DataFrame)
immigration_rate_per_birth = CSV.read(joinpath(dirname(pathof(Asthma_Julia)),"processed_data","pop_all_projected_2020.csv"),DataFrame)

asthma_initial_distribution = CSV.read(joinpath(dirname(pathof(Asthma_Julia)),"processed_data","asthma_initial_distribution.csv"),DataFrame)
filter!(:sex=> !=("B"),asthma_initial_distribution)
asthma_initial_distribution.sex = (asthma_initial_distribution.sex .== "M")
asthma_initial_distribution.new_prop = rand.(Beta.(asthma_initial_distribution.alpha,asthma_initial_distribution.beta))
asthma_initial_distribution = [filter(:sex => ==(false),asthma_initial_distribution),filter(:sex => ==(true),asthma_initial_distribution)]

init_data = JLD2.load(joinpath(dirname(pathof(Asthma_Julia)),"processed_data","init_data_Nov5.jld2"))["output"]

# asthma_initial_distribution = CSV.read("src/processed_data/asthma_initial_distribution.csv",DataFrame)
# filter!(:sex=> !=("B"),asthma_initial_distribution)
# asthma_initial_distribution.sex = (asthma_initial_distribution.sex .== "M")
# asthma_initial_distribution.new_prop = rand.(Beta.(asthma_initial_distribution.alpha,asthma_initial_distribution.beta))
# asthma_initial_distribution = [filter(:sex => ==(false),asthma_initial_distribution),filter(:sex => ==(true),asthma_initial_distribution)]
# tmp_index = 1
# tmp_age = 68
# tmp_p = asthma_initial_distribution[tmp_index].prop[searchsortedfirst(cumsum(asthma_initial_distribution[tmp_index].age_upper),tmp_age)]
# rand(Bernoulli(9.8/100))
