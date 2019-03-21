# Intended Use Cases

Here are some use cases for SemanticModels.jl

Scientific knowledge is richer than the ability to make predictions given data.
Knowledge and understanding provide the ability to reason about novel scenarios. 
A crucial aspect of acquiring knowledge is asking questions about the world and
answering those questions with models.

Suppose the model is  $du/dt = f_p(u,t)$ where $u$ is the observable, $du/dt$ is the derivative, $f$ is a function, $t$ is the time variable, and $p$ is a parameter. 

Scientific knowledge involves asking and answering questions about the model. For example:
1. How does `u` depend on `p`?
2. How does `u` depend on `f`?
3. How does `u` depend on the implementation of `f`?

## Counterfactuals

Scientists often want to run counterfactuals through a model. they have questions like: 

1. What if the parameters were different?
2. What if the functional form of this equation was different?
3. What if the implementation of this function was different?

The "how" questions can be answered by running counterfactuals of the model.
In order to run counterfactuals we need to modify the code. 
The current approach is for scientists to modify code writen by other scientists.
This takes a long time and requires models to be converted from the modeling level to the code level, 
then someone else reads the code and converts it back to the modeling level.

If we could automate these transformations, we could enable scientists to spend more time 
thinking about the science and less time working with code. 

## Model-Code Transformations

There are many places we could modify code in order to give it new features for modeling.

1. Source Code, changing the source files on disk before they are parsed
2. Expressions, after parsing, we could use macros or Meta.parse to get `Expr`s and make new ones to `eval`
3. Type System, using multiple dispatch with new types to get new behavior
4. Overdubbing, Cassette.jl lets you change the definitions of functions with overdub
5. Contextual Tags, Cassette provides a tagging mechanism attach metadata to values
6. Compiler Pass, Cassette lets you implement your own compiler passes

Different code modifications will be easier at different levels of this toolchain.

## Use Cases

1. Answering counterfactuals
2. Instrumenting code to extract additional insight
3. Semantic Model Validation

### Answering Counterfactuals

Scientists want to change 1) parameters, 2) assumptions, 3) functions, or
4) implementations in order to determine their effects on the output of the model.

Note: a paramter is an argument to the model and is intended (by the simulation author)
to be changed by users. An assumption is a value in the code that could be changed,
but is not exposed to the API.

While making accurate predictions of measurable phenomena is a necessary
condition of a scientific knowledge it is not sufficient. Scientists have
knowledge that allows them to reason about novel scenarios and they do this by
speculating about counterfactuals. Thus answering counterfactuals about model codes form a
foundational capability of our system.

### Instrumenting Model Code

In order to get additional insight out of models, we want to add
instrumentation into the bodies of the functions. These instrumented values will be useful
for many purposes. The simplest use is to add instrumentation of additional measurements.
Scientists write code for a specific purposes and do not take the time to report all
possible measurements or statistics in their code. A second scientist who is trying to repurpose
that software will often need to compute different values from the internal state of the algorithm
in order to understand their phenomenon of interest.

A simple example is a model that simulates Lotka-Volterra population dynamics
and reports the average time between local maxima of predator populations. A
second scientist might want to also characterize the variance or median of the
time between local maxima.

### Semantic Model Validation

One could trace the value of variables as the code 
is run in order to build up a distribution of *normal* values that variable takes.
This could be used to learn implied invariants in the code.
Then when running the model in a new context, you could compare the instrumentation
values to these invariants to validate if the model is working
as intended in this new context.

One of the main benefits of mechanistic modeling over statistical modeling is
the generalization of mechanistic models to novel scenarios. It is difficult to
determine when a model is being applied in a novel scenario where we can trust the
output and a novel scenario that is beyond the bounds of the model's capability.
By analyzing the values of the internal variables in the algorithms, we can
determine whether a component of the model is operating outside of the region
of inputs where it can be trusted.

An example of this validation could be constructed by taking a model that uses a
polynomial approximation to compute a function $f(x)$. If this polynomial
approximation has small error on a region of the input space, $R$ then whenever
$x$ is in $R$, we can trust the model. But if we every run the model and
evaluate the approximation on an $x$ outside of this region, we do not know if
the approximation is close, and cannot trust the model. Program analysis can
help scientists to identify reasons to be sceptical of model validity.

