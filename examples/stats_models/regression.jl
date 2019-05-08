
using SemanticModels
using Random
using LightGraphs
using MetaGraphs
using DataFrames
using GraphPlot
using DifferentialEquations
using Plots
using MultivariateStats
using Statistics

mutable struct DepVar{T}
    value::T
end

mutable struct IndepVar{T}
    value::T
end

# to allow transformations that feature numeric elements/vectors 
mutable struct Other{T}
    value::T
end


const Var = Union{DepVar, IndepVar}
const RegComponents = Union{DepVar, IndepVar, Other}


mutable struct OpElementTypes{a, b}
    vec_a::a
    vec_b::b
end

function var_type_check(a::Var, b::Other)
    return isa(a, DepVar) ? DepVar : IndepVar
end
    
function var_type_check(a::Other, b::Var)
    return isa(b, DepVar) ? DepVar : IndepVar
end

function var_type_check(a::Var, b::Var)   
    return isa(a, DepVar) || isa(b, DepVar) ? DepVar : IndepVar

end

function var_type_check(a::Other, b::Other)   
    return Other
end


binary_ops = [+,-,*,/]

# example loops to get element-level truth tables 
dv_num = 10
iv_num = 3
other_num = 7


for op in binary_ops
    for a in (DepVar(dv_num), IndepVar(iv_num), Other(other_num))
        for b in (DepVar(dv_num), IndepVar(iv_num), Other(other_num))
            output_check = var_type_check(a,b)
            result_type = output_check(op(a.value, b.value))
            print("Op: $op, a: $a, b: $b, result_type: $result_type \n")
        end
    end
end

function transform_col_vector(op, vec_a::Array, vec_b::Array)
    
    if length(vec_a) == length(vec_b)

        output_types = map(var_type_check, [x for x in vec_a], [x for x in vec_b]) 
        numeric_results = broadcast(op, [x.value for x in vec_a], [x.value for x in vec_b])    
        typed_results = [i(j) for (i,j) in zip(output_types, numeric_results)]
            #output_types[i](numeric_results[i]) for i in range](1:length(vec_a))]
        return typed_results
    else
        return "Error: dimensions mismatch"
    end
end

function regress(vec_a::Array{IndepVar{Float64}, 2}, vec_b::Array{IndepVar{Float64}, 2}, orig_x::Array{IndepVar{Float64}, 2}, orig_y::Array{DepVar{Float64}, 2}, op)
    
    println("Case 1: op(IV, IV) yields IV_mod; regress orig_y on IV_mod")
    IV_mod = transform_col_vector(op, vec_a, vec_b)
    
    x_mod_vals = [x.value for x in IV_mod]
    
    
    y_values = [y.value for y in orig_y]
    
    if all([x == 0 for x in x_mod_vals])
        println("Error: subtracting IV from itself yields 0; matrix is not positive definite; cannot regress.")
        return false, IV_mod
    else
        reg_coef = llsq(x_mod_vals, y_values; bias=false)
        return true, IV_mod, reg_coef
    end
    
end

function regress(vec_a::Array{DepVar{Float64},2}, vec_b::Array{IndepVar{Float64}, 2}, orig_x::Array{IndepVar{Float64}, 2}, orig_y::Array{DepVar{Float64}, 2}, op)
    
    println("Case 2: (DV, IV) yields (unexpected) DV_mod; cannot regress orig_y on DV_mod")
    accidental_DV_mod = transform_col_vector(op, vec_a, vec_b)
    
    println(accidental_DV_mod)
    return false, accidental_DV_mod
    
end 

function regress(vec_a::Array{IndepVar{Float64},2}, vec_b::Array{DepVar{Float64}, 2}, orig_x::Array{IndepVar{Float64}, 2}, orig_y::Array{DepVar{Float64}, 2}, op)
    
    println("Case 2: (IV, DV) yields (unexpected) DV_mod; cannot regress orig_y on DV_mod")    
    accidental_DV_mod = transform_col_vector(op, vec_a, vec_b)
    
    println(accidental_DV_mod)
    return false, accidental_DV_mod
    
end 

function regress(vec_a::Array{DepVar{Float64},2}, vec_b::Array{DepVar{Float64},2}, orig_x::Array{IndepVar{Float64},2}, orig_y::Array{DepVar{Float64},2}, op)
    
    println("Case 3: (DV, DV) yields DV_mod; regress DV_mod on orig_x")    
    DV_mod = transform_col_vector(op, vec_a, vec_b)
    
    y_mod_vals = [x.value for x in DV_mod]
    x_values = [x.value for x in orig_x]
    
    reg_coef = llsq(x_values, y_mod_vals; bias=false)
    return true, DV_mod, reg_coef
    
end 

function regress(vec_a::Array{DepVar{Float64},2}, vec_b::Array{Other{Float64},2}, orig_x::Array{IndepVar{Float64},2}, orig_y::Array{DepVar{Float64},2}, op)
    
    println("Case 4: (DV, Other) yields DV_mod; regress DV_mod on orig_x")    
    DV_mod = transform_col_vector(op, vec_a, vec_b)
    
    y_mod_vals = [x.value for x in DV_mod]
    x_values = [x.value for x in orig_x]
    
    reg_coef = llsq(x_values, y_mod_vals; bias=false)
    return true, DV_mod, reg_coef
    
end 

function regress(vec_a::Array{Other{Float64},2}, vec_b::Array{DepVar{Float64},2}, orig_x::Array{IndepVar{Float64},2}, orig_y::Array{DepVar{Float64},2}, op)
    
    println("Case 4: (Other, DV) yields DV_mod; regress DV_mod on orig_x")    
    DV_mod = transform_col_vector(op, vec_a, vec_b)
    
    y_mod_vals = [x.value for x in DV_mod]
    x_values = [x.value for x in orig_x]
    
    reg_coef = llsq(x_values, y_mod_vals; bias=false)
    return true, DV_mod, reg_coef
end 

function regress(vec_a::Array{IndepVar{Float64},2}, vec_b::Array{Other{Float64},2}, orig_x::Array{IndepVar{Float64},2}, orig_y::Array{DepVar{Float64},2}, op)
    
    println("Case 5: (IV, Other) yields IV_mod; regress orig_y on IV_mod")    
    IV_mod = transform_col_vector(op, vec_a, vec_b)
    
    x_mod_vals = [x.value for x in IV_mod]
    y_values = [y.value for y in orig_y]
    
    reg_coef = llsq(x_mod_vals, y_values; bias=false)
    
    return true, IV_mod, reg_coef
    
end 

function regress(vec_a::Array{Other{Float64},2}, vec_b::Array{IndepVar{Float64},2}, orig_x::Array{IndepVar{Float64},2}, orig_y::Array{DepVar{Float64},2}, op)
    
    println("Case 5: (Other, IV) yields IV_mod; regress orig_y on IV_mod")    
    IV_mod = transform_col_vector(op, vec_a, vec_b)
    
    x_mod_vals = [x.value for x in IV_mod]
    y_values = [y.value for y in orig_y]
    
    reg_coef = llsq(x_mod_vals, y_values; bias=false)
    
    return true, IV_mod, reg_coef
    
end 

function regress(vec_a::Array{Other{Float64},2}, vec_b::Array{Other{Float64},2}, orig_x::Array{IndepVar{Float64},2}, orig_y::Array{DepVar{Float64},2}, op)
    
    println("Case 65: (Other, Other) yields other_mod; nothing to regress.")    
    other_mod = transform_col_vector(op, vec_a, vec_b)
    
    return false, other_mod
    
end 

function simulate_type_checked_univariate_reg(n=10)

    binary_ops = [+,-,*,/]
    
    x_vals = rand(n,1) 
    y_vals = rand(n,1)
    other_vals = rand(n,1)

    sample_DV_col_vec = [DepVar(yi) for yi in y_vals]
    sample_IV_col_vec = [IndepVar(xi) for xi in x_vals]
    sample_other_col_vec = [Other(oi) for oi in other_vals]
    
    # convert/promote so !have to hardcode the var data type and array dimensions?

    # subtraction doesn't work if we subtract the indep vec from itself
    
    counter = 1
    
    for op in binary_ops
        for vec_a in (sample_IV_col_vec, sample_DV_col_vec, sample_other_col_vec)
            for vec_b in (sample_IV_col_vec, sample_DV_col_vec, sample_other_col_vec)
                
                println("Scenario $counter: \n")
                
                results = regress(vec_a, vec_b, sample_IV_col_vec, sample_DV_col_vec, op)

                for x in results
                    println(x)
                end
                
                println()
                
                counter +=1
    
            end
        end
    end
end

    


simulate_type_checked_univariate_reg(10)
