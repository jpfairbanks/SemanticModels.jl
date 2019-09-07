using Catlab
using Catlab.WiringDiagrams
using Catlab.Doctrines
using Test
import Catlab.Doctrines: ⊗, id
⊗(a::WiringDiagram, b::WiringDiagram) = otimes(a,b)
import Base: ∘
∘(a::WiringDiagram, b::WiringDiagram) = compose(b, a)
⊚(a,b) = b ∘ a

import Catlab.Graphics: to_graphviz
import Catlab.Graphics.Graphviz: run_graphviz

wd(s::Symbol, a,b) = WiringDiagram(Hom(s, a, b))
id(g::Catlab.Doctrines.FreeSymmetricMonoidalCategory.Ob{:generator}) = id(Ports([g]))

function writesvg(f::Union{IO,AbstractString}, d::WiringDiagram)
    write(f, to_graphviz(d, labels=true)
          |>g->run_graphviz(g, format="svg")
          )
end

#       subroutine sir(S, I, R, beta, gamma, dt)
#         implicit none
#         double precision S, I, R, beta, gamma, dt
#         double precision infected, recovered

#         infected = (-(beta*S*I) / (S + I + R)) * dt
#         recovered = (gamma*I) * dt

#         S = S - infected
#         I = I + infected - recovered
#         R = R + recovered
#       end subroutine sir

# C      program main
# C      double precision, parameter :: S0 = 500, I0 = 10, R0 = 0
# C      double precision, parameter :: beta = 0.5, gamma = 0.3, t = 1
# C
# C      call sir(S0, I0, R0, beta, gamma, t)
# C      end program main

double = Ob(FreeSymmetricMonoidalCategory, :F64)

code = wd(:sir, double⊗double⊗double⊗double⊗double⊗double, double⊗double⊗double)

quote
    infection(β, S, I, R, dt, infected) = begin
        infected = (-(beta*S*I) / (S + I + R)) * dt
    end

    recovery(γ, I, dt) = begin
        recovered = (gamma*I) * dt
    end

    update(S, I, R, infected, recovered) = begin
        S = S - infected
        I = I + infected - recovered
        R = R + recovered
    end

    # updateS(S, infected) = S - infected
    # updateI(I, infected, recovered) = I+infected-recovered
    # updateR(R, recovered) = R+ recovered
end

d2 = double⊗double
d3 = d2 ⊗ double
d4 = d3 ⊗ double
d5 = d4 ⊗ double
d6 = d5 ⊗ double

idd = id(double)

copies = wd(:copies, d3, d6)
copy2 = wd(:copy2, double, d2)
inf = wd(:infection, d5, double)
rec = wd(:recovery, d4, double)
update = wd(:update, d5, d3)
m1 = ((copies ⊗ idd ⊗ idd) ⊚ (idd ⊗ idd ⊗ idd ⊗ inf))
code2 = (m1 ⊗ rec) ⊚ update
swap = braid(Ports([double]), Ports([double]))
# code2 = (idd ⊗ (copy2⊗idd ⊚ (idd⊗swap)) ⊗ idd ⊗ idd) ⊚ m1
sirsiri = (idd ⊗ (copy2⊗idd ⊚ (idd⊗swap))) ⊚ ( copies ⊗ idd)


writesvg("sir_simple_f.svg", code)
writesvg("sir_simple_f_refactored.svg", code2)
