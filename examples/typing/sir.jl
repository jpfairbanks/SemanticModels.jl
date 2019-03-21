module test
function sir_ode(du, u, p, t)  
    #Infected per-Capita Rate
    β = p[1]
    #Recover per-capita rate
    γ = p[2]
    
    #Susceptible Individuals
    S = u[1]
    #Infected by Infected Individuals
    I = u[2]
   
    du[1] = -β * S * I
    du[2] = β * S * I - γ * I
    du[3] = γ * I
end

function sir_ode2(du,u,p,t)
    S,I,R = u
    b,g = p
    du[1] = -b*S*I
    du[2] = b*S*I-g*I
    du[3] = g*I
end

using DifferentialEquations

function main()
#Pram = (Infected Per Capita Rate, Recover Per Capita Rate)
pram = [0.1,0.05]
#Initial Prams = (Susceptible Individuals, Infected by Infected Individuals)
init = [0.99,0.01,0.0]
tspan = (0.0,200.0)

sir_prob = ODEProblem(sir_ode, init, tspan, pram)

sir_sol = solve(sir_prob, saveat = 0.1);

parms = [0.1,0.05]
init = [0.99,0.01,0.0]
tspan = (0.0,200.0)
sir_prob2 = ODEProblem(sir_ode2,init,tspan,parms)
sir_sol = solve(sir_prob2,saveat = 0.1)
end

end