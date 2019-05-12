using SemanticModels
using Random
using MultivariateStats
using Statistics
import Base.+, Base.-, Base.*, Base./

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

var_type_check(a::DepVar, b::Other) = DepVar
var_type_check(a::Other, b::DepVar) = DepVar

var_type_check(a::IndepVar, b::Other) = IndepVar
var_type_check(a::Other, b::IndepVar) = IndepVar

var_type_check(a::DepVar, b::IndepVar) = DepVar
var_type_check(a::IndepVar, b::DepVar) = DepVar

var_type_check(a::IndepVar, b::IndepVar) = IndepVar
var_type_check(a::DepVar, b::DepVar) = DepVar

var_type_check(a::Other, b::Other) = Other

# Anything op(DV, *) yields a DV; op(IV, Other) yields IV and vice versa; op(IV, IV) yields IV; op(Other, Other)
output_check(op::Function, a::DepVar, b::DepVar) = DepVar(eval(op)(a.value, b.value))
output_check(op::Function, a::DepVar, b::RegComponents) = DepVar(eval(op)(a.value, b.value))
output_check(op::Function, a::RegComponents, b::DepVar) = DepVar(eval(op)(a.value, b.value))
output_check(op::Function, a::IndepVar, b::IndepVar) = IndepVar(eval(op)(a.value, b.value))
output_check(op::Function, a::Other, b::IndepVar) = IndepVar(eval(op)(a.value, b.value))
output_check(op::Function, a::IndepVar, b::Other) = IndepVar(eval(op)(a.value, b.value))
output_check(op::Function, a::Other, b::Other) = Other(eval(op)(a.value, b.value))

for binary_op in (:+, :-, :*, :/)
    @eval ($binary_op)(a::RegComponents,b::RegComponents) = output_check($binary_op, a, b)
end

# # example loops to get element-level truth tables
dv_num = 10
iv_num = 3
other_num = 7

for op in (+, -, *, /)
    for a in (DepVar(dv_num), IndepVar(iv_num), Other(other_num))
        for b in (DepVar(dv_num), IndepVar(iv_num), Other(other_num))
            @show @eval ($op)($a,$b)
        end
    end
end

function regress(vec_a::Array{IndepVar{T}}, vec_b::Array{IndepVar{T}}, orig_x::Array{IndepVar{T}}, orig_y::Array{DepVar{T}}, op) where {T<:Number}
    println("Case 1: op(IV, IV) yields IV_mod; regress orig_y on IV_mod")

    IV_mod = @eval broadcast($op, $vec_a, $vec_b)
    IV_mod_vals = [x.value for x in IV_mod]
    y_values = [y.value for y in orig_y]

    if all([x == 0 for x in IV_mod_vals])
        println("Error: subtracting IV from itself yields 0; matrix is not positive definite; cannot regress.")
        return false, IV_mod_vals
    else
        reg_coef = llsq(IV_mod_vals, y_values; bias=false)
        return true, IV_mod_vals, reg_coef
    end
end

function regress(vec_a::Array{DepVar{T}}, vec_b::Array{IndepVar{T}}, orig_x::Array{IndepVar{T}}, orig_y::Array{DepVar{T}}, op) where {T<:Number}
    println("Case 2: (DV, IV) yields (unexpected) DV_mod; cannot regress orig_y on DV_mod")
    accidental_DV_mod = @eval broadcast($op, $vec_a, $vec_b)

    println(accidental_DV_mod)
    return false, accidental_DV_mod, NaN
end

function regress(vec_a::Array{IndepVar{T}}, vec_b::Array{DepVar{T}}, orig_x::Array{IndepVar{T}}, orig_y::Array{DepVar{T}}, op) where {T<:Number}
    println("Case 2: (IV, DV) yields (unexpected) DV_mod; cannot regress orig_y on DV_mod")
    accidental_DV_mod = @eval broadcast($op, $vec_a, $vec_b)
    println(accidental_DV_mod)
    return false, accidental_DV_mod, NaN
end

function regress(vec_a::Array{DepVar{T}}, vec_b::Array{DepVar{T}}, orig_x::Array{IndepVar{T}}, orig_y::Array{DepVar{T}}, op) where {T<:Number}
    println("Case 3: (DV, DV) yields DV_mod; regress DV_mod on orig_x")
    DV_mod = @eval broadcast($op, $vec_a, $vec_b)
    
    y_mod_vals = [y.value for y in DV_mod]
    x_values = [x.value for x in orig_x]

    reg_coef = llsq(x_values, y_mod_vals; bias=false)
    return true, DV_mod, reg_coef
end

function regress(vec_a::Array{DepVar{T}}, vec_b::Array{Other{T}}, orig_x::Array{IndepVar{T}}, orig_y::Array{DepVar{T}}, op) where {T<:Number}
    println("Case 4: (DV, Other) yields DV_mod; regress DV_mod on orig_x")
    DV_mod =  @eval broadcast($op, $vec_a, $vec_b)

    y_mod_vals = [y.value for y in DV_mod]
    x_values = [x.value for x in orig_x]

    reg_coef = llsq(x_values, y_mod_vals; bias=false)
    return true, DV_mod, reg_coef
end

function regress(vec_a::Array{Other{T}}, vec_b::Array{DepVar{T}}, orig_x::Array{IndepVar{T}}, orig_y::Array{DepVar{T}}, op) where {T<:Number}
    println("Case 4: (Other, DV) yields DV_mod; regress DV_mod on orig_x")
    DV_mod = @eval broadcast($op, $vec_a, $vec_b)

    y_mod_vals = [y.value for y in DV_mod]
    x_values = [x.value for x in orig_x]

    reg_coef = llsq(x_values, y_mod_vals; bias=false)
    return true, DV_mod, reg_coef
end

function regress(vec_a::Array{IndepVar{T}}, vec_b::Array{Other{T}}, orig_x::Array{IndepVar{T}}, orig_y::Array{DepVar{T}}, op) where {T<:Number}
    println("Case 5: (IV, Other) yields IV_mod; regress orig_y on IV_mod")
    IV_mod = @eval broadcast($op, $vec_a, $vec_b)

    x_mod_vals = [x.value for x in IV_mod]
    y_values = [y.value for y in orig_y]

    reg_coef = llsq(x_mod_vals, y_values; bias=false)
    return true, IV_mod, reg_coef
end

function regress(vec_a::Array{Other{T}}, vec_b::Array{IndepVar{T}}, orig_x::Array{IndepVar{T}}, orig_y::Array{DepVar{T}}, op) where {T<:Number}
    println("Case 5: (Other, IV) yields IV_mod; regress orig_y on IV_mod")
    IV_mod = @eval broadcast($op, $vec_a, $vec_b)

    x_mod_vals = [x.value for x in IV_mod]
    y_values = [y.value for y in orig_y]

    reg_coef = llsq(x_mod_vals, y_values; bias=false)
    return true, IV_mod, reg_coef
end

function regress(vec_a::Array{Other{T}}, vec_b::Array{Other{T}}, orig_x::Array{IndepVar{T}}, orig_y::Array{DepVar{T}}, op) where {T<:Number}
    println("Case 6: (Other, Other) yields other_mod; nothing to regress.")
    other_mod = @eval broadcast($op, $vec_a, $vec_b)

    return false, other_mod, NaN
end

function simulate_type_checked_univariate_reg(n=10)

    binary_ops = [+,-,*,/]

    x_vals = rand(n,1)
    y_vals = rand(n,1)
    other_vals = rand(n,1)
    
    sample_DV_col_vec = DepVar.(y_vals)
    sample_IV_col_vec = IndepVar.(x_vals)
    sample_other_col_vec = Other.(other_vals)

    # convert/promote so !have to hardcode the var data type and array dimensions?

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


