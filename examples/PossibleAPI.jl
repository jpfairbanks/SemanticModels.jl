# -*- coding: utf-8 -*-
# ---
# jupyter:
#   jupytext:
#     text_representation:
#       extension: .jl
#       format_name: light
#       format_version: '1.4'
#       jupytext_version: 1.1.7
#   kernelspec:
#     display_name: Julia 1.0.3
#     language: julia
#     name: julia-1.0
# ---

# # Version 1 API Find and Replace

using SemanticModels.Parsers
using SemanticModels.ModelTools
using SemanticModels.ModelTools.ExpODEModels

funcblock(ex::Expr) = ex.args[2] # returns the block part of a func

mutable struct Definition # adds the def type
    name::Symbol # name of var
    code::Expr # code representation 
end

Definition(name::Symbol) = Definition(name,:()) 

function find(ex::Expr,def::Definition) # collects the rhs for a specific lhs
    try                                 # inplace collection into the Defintion object
        ex.head == :function            # targeted at ode def functions
    catch
        println("Please check that the Expr passed in is a function.")
    end
    
    ex = funcblock(ex)
    
    for line in ex.args
        if typeof(line) == Expr && line.head == :(=) && line.args[1] == def.name
                def.code = line.args[2]
                return def
        end
    end
end

function replace(ex::Expr,def::Definition,replacement::Expr) # replace one rhs for a symbol with another
    try 
        ex.head == :function
    catch
        println("Please check that the Expr passed in is a function.")
    end
        
    func = Expr(:block)
    
    for line in funcblock(ex).args
        if typeof(line) == Expr && line.head == :(=) && line.args[1] == def.name
            line.args[2] = replacement
            push!(func.args,line)
        else
            push!(func.args,line)
        end
    end
    
    ex.args[2] = func
    
    return ex
end

# +
function add(ex::Expr,def::Definition)
    try 
        ex.head == :function
    catch
        println("Please check that the Expr passed in is a function.")
    end
    
    func = Expr(:block)
        
    for line in funcblock(ex).args
        if typeof(line) == Expr && line.head == :(=) && line.args[1] == :du
            push!(func.args,Expr(:(=),def.name,def.code))
            push!(line.args[2].args,def.name)
            push!(func.args,line)  
        else
            push!(func.args,line)
        end
    end
            
    ex.args[2] = func
    
    return ex
    
end

# +
function remove(ex::Expr,def::Definition)
    try 
        ex.head == :function
    catch
        println("Please check that the Expr passed in is a function.")
    end
    
    func = Expr(:block)
        
    for line in funcblock(ex).args
        if typeof(line) == Expr && line.head == :(=) && line.args[1] == :du 
            states = []
            for state in line.args[2].args
                if state != def.name
                    push!(states,state)
                end
            end
            line.args[2].args = states
            push!(func.args,line)
        else
            push!(func.args,line)
        end
    end
            
    ex.args[2] = func
    
    return ex
    
end
# -

# # Start of Actual Workflow

# In this simple example, we are going to show how to extend the the SIS model into the SIR model using SemanticModels.jl. While this may not be a typical process in epidemiological modeling, let's say there arises a situation in which a scientist would like add new states to the model. Using SemanticModels we provide an accessible API to provide this functionality. It seems as though a better method of manipulation would be to just edit the source file itself; however, we believe we are quickly approaching a time where complex system modeling scipts will obfuscate even the simplest of program manipulation tasks.

# The susceptible-infected-susceptible (SIS) model is one of the simplest models that has an endemic equilibrium. Susceptible individuals, S, are infected by infected individuals, I, at a per-capita rate βI, and infected individuals recover at a per-capita rate γ to become susceptible again. An extenstion of this model is the SIR model which adds a new state for the recovered indiviudals after they have recovered from an infection.

# # SIS
#
# $$
# \frac{dS(t)}{dt}  = -\beta S(t) I(t)+\gamma I(t)\\
# \frac{dI(t)}{dt}  = \beta S(t) I(t)- \gamma I(t)\\ 
# $$

# # SIR
# $$
# \frac{dS(t)}{dt}  = -\beta S(t) I(t)\\
# \frac{dI(t)}{dt}  = \beta S(t) I(t)- \gamma I(t)\\
# \frac{dR(t)}{dt}  = \gamma I(t)
# $$

# The first step in program manipulation is to read the models into the SemanticModels' framework which is an extentsion of Julia's AST with extra definitions for program semantics such as function calls, function definitions, varibles, and domain info. This can be completed using `SemanticModels.parsefile` and `SemanticModels.model` functions.

sis = parsefile("epicookbook/src/SISModel.jl");
sis = model(ExpODEModel,sis);

# Since we are interested in changing the definition of the $dS$ term we need to inspect it. To find any functions programmatic definition we can use the `find` function in conjunction with the `Definition` stuct to relate this to other semantic info about its representation. To initialize the `Definition`, we pass the symbol of the varible name we are interested in modifying.

# The `Definition` stuct has the following internal layout where name element refers to the varible name and the code element refers to the `Expr` which is the programmatic definition of the varible. 
#
# ```
# mutable struct Definition 
#     name::Symbol
#     code::Expr 
# end
# ```

dS = Definition(:dS)

find(sis.funcs[1],dS)

# Based on the equations, we know that we need to modify this $dS$ by removing the last $ \gamma I(t)$ which can be done through the `replace` function. We simply pass in the new program definition as an `Expr` in the following format.

f = replace(sis.funcs[1],dS,:(-β * S * I))

find(sis.funcs[1],dS)

# Now that we have the correct definition for $dS$ it is time for us to add the $dR$ state as well as the correct definition for the terms we are interested in which can be accomplished as follows using the `addstate` function.

dR = Definition(:dR,:(γ * I))

sis.funcs[1] = add(sis.funcs[1],dR)

# Now that we have completed the transformations on our model it is time for us to `eval` these changes and run the actual model.

sis.expr

m = eval(sis.expr)

Main.SISModel.main()

# # Version 2 API DSL Representation
# - discussed how this lacks the global state of a model eg function that only returns a print statement 
# - thought it might still be good as a possible future goal since its a epi dsl
# - did not implement read in's into this format

abstract type Type end # the type of model

abstract type Field end # field of model 

abstract type Definition end # the semantic meaning of a value

struct CompartmentalODE <: Type 
    Name::Symbol
end

struct Epidemiology <: Field 
    Name::Symbol
end

mutable struct Model # a collector for general models
    Type::Type
    Domain::Field
    Definitions::Dict{Symbol,Array{T}} where T <: Definition
end

mutable struct State <: Definition
    name::Symbol
    initial::Any
    meaning::String
end

mutable struct Parameter <: Definition
    name::Symbol
    initial::Any
    meaning::String
end

mutable struct Derivative <: Definition
    varible::State
    func::Expr
end

EpiDict = Dict(:States=>Array{State},:Parameters=>Array{Parameter},:Derivatives=>Array{Derivative})

ode = CompartmentalODE(:SIS)

Model(Type::CompartmentalODE,Domain::Epidemiology) = Model(Type, Domain,EpiDict)
