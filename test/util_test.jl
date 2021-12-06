using BenchmarkTools



function dict_regressor(input_params::Dict,data::AbstractMatrix)
    tmp_sum::Vector{Float64} = zeros(size(data)[1])
    for index in 1:length(input_params)
        tmp_sum += input_params["$index"] * data[:,index]
    end
    tmp_sum
end

function vector_regressor(input_params::AbstractVector,data::AbstractMatrix)
    data * input_params;
end

n = 10000
k = 15
params_vec = rand(k)
params= Dict()
for i in 1:k
    params["$i"] = params_vec[i]
end

X = rand(n,k);

dict_regressor(params,X)[1:98]
vector_regressor(params_vec,X)[1:98]

@benchmark dict_regressor($params,rand(n,k))
@benchmark vector_regressor($params_vec,rand(n,k))

# analysis shows that vector form might be more desirable