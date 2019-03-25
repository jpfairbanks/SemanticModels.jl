using Distributions, Random, DataFrames, GLM

export generate_synthetic_data, RegressionProblem, ols
function generate_synthetic_data(population_size, start_yr, end_yr)

    Random.seed!(1234)

    years = range(start_yr, end_yr+1)

    flu_mu = population_size*rand(Uniform(0.25, 0.75))
    flu_std = population_size*rand(Uniform(0.1, 0.2))

    flu_distribution = Normal(flu_mu, flu_std)
    flu_patients = [abs(rand(flu_distribution)) for i in start_yr:end_yr+1]

    beta_0 = population_size*rand(Uniform(0.1, 0.25))
    beta_1 = rand(Uniform(0.5, 0.75))

    error_distribution = Normal(0.1, 2.0)
    errors = [abs(rand(error_distribution)) for i in start_yr:end_yr]

    vaccines_produced = [0.0 for i in start_yr:end_yr]

    for i in range(2, stop=length(years)-1, step=1)
        vaccines_produced[i] = ceil(beta_0 + beta_1*flu_patients[i-1] + errors[i-1])
    end

    df = DataFrame(year=Int64[], flu_patients=Float64[], vaccines_produced=Union{Float64, Missing}[])

    push!(df, [years[1], flu_patients[1], missing])

    for i in range(2, length(years)-1)
        push!(df, [years[i], flu_patients[i], vaccines_produced[i]])
    end

    return df
end

function ols(df, num_flu_patients_from_sim, year_to_predict)

    model =  lm(@formula(vaccines_produced ~ flu_patients), df[2:length(df.year), [:year, :flu_patients, :vaccines_produced]])
    targetDF = DataFrame(year=year_to_predict, flu_patients=num_flu_patients_from_sim, vaccines_produced=missing)
    predicted_num_vaccines = predict(model, targetDF)
    println("GLM Model:")
    println(model)
    println("Predicted number of vaccines based on simulated number of flu patients for year ", year_to_predict, " = ", ceil(predicted_num_vaccines[1]))
    return predicted_num_vaccines

end

struct RegressionProblem{F,T,U,Y} <: AbstractModel
    formula::F
    β::T
    X::U
    y::Y
end

function solve(m::RegressionProblem{F,T,U,Missing}) where {F,T, U}
    return predict(m.β, m.X)
end

function solve(m::RegressionProblem{F, Missing, U,V}) where {F,U,V}
    return lm(m.formula, m.X)
end