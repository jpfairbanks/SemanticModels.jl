# Malaria Example

The following example illustrates how you can ingest two simple scientific models and perform
a metamodeling or model modification task on the using the SemanticModels system to end up with a much more complex system.

Our two models are a Lotka Volterra model to simulate predation and an SIR model to simulate disease spread.
We want to compose these two models together, to produce a new model how predation between birds and mosquitos in a system and the spread of Malaria between mosquitos and susceptible humans affect one another.

The full example notebook can be found at [malaria.jl](examples/html/malaria.html)