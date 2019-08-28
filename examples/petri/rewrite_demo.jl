# -*- coding: utf-8 -*-
using ModelingToolkit
using MacroTools
using SemanticModels
using SemanticModels.ModelTools.PetriModels
import MacroTools: postwalk
using Test
using Petri

# +
@variables S, I, I′, R, R′

# rule1 = SI <- SI -> SII
si = model(PetriModel, Petri.Model([S, I, R],
                 [(S+I, 2I)]))

sii = model(PetriModel, Petri.Model([S, I, R],
                  [(S+I,  2I ),
                   (S+I′, 2I′)]
                 ))

sir = model(PetriModel, Petri.Model([S, I, R],
                 [(S+I, 2I), (I,R)]))

# rule2 = I <- I -> IR
i = model(PetriModel, Petri.Model([I′],
                Tuple{Operation,Operation}[]))

ir = model(PetriModel, Petri.Model([I′, R′],
                [(I′, R′)]))

# rule3 = IRI′R′ <- II′ -> II′R

irir = model(PetriModel, Petri.Model([I, I′, R, R′],
                   [(I, R), (I′, R′)]))

ii = model(PetriModel, Petri.Model([I, I′],
                 Tuple{Operation,Operation}[]))
iir = model(PetriModel, Petri.Model([I, I′, R],
                  [(I, R), (I′, R)]))

# +
rule1 = PetriModels.Span(si, si, sii)
siir = PetriModels.solve(PetriModels.DPOProblem(rule1, sir))

rule2 = PetriModels.Span(i, i, ir)
siirr = PetriModels.solve(PetriModels.DPOProblem(rule2, siir))

rule3 = PetriModels.Span(irir, ii, iir)
siir′ = PetriModels.solve(PetriModels.DPOProblem(rule3, siirr))

println(siirr.model.Δ)
println()
println(siir′.model.Δ)

# siirr = Petri.Model([S, I, I′, R, R′],
#                   [(S+I,  2I ),
#                    (S+I′, 2I′),
#                    (I, R),
#                    (I′, R′)]
#                  )

# siir = Petri.Model([S, I, I′, R, R′],
#                   [(S+I,  2I ),
#                    (S+I′, 2I′),
#                    (I, R),
#                    (I′, R)]
#                  )
