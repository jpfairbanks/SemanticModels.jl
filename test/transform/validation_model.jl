
#
# Julia implementation of LSTM/RNN classifier for classifying program
# execution traces. 
# 

#
# Loop to check if packages are installed and install them if not, then 
# import.
# 

using Pkg

using DelimitedFiles
using Flux
using Flux: onehot, throttle, crossentropy, onehotbatch, params, shuffle
using MLDataPattern: stratifiedobs
using Base.Iterators: partition
using Statistics

include("../../src/validation/utils.jl")

#
# Set up inputs for model
#

# Read lines from traces.dat text in to arrays of characters
# Convert to onehot matrices

cd(@__DIR__)

text, alphabet, N = get_data("traces.csv")
stop = onehot('\n', alphabet);


# Partition into batches of subsequences to input to our model

seq_len = 50

Xs = [collect(partition(collect(t), seq_len)) for t in text];
Ys = readdlm("y_results.csv");

# Transform our sequences to one hot matrices, and pad sequences to equal
# lengths.

Xs = [[onehotbatch(x_1, alphabet, '\n') for x_1 in x] for x in Xs];
Xs = [[hcat(x_1,repeat(stop,1,seq_len-size(x_1)[2])) for x_1 in x] for x in Xs];

dataset = [(Xs[i], onehot(Ys[i], unique(Ys))) for i in 1:length(Ys)] |> shuffle;
labels = unique(Ys)
Ys = [onehot(y, labels) for y in Ys];


# There are 972,290 items in our data. We use a train:test split of 90:10

Xs = reshape(Xs, length(Xs));
Ys = reshape(Ys, length(Ys));

(Xtrain, Ytrain), (Xtest, Ytest) = stratifiedobs((Xs, Ys), p=0.9);

train = [(Xtrain[i], Ytrain[i]) for i in 1:length(Ytrain)];
test = [(Xtest[i], Ytest[i]) for i in 1:length(Ytest)];

scanner = Chain(LSTM(length(alphabet), 32), 
				LSTM(32, seq_len), 
				Dense(seq_len, seq_len, σ))
encoder = Dense(seq_len, 2)

function model(x)
  state = scanner.(x)[end]
  Flux.truncate!(scanner)
  softmax(encoder(state))
end

function loss(x, y)
	l = crossentropy(model(x), y)
	return l
end

accuracy(t) = mean(argmax(model(t[1])) == argmax(t[2]))

testacc() = mean(accuracy(t) for t in test)
testloss() = mean(loss(t) for t in test)

opt = ADAM(0.01)
ps = params(model)
evalcb = () -> @show testloss(), testacc()

Flux.train!(loss, ps, train, opt, cb = throttle(evalcb, 10))


