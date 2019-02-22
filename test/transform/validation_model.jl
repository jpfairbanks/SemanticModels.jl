
#
# Julia implementation of LSTM/RNN classifier for classifying program
# execution traces. 
# 

#
# Loop to check if packages are installed and install them if not, then 
# import.
# 

using Pkg

packages = ['Flux','DelimitedFiles','MLDataPattern']

for package in packages
    haskey(Pkg.installed(),package) || Pkg.add(package)

using DelimitedFiles
using Flux
using Flux: onehot, throttle, crossentropy, onehotbatch, params, shuffle
using MLDataPattern: stratifiedobs
using Base.Iterators: partition


#
# Set up inputs for model
#

# Read lines from traces.dat text in to arrays of characters
# Convert to onehot matrices

cd(@__DIR__)

text = collect.(readdlm("traces.csv"));
alphabet = [unique(vcat(text...))..., '\n'];
N = length(alphabet)
stop = onehot('\n', alphabet);

# Partition into subsequences to input to our model

seq_len = 50

Xs = [collect(partition(t,seq_len)) for t in text];
Ys = readdlm("y_results.csv");

dataset = [(onehotbatch(x, alphabet, '\n'), onehot(Ys[i], unique(Ys)))
           for i in 1:length(Ys) for x in Xs[i]] |> shuffle

# Pad sequences to equal lengths

Xs = [hcat(x,repeat(stop,1,seq_len-size(x)[2])) for x in first.(dataset)]
Ys = last.(dataset)

# There are 972,290 items in our data. We use a train:test split of 90:10

(Xtrain, Ytrain), (Xtest, Ytest) = stratifiedobs((Xs, Ys), p=0.9)

train = [(Xtrain[i], Ytrain[i]) for i in 1:length(Ytrain)];
test = [(Xtest[i], Ytest[i]) for i in 1:length(Ytest)];

scanner = Chain(Dense(length(alphabet), seq_len, σ), LSTM(seq_len, seq_len))
encoder = Dense(seq_len, 2)

function model(x)
  state = scanner.([x])[end]
  Flux.reset!(scanner)
  softmax(encoder(state))
end

loss(tup) = crossentropy(model(tup[1]), tup[2])

testloss() = mean(loss(t) for t in test)

opt = ADAM(0.01)
ps = params(scanner, encoder)
evalcb = () -> @show testloss()

Flux.train!(loss, ps, train, opt, cb = throttle(evalcb, 10))


