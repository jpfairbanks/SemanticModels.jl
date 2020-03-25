using ModelingToolkit
using SemanticModels.ModelTools
using SemanticModels.ModelTools.PetriModels
using SemanticModels.ModelTools.OpenPetris
using SemanticModels.ModelTools.OpenModels
using Petri
MAX_STATES = 100
X = @variables(X[1:MAX_STATES])[1]
STATELOOKUP = Dict(s.op.name=>i for (i,s) in enumerate(X))

#const OpenPetri{V} = OpenModel{V, PetriModel}

Petri.N(s) = 1

SEIRD = Petri.Model(1:5, [
    (X[1]+X[2], X[3]+X[2]),
    (X[3], X[2]),
    (X[2], X[4]),
    (X[2], X[5])
], missing, missing)

flows = Petri.Model(1:3, [
    (X[1], X[4]),
    (X[2], X[5]),
    (X[3], X[6])], missing, missing
)

seirdpetri = OpenModel([1,2,3], PetriModel(SEIRD), [1,2,3])
openflows = OpenModel([1,2,3], PetriModel(flows), [4,5,6])
city = OpenPetris.compose(seirdpetri, openflows)
city³ = compose(city, city, city)
