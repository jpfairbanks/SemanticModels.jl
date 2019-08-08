# -*- coding: utf-8 -*-
using Catlab
using SemanticModels.ModelTools.ExpODEModels

using Catlab.WiringDiagrams
using Catlab.Doctrines
using Test
import Catlab.Doctrines.⊗
⊗(a::WiringDiagram, b::WiringDiagram) = otimes(a,b)
import Base: ∘
∘(a::WiringDiagram, b::WiringDiagram) = compose(b, a)
⊚(a,b) = b ∘ a

?WiringDiagram

# +
# Generators
A, B, C, D = Ob(FreeSymmetricMonoidalCategory, :A, :B, :C, :D)
f = WiringDiagram(Hom(:f,A,B))
g = WiringDiagram(Hom(:g,B,A))


@test nboxes(f) == 1
@test boxes(f) == [ Box(Hom(:f,A,B)) ]
@test nwires(f) == 2
@test Ports([:A]) == Ports([:A])
@test WiringDiagram(Hom(:f,A,B)) == WiringDiagram(Hom(:f,A,B))
# -

Hom(:h, otimes(A,B), C)

Hom(:f, A, B) ⊗ Hom(:g, B, C)

Hom(:g, B, C) ∘ Hom(:f, A, B)

@test_throws SyntaxDomainError Hom(:g, B, C) ⊚ Hom(:f, A, B) 

@test compose(Hom(:f, A, B), Hom(:g, B, C)) == ⊚(Hom(:f, A,B), Hom(:g, B, C))

h = WiringDiagram(Hom(:h, otimes(A,B), C)) 

@test compose(otimes(f,g), h) == (f⊗g) ⊚ h

# Scientists will draw diagrams that capture the behavior of physical systems. These diagrams are often structured according to what category theorist call a *Symmetric Monoidal Category* these diagrams have wires that represent *things* and boxes that represent *events*, and there are rules for composing little diagrams to make big ones.
#
# 1. If the output wires of A are the same type as the input wires of B, you can combine them in series to make $B \circ A$.
# 2. If the A and B are diagrams, you can combine them in parallel them to make $A\otimes B$
# 3. If two wires cross, you can un cross them.
#
# Rule 1 is composition, Rule 2 is the monoidal product $\otimes$ these diagrams arose from Feynman Diagrams where the "in parallel" rule is tensor product of vector spaces. And Rule 3 is the symetry condition. These are abbreviated SMC for *Categorie, Monoidal, Symetrique*
#
# An SMC is called *finitely generated* if there are a finite number of objects (wires) and events (morphisms) that can be composed freely.

# Generators
S, E, I, R, D= Ob(FreeSymmetricMonoidalCategory, :S, :E, :I, :R, :D)

# We are going to model some infectious processes in epidemiology as wiring diagrams and then show how to convert these process models into differential equations and solve them.

# A person could get sick spontaniously
ens = Hom(:ensicken, S, I)

#And sick people recover spontaneously too.
recovery = Hom(:recover, I, R)

# We can compose these to make a diagram of illness
compose(WiringDiagram(ens), WiringDiagram(recovery))

# But that isn't how people get sick usually, they pick it up from someone else who has already been infected. The monoidal product for our case is going to be $A \otimes B$ means a person in state A and a person in state B as an unordered collection so that $A\otimes B = B\otimes A$ and $A\otimes B\otimes C$ is an A, a B, and a C in any order.

infecting = Hom(:infection,S ⊗ I, I⊗I)

inf = WiringDiagram(infecting)
rec = WiringDiagram(Hom(:recovery,I, R))

# We are going to use $\circ$ to mean mathematical composition in the normal ordering $f\circ g (x)= g(f(x))$ and $f \circledcirc g = g(f)$ for the ordering that makes more sense 
#
# If you try to compose these diagrams you will get a domain error because we have $S \otimes I \rightarrow I\otimes I \circledcirc I\rightarrow R$ which doesn't satisfy the consistency requirement of function composition that is $A\rightarrow B \circledcirc B \rightarrow C = A\rightarrow C$.  
#

SIR = inf ⊚ rec

# We can introduce another diagram to our set of generators to fix it.

SIR = inf ⊚ WiringDiagram(Hom(:recover, I⊗I, R⊗R))

# How would you interperet the diagram on the right above?
#
# It is a single event that takes to sick people and creates two healthy people. What medical mystery is this? This doesn't correspond to our understanding of the domain. There is no epidemiological meaning to the concept of `Hom(:recover, I⊗I, R⊗R)`. Recovery is an event that happens to individuals, not pairs of individuals, but we if we have two people that need to recover, we can have them recover in parallel.

SIR = inf ⊚ (rec ⊗ rec)

# What we have seen so far represents a disease where you get catch the disease, becaoming infectious, and then recover. That makes sense for chicken pox. 
# But what about diseases like the common cold, where you can get the disease again? Our example of the SEIR process can be composed with the waning of immunity $wan: R \rightarrow S$. 

wan = WiringDiagram(Hom(:waning,R, S))
SIRS = SIR ⊚ (wan⊗wan)

# When combining diagrams, composition only checks that that inputs and outputs of the things you are composing match. These are called *Domain* and *Codomain*. We can see that the SIR model is a map from $S\otimes I \rightarrow R\otimes R$. Which means it takes two sucesptible people to two recovered people. The SIRS model is $SIRS: S\otimes I \rightarrow S\otimes S$ Which means we could compose the SIRS model with another model that expected two suceptible people.

dom(SIR), codom(SIR)

dom(SIRS), codom(SIRS)

# Lets add a new concept to our SMC representation of the disease. Diseases like the flu have an exposed state, where you can be exposed but not yet infectious.

exposure = WiringDiagram(Hom(:exposure, S⊗I, E⊗I))
exposure ⊚ WiringDiagram(Hom(:progression, E⊗I, I)) ⊚ rec 

# The previous string diagram introduces an element $progression$ that represents the progression of an exposed person into the infectious stage of the disease. This progression element that we introduced is not consitant with the domain understanding of the scientist. As defined above, progression  keeps track of the pairs $S\otimes I \rightarrow E\otimes I$ which represents the person who exposed you. In most diseases, the infectious pathogen is homogeneous meaning that it does not matter who infected you. In this case, it is not meaningful to define progression as taking exposure pairs together.
#
# We want to draw a diagram that doesn't remember these exposure pairs. 
#
# Diagramatic reasoning is like static typing in programming languages. To draw a diagram, we need to match up the domains and codomains of the boxes. This is why the rules of SMC are so useful for modeling processes, we need the ingredients to match the products of each component. This gives us a finite number of ways to combine finitely generated systems. A human designer can solve the SMC compositional constraints in their head and thus generate candidate wiring diagrams.
#
# (Footnote: If you were studying the evolution of a virus and wanted to track these exposure lineages you would have this concept in your domain ontology.)

# The Diagram $(E\rightarrow I) \otimes (I\rightarrow R)$ says that the progression from E to I is independent of the recovery from infected to recovered status. This captures our domain ontology concepts that these phenomena are independent, but combine using the tensor product of "happen independently" in a compositional way.

# by tensoring the recovery and waning processes and then composing with the exposuring process, we get a model that forgets the pairing between the person who exposed you.
#
# $S\otimes I \rightarrow E\otimes I \rightarrow (E \otimes I \rightarrow I \otimes R)$
# which is equivalent to 
#
# $S\otimes I \rightarrow I \otimes R$ or are pair of (suceptible, infected) goes to a pair (infected, recovered). Because the category is monoidal, the order doesn't matter so this model is black-box equivalent to $(S\rightarrow I) \otimes (I \rightarrow R)$. The SMC does not track the identity of the 

seir = exposure ⊚ (WiringDiagram(Hom(:progression, E, I)) ⊗ rec)

dom(seir), codom(seir)

# If you compose diagrams in the wrong order, the software tells you about the mistake. These checking rules are easy to understand and easy to implement. Which makes them great for representing models. 

seir ⊚ wan

# the types didn't match, we need to do something with that infected wire
seirs = seir ⊚ (rec⊗wan)

# This process is capturing a determinstic infectious disease where each event happens between a pair of people with certainty in a synchronous way . We are able to describe the process of exposure, progression, recovery, and waning of immunity in a deterministic and chronological language, but then translate this string diagram into a petri net that captures the probabilistic nature of compartmental epidemiology models.
#
# String diagrams allow scientists to describe their models in the process model, then functorially map them to categories that capture the dynamics of populations undergoing the process in bulk. We can blackbox those categories into differential equations or stochastic agent based models in order to actually calculate the answers to questions about these systems.
#
# (Footnote: SMC categories allow you to slide boxes along wires to deform the temporal ordering so even though the description we gave is synchronous, you can reorder events that don't share wires.)

# In order to use SMC string diagrams as a modeling framework in the context of SemanticModels, we need to write a lens between string diagrams and Julia programs.

#what is a diagram? 
boxes(seirs)

# +
# Generators
S, E, I, R, D= Ob(FreeSymmetricMonoidalCategory, :S, :E, :I, :R, :D)

infecting = Hom(:infection, S ⊗ I, I⊗I)

inf  = WiringDiagram(infecting)
expo = WiringDiagram(Hom(:exposure, S⊗I, E⊗I))
rec  = WiringDiagram(Hom(:recovery, I,   R))
wan  = WiringDiagram(Hom(:waning,   R,   S))

si    = WiringDiagram(Hom(:infection,   S⊗I, I⊗I))
se    = WiringDiagram(Hom(:exposure,    S⊗I, E⊗I))
prog  = WiringDiagram(Hom(:progression, E,   I))
fatal = WiringDiagram(Hom(:die,  I, D))
rip   = WiringDiagram(Hom(:rest, D, D))

sir    = si    ⊚ (rec   ⊗ rec)
seir   = se    ⊚ (prog  ⊗ rec)
seirs  = seir  ⊚ (wan   ⊗ wan)
seird  = seir  ⊚ (fatal ⊗ WiringDiagram(Hom(:id, R, R)))
seirds = seird ⊚ (rip   ⊗ wan)

odeTemplate(seirds)
