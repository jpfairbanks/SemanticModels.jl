
#
# Julia implementation of LSTM/RNN classifier for classifying program
# execution traces. 
# 

#
# Loop to check if packages are installed and install them if not, then 
# import.
# 

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

# Read lines from trace_test.dat text in to arrays of characters
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


mod = Chain(Dense(N, 5), softmax)

function forward(trc)
  if is_leaf(trc)
    token = embedding * string(trc.value)
    phrase, crossentropy(mod(token), sent)
  else
    _, sent = tree.value
    c1, l1 = forward(tree[1])
    c2, l2 = forward(tree[2])
    phrase = combine(c1, c2)
    phrase, l1 + l2 + crossentropy(sentiment(phrase), sent)
  end
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


