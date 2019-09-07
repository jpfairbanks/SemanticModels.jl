using ModelingToolkit
using MacroTools
using SemanticModels
import MacroTools: postwalk
using Test
using Petri

@variables S, I, I′, R, R′

# rule1 = SI <- SI -> SII
si = Petri.Model([S, I, R],
                 [(S+I, 2I)])

sii = Petri.Model([S, I, R],
                  [(S+I,  2I ),
                   (S+I′, 2I′)]
                 )

sir = Petri.Model([S, I, R],
                 [(S+I, 2I), (I,R)])

# rule2 = I <- I -> IR
i = Petri.Model([I′],
                [])

ir = Petri.Model([I′, R′],
                [(I′, R′)])

# rule3 = IRI′R′ <- II′ -> II′R

irir = Petri.Model([I, I′, R, R′],
                   [(I, R), (I′, R′)])

ii = Petri.Model([I, I′],
                 [])
iir = Petri.Model([I, I′, R],
                  [(I, R), (I′, R)])


rule1 = Span(si, si, sii)
siir = solve(DPOProblem(rule1, sir))

rule2 = Span(i, i, ir)
siirr = solve(DPOProblem(rule2, siir))

rule3 = Span(irir, ii, iir)
siir′ = solve(DPOProblem(rule3, siirr))

print(siirr)
print(siir′)

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
