include("petri.jl")

using ModelingToolkit
using Test
@variables S, E, I, R

# SIR  <- IR  -> SEIR
#  |       |      |
#  v       v      v
# SIRS <- IRS -> SEIRS

ir = Petri.Model([S, I, R],
                 [(I, R)],
                 (),
                 ())

sir = Petri.Model([S, I, R],
                 [(I, R), (S+I, 2I)],
                 (),
                 ())

seir = Petri.Model([S, I, R],
                 [(I, R), (S+I, I+E), (E, I)],
                 (),
                 ())

irs = Petri.Model([S, I, R],
                 [(I, R), (R, S)],
                 (),
                 ())

sirs = Petri.Model([S, I, R],
                 [(I, R), (S+I, 2I), (R, S)],
                 (),
                 ())

rule = Petri.Span(sir, ir, seir)
sirs′ = Petri.pushout(irs, sir)
@test sirs′.Δ == sirs.Δ
# seirs = Petri.pushout(irs, seir)
seirs = Petri.solve(Petri.DPOProblem(rule, irs))
@test all(Set(seirs.Δ) .== Set([(S+I, I+E),
                             (E, I),
                             (I, R),
                             (R, S)]))

function test_1()
    @variables A, B, C, D
    states = [A, B, C, D]
    l = Petri.Model(states, [(A, B)], (), ())
    c = Petri.Model(states, [], (), ())
    r = Petri.Model(states, [(A, B + C)], (), ())
    rule = Petri.Span(l, c, r)
    c′ = Petri.Model(states, [(B, A)], (), ())
    r′ = Petri.solve(Petri.DPOProblem(rule, c′))
    @test r′.Δ == [(A, B+C), (B, A)]
end

test_1()
