module Symbolic
using ModelingToolkit
import ModelingToolkit.Constant

struct Lag{T,N}
    variable::T
    lag::N
end

#you can't register a constructor so we have to introduce this intermediate.
lag(x,i) = Lag(x,i)

@register lag(x,i)

@variables t x y z

function apply(expr::Equation, data)
    rhs = expr.rhs
    apply(rhs, data)
end

function apply(expr::Constant, data)
    # constants don't have an op field they are just a value.
    return expr.value
end

function apply(expr::Operation, data)
    # this method only exists to harmonize the API for Equation, Constant, and Operation
    # all the real work is happening in the three argument version below.
    apply(expr.op, expr, data)
end

# this uses the operation function as a trait, so that we can dispatch on it;
# allowing client code to extend the language using Multiple Dispatch.
function apply(op::Function, expr::Operation, data)
    # handles the case where there are no more arguments to find.
    # we assume this is a leaf node in the expression, which refers to a field in the data
    if length(expr.args) == 0
        return getproperty(data, expr.op.name)
    end
    anses = map(expr.args) do a
        apply(a, data)
    end
    return op(anses...)
end


function apply(op::typeof(lag), expr::Operation, data)
    var = expr.args[1].op.name
    sft = expr.args[2].value
    return getproperty(data[sft], var)
end


using Test
@testset "Expression Construction" begin
    eqn1 = z ~ x+y
    eqn2 = z ~ x + lag(x, 1)
    wdw = y ~ lag(x, -1) + lag(x, 0) + lag(x, 1)
end

@testset "Expression Evaluation" begin
@test apply(z~x+y, (x=1, y=2)) == 3
@test apply(z~x+y^2, (x=1, y=2)) == 5
@test apply(z~2*x+y^2, (x=1, y=2)) == 6
end

eqn2 = z ~ 1 + lag(x, 0)
# @show apply(eqn2, (x=(1:5), y=(1:4)))


# how do we get the formula to execute like a time series model where given a
# DataFrame with a "time colum" or a Vector{NamedTuple} with a timestamp field
# or a Vector{(t=Time(...), data=(...))}? I think we need to pass a context
# around from the initial Model through the recursion tree. We might a well make
# it a read/write context so that people can overload it however they want.


data = [
    (t=1, x=1),
    (t=2, x=2),
    (t=3, x=3),
    (t=4, x=4),
    (t=5, x=5),
]

struct LagData{T}
    data::T
    current::Int
end

import Base: getindex, getproperty

getindex(ld::LagData, i::Integer) = ld.data[ld.current + i]
function Base.getproperty(ld::LagData, s::Symbol)
    if s == :data || s == :current
        return getfield(ld, s)
    end
    getfield(ld.data[ld.current], s)
end

function tsapply(eqn, data, lags=(-1:1))
    center = ceil(Int, length(lags)/2)
    map(1-first(lags):length(data)-last(lags)) do i
        trip = LagData([data[i+l] for l in lags], center)
        apply(eqn, trip)
    end
end

# The tsapply approach, does not use a context, because it is able to define
# collection types that behave appropriately for the lag function and the
# regular apply primitive. LagData creates a container that you can index with a
# time offset like ld[-1].field to get the shifted version of field. Or you can
# index it without a time offset to get the center time (Δt=0). Then the
# function tsapply creates an outer loop that packages an arbitrary collection
# (assumed to contain rows indexed by time) into sliding windows.

# client code can extend the windowing by defining a new version of tsapply with
# a different type for the lags. We use a range to denote a symmetric window.

@testset "Basic Lag Formulas" begin
@test tsapply(z ~ 1 + lag(x, -1), data) == [2,3,4]
@test tsapply(z ~ 1 + lag(x,  0), data) == [3,4,5]
@test tsapply(z ~ 1 + lag(x, +1), data) == [4,5,6]

@test tsapply(z ~ 2 * lag(x, -1), data) == 2 .* (1:3)
@test tsapply(z ~ 2 * lag(x,  0), data) == 2 .* (2:4)
@test tsapply(z ~ 2 * lag(x, +1), data) == 2 .* (3:5)

@test tsapply(z ~ lag(x, -1) + lag(x, -1), data) == 2 .* (1:3)
@test tsapply(z ~ lag(x,  0) + lag(x,  0), data) == 2 .* (2:4)
@test tsapply(z ~ lag(x, +1) + lag(x, +1), data) == 2 .* (3:5)

@test tsapply(z ~ x + lag(x, -1), data) == [3,5,7]
@test tsapply(z ~ x + lag(x,  0), data) == [4,6,8]
@test tsapply(z ~ x + lag(x, +1), data) == [5,7,9]
end
end
