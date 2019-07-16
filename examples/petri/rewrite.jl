include("petri.jl")

using ModelingToolkit
using MacroTools
import MacroTools: postwalk
using Test

@variables S, E, I, R

# SIR  <- IR  -> SEIR
#  |       |      |
#  v       v      v
# SIRS <- IRS -> SEIRS

ir = Petri.Model([S, I, R],
                 [(I, R)])

sir = Petri.Model([S, I, R],
                 [(I, R), (S+I, 2I)],
                 )

seir = Petri.Model([S, I, R],
                 [(I, R), (S+I, I+E), (E, I)],
                 )

irs = Petri.Model([S, I, R],
                 [(I, R), (R, S)],
                 )

sirs = Petri.Model([S, I, R],
                 [(I, R), (S+I, 2I), (R, S)],
                 )

rule = Petri.Span(sir, ir, seir)
sirs′ = Petri.pushout(irs, sir)
@test sirs′.Δ == sirs.Δ
# seirs = Petri.pushout(irs, seir)
seirs = Petri.solve(Petri.DPOProblem(rule, irs))
@test all(Set(seirs.Δ) .== Set([(S+I, I+E),
                             (E, I),
                             (I, R),
                             (R, S)]))
l = sir
c = ir
r = seir
c′ = irs

l′ = Petri.pushout(l, c′)
@test l′.Δ == sirs.Δ
@test Petri.dropdown(l,c,l′).Δ == c′.Δ
@test Petri.pushout(r, c′).Δ == seirs.Δ

function funckit(m::Petri.Model, ctx=:state)
    function updateblock(exp, sym)
        return postwalk(exp) do x
            if typeof(x) == Expr && x.head == :call
                if length(x.args) == 1
                    var = x.args[1]
                    # push!(args, var)
                    e = Expr(sym, var, 1)
                    @show "adding guard"
                    if sym == :-=
                        return quote
                            $var > 0 && $e
                        end
                    end
                    return e
                end
                if length(x.args) >= 1 && x.args[1] == :(*)
                    @show x
                    op = x
                    try
                        @info "trying"
                        @show x
                        branch = x.args[3].args[2]
                        @show branch
                        @show branch.head
                        @show branch.args[1]
                        if branch.head == :&&
                            @info "&& found"
                            dump(branch)
                            op = branch.args[2]
                            @show op
                            op.args[end] = x.args[2]
                            @show x
                            return x.args[3]
                        end
                    catch
                        @info "catching: there was no branch"
                        @show changevalue = x.args[2]
                        @show statename = x.args[3].args[1]
                        # e = Expr(sym, statename, changevalue)
                        # return e
                        x.args[3].args[2] = changevalue
                        return x.args[3]
                    end
                end
                if length(x.args) >= 1 && x.args[1] == :(+)
                    @show x
                    return quote
                        $(x.args[2:end]...)
                    end
                end
            end
        return x
        end
    end

    δf = map(m.Δ) do δ
        q = quote end
        # input states get decremented
        parents = δ[1]
        children = δ[2]

        exp1 = convert(Expr, parents)
        decrements = updateblock(exp1, :-=)


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
funckit(l, :state)
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

exprs = funckit(sirs, :state)
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

p = Petri.Problem(Petri.eval(m), SIRState(100, 1, 0, 0.5, 0.15, 0.05), 150)
# @show Petri.solve(p)

# @show Petri.funckit(Petri.Problem(l, missing, 10), :state)
function test_1()
    no_transitions = Tuple{Operation, Operation}[]
    @variables A, B, C, D
    states = [A, B, C, D]
    l = Petri.Model(states, [(A, B)])
    c = Petri.Model(states, no_transitions)
    r = Petri.Model(states, [(A, B + C)])
    rule = Petri.Span(l, c, r)
    c′ = Petri.Model(states, [(B, A)])
    r′ = Petri.solve(Petri.DPOProblem(rule, c′))
    @test r′.Δ == [(A, B+C), (B, A)]

    l′ = Petri.pushout(l, c′)
    @test l′.Δ == [(A, B), (B, A)]
    @test Petri.dropdown(l,c,l′).Δ == [(B, A)]
end

function test_2()
    no_transitions = Tuple{Operation, Operation}[]
    @variables A, B, C, D
    states = [A, B, C, D]
    l = Petri.Model(states, [(A, B), (B,C)])
    c = Petri.Model(states, no_transitions)
    r = Petri.Model(states, [(A, C)])
    rule = Petri.Span(l, c, r)
    c′ = Petri.Model(states, [(C, D)])
    r′ = Petri.solve(Petri.DPOProblem(rule, c′))
    @test r′.Δ == [(A, C), (C, D)]

    l′ = Petri.pushout(l, c′)
    @test l′.Δ == [(A, B), (B, C), (C, D)]
    @test Petri.dropdown(l,c,l′).Δ == [(C, D)]
    @test Petri.pushout(rule.r, c′).Δ == [(A, C), (C, D)]
end
test_1()
test_2()

exprs2 = funckit(Petri.Model([S,I,R], [(2S+I, 3I)]))
