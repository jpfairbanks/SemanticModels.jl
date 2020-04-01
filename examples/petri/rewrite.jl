# -*- coding: utf-8 -*-
using ModelingToolkit
using MacroTools
import MacroTools: postwalk
using Petri
using SemanticModels.PetriModels
using Test

# SIR  <- IR  -> SEIR
#  |       |      |
#  v       v      v
# SIRS <- IRS -> SEIRS

# +
using Catlab.WiringDiagrams
using Catlab.Doctrines
import Catlab.Doctrines.⊗
import Catlab.Graphics: to_graphviz
import Catlab.Graphics.Graphviz: run_graphviz
⊗(a::WiringDiagram, b::WiringDiagram) = otimes(a,b)
import Base: ∘
∘(a::WiringDiagram, b::WiringDiagram) = compose(b, a)
⊚(a,b) = b ∘ a
S, E, I, R, D= Ob(FreeSymmetricMonoidalCategory, :S, :E, :I, :R, :D)
wd(args...) = to_wiring_diagram(args...)

inf  = wd(Hom(:infection, S ⊗ I, I⊗I))
expo = wd(Hom(:exposure, S⊗I, E⊗I))
rec  = wd(Hom(:recovery, I,   R))
wan  = wd(Hom(:waning,   R,   S))

sir_wire  = inf ⊚ (rec ⊗ rec)

sir = model(PetriModel, sir_wire)

dump(sir)

# +
@variables S, E, I, R

dump(S)
# -

sir = Petri.Model([S, I, R], [(I, R), (S+I, 2I)])
sir_model = model(PetriModel, sir)

ir = Petri.Model([S, I, R], [(I, R)])
ir_model = model(PetriModel, ir)

seir = Petri.Model([S, I, R], [(I, R), (S+I, I+E), (E, I)])
seir_model = model(PetriModel, seir)

# +
irs = Petri.Model([S, I, R], [(I, R), (R, S)])
irs_model = model(PetriModel, irs)

# -

sirs = Petri.Model([S, I, R], [(I, R), (S+I, 2*I), (R, S)])
sirs_model = model(PetriModel, sirs)

rule = PetriModels.PetriSpan(sir_model, ir_model, seir_model)
sirs_model′ = PetriModels.pushout(irs_model, sir_model)
@test sirs_model′.model.Δ == sirs_model.model.Δ
seirs = PetriModels.solve(PetriModels.DPOProblem(rule, irs_model))
@test all(Set(seirs.model.Δ) .== Set([(S+I, I+E),
                                      (E, I),
                                      (I, R),
                                      (R, S)]))

l = sir_model
c = ir_model
r = seir_model
c′ = irs_model

l′ = PetriModels.pushout(l, c′)
@test l′.model.Δ == sirs_model.model.Δ
@test PetriModels.dropdown(l,c,l′).model.Δ == c′.model.Δ
@test PetriModels.pushout(r, c′).model.Δ == seirs.model.Δ

function Δ(m::Petri.Model, ctx=:state)
    function updateblock(exp, sym)
        return postwalk(exp) do x
            if typeof(x) == Expr && x.head == :call
                if length(x.args) == 1
                    var = x.args[1]
                    # push!(args, var)
                    e = Expr(sym, :($ctx.$var), 1)
                    # @show "adding guard"
                    if sym == :-=
                        return quote
                            ($ctx.$var > 0 || return nothing ) && $e
                        end
                    end
                    return e
                end
                if length(x.args) >= 1 && x.args[1] == :(*)
                    op = x
                    try
                        # @info "trying"
                        # @show x
                        branch = x.args[3].args[2]
                        # @show branch
                        # @show branch.head
                        # @show branch.args[1]
                        if branch.head == :&&
                            # @info "&& found"
                            op = branch.args[2]
                            # @show op
                            op.args[end] = x.args[2]
                            # @show x
                            return x.args[3]
                        end
                    catch
                        # @info "catching: there was no branch"
                        changevalue = x.args[2]
                        statename = x.args[3].args[1]
                        # e = Expr(sym, statename, changevalue)
                        # return e
                        x.args[3].args[2] = changevalue
                        return x.args[3]
                    end
                end
                if length(x.args) >= 1 && x.args[1] == :(+)
                    # @show x
                    return quote
                        $(x.args[2:end]...)
                    end
                end
            end
        return x
        end
    end

    head(x) = try
        x.head
    catch
        nothing
    end

    function poolconditions(decrements)
        if decrements.head == :block
            steps = postwalk(MacroTools.striplines, decrements).args
            checks = Expr[]
            events = Expr[]
            map(steps) do s
                postwalk(s) do x
                    if head(x) == :&&
                        push!(checks, x.args[1])
                        push!(events, x.args[2])
                    end
                    return x
                end
            end
            decrements = quote $(checks...); $(events...)  end
        end
        return decrements
    end
    δf = map(m.Δ) do δ
        q = quote end
        # input states get decremented
        parents = δ[1]
        children = δ[2]

        exp1 = convert(Expr, parents)
        decrements = updateblock(exp1, :-=) |> poolconditions

        exp2 = convert(Expr, children)
        increments = updateblock(exp2, :+=)

        push!(q.args, decrements)
        push!(q.args, increments)

        sym = gensym("δ")
        @show MacroTools.striplines(q)
        :($sym(state) = $(q) )
    end
end

@show "SIR"
Δ(l.model, :state)
# @show "IR"
# funckit(c, :state)
@show "SEIR"
# funckit(r, :state)

@show "SIRS"
# funckit(l′, :state)
# @show "IRS"
# funckit(c′, :state)
@show "SEIRS"
# funckit(seirs, :state)

exprs = Δ(sirs, :state)
m = Petri.Model([S, I, R], exprs, [
    quote
    λ_2(state) = state.γ * state.I
    end,
    quote
    λ_1(state) = state.β * state.S * state.I / +(state.S, state.I, state.R)
    end,
    quote
    λ_3(state) = state.μ * state.R
    end],
                [
                    quote b_2(state) = state.I > 0 end,
                    quote b_1(state) = state.S > 0 && state.I > 0 end,
                    quote b_3(state) = state.R > 0 end]
                )

# +
mutable struct SIRState{T,F}
    S::T
    I::T
    R::T
    β::F
    γ::F
    μ::F
end

mutable struct ParamSIR{T, P}
    S::T
    I::T
    R::T
    params::P
end
# -

p = Petri.Problem(eval(m), SIRState(100, 1, 0, 0.5, 0.15, 0.05), 150)
#@show Petri.solve(p)

# @show Petri.funckit(Petri.Problem(l, missing, 10), :state)
function test_1()
    no_transitions = Tuple{Operation, Operation}[]
    @variables A, B, C, D
    states = [A, B, C, D]
    l = model(PetriModel, Petri.Model(states, [(A, B)]))
    c = model(PetriModel, Petri.Model(states, no_transitions))
    r = model(PetriModel, Petri.Model(states, [(A, B + C)]))
    rule = PetriModels.PetriSpan(l, c, r)
    c′ = model(PetriModel, Petri.Model(states, [(B, A)]))
    r′ = PetriModels.solve(PetriModels.DPOProblem(rule, c′))
    @test r′.model.Δ == [(A, B+C), (B, A)]

    l′ = PetriModels.pushout(l, c′)
    @test l′.model.Δ == [(A, B), (B, A)]
    @test PetriModels.dropdown(l,c,l′).model.Δ == [(B, A)]
end

function test_2()
    no_transitions = Tuple{Operation, Operation}[]
    @variables A, B, C, D
    states = [A, B, C, D]
    l = model(PetriModel, Petri.Model(states, [(A, B), (B,C)]))
    c = model(PetriModel, Petri.Model(states, no_transitions))
    r = model(PetriModel, Petri.Model(states, [(A, C)]))
    rule = PetriModels.PetriSpan(l, c, r)
    c′ = model(PetriModel, Petri.Model(states, [(C, D)]))
    r′ = PetriModels.solve(PetriModels.DPOProblem(rule, c′))
    @test r′.model.Δ == [(A, C), (C, D)]

    l′ = PetriModels.pushout(l, c′)
    @test l′.model.Δ == [(A, B), (B, C), (C, D)]
    @test PetriModels.dropdown(l,c,l′).model.Δ == [(C, D)]
    @test PetriModels.pushout(rule.r, c′).model.Δ == [(A, C), (C, D)]
end
test_1()
test_2()

exprs2 = Δ(Petri.Model([S,I,R], [(2S+I, 3I)]))

function Λ(m::Petri.Model{G, S, D, L, B}) where {G, S, D, L, B}
    head(x) = try
        x.head
    catch
        nothing
    end
    function ratecomp(exp, ctx)

        args = Dict{Symbol, Int}()
        postwalk(convert(Expr, exp)) do x
            if typeof(x) == Expr && x.head == :call
                if length(x.args) == 1
                    var = x.args[1]
                    args[var] = 1
                    return :($ctx.$var)
                end
                if x.args[1] == :(*)
                    args[var] = x.args[2]
                end
            end
        return x
        end
        return args
    end

    δf = map(enumerate(m.Δ)) do (i, δ)
        # input states are used to calc the rates
        parents = δ[1]

        # exp1 = convert(Expr, parents)
        ctx = :state
        rates = ratecomp(parents, ctx)
        q = :(*())
        map(collect(keys(rates))) do s
            r = rates[s]
            push!(q.args, :($ctx.$s / $r))
        end
        term = :($ctx.params[$i])
        push!(q.args, term)

        sym = gensym("λ")
        @show MacroTools.striplines(q)
        :($sym(state) = $(q) )
    end
end

function funckit(m::Petri.Model)
    return Petri.Model(m.g, m.S, Δ(m), Λ(m), missing)
end

function Petri.eval(m::Petri.Model{G, Z, D, L, Missing}) where {G, Z, D, L}
    Petri.Model(m.g, m.S, eval.(m.Δ), eval.(m.Λ), missing)
end



sir′ = funckit(sir)
m = sir′
m′ = evaluate(m)
@show m′
@show typeof(m′)
p = Petri.Problem(m′, ParamSIR(100, 1, 0, [0.15, 0.55/101]), 250)
soln = Petri.solve(p)
@test soln.S <= 10
@test soln.S + soln.I + soln.R == 101

m′ = evaluate(funckit(sirs))
@show m′
@show typeof(m′)
p = Petri.Problem(m′, ParamSIR(100, 1, 0, [0.15, 0.55/101, 0.15]), 250)
sirs_soln = Petri.solve(p)
@test sirs_soln.S >= 10
@test sirs_soln.S + sirs_soln.I + sirs_soln.R == 101
@show soln
@show sirs_soln
