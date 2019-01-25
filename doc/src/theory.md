# Semantic Modeling Theory

We can consider three different problems for semantic modeling

1. *Model Modification:* Given a model $M$ and a transformation $T$ construct a
   new model $T(M)$.
2. *Metamodel construction:* Given a set of a possible component models
   $\mathcal{M}$, known independent variables $\mathcal{I}$, and a set of
   desired dependent variables $V$, and a set of rules for combining
   models $R$construct a combination of models $m\in\mathcal{R(M)}$ that takes
   as input $\mathcal{I}$ and evaluates the dependent variables $V$.
3. *Model Validation:* Given a model $M$ and a set of properties $P$ and input
   $x$, determine if the model satisfies all properties $P$ when evaluated on
   $x$
   
A model $M=(D,R,f)$ is a tuple containing a set $D$, called the domain, and a
set $R$, called the co-domain with a function $f:D\mapto R$. If $D$ is the cross
product of sets $D_1 \times D_2 \cdots D_k$ then the and $f = f(x_1\dots x_k)$
where $x$ are the independent variables of $M$. If $R=R_1\times R_2\cdots r_d$
then $R_i$ are the dependent variables of $M$. 

A Modeling framework $(U,M,R)$is a universe of sets $U$, class of models
$\mathcal{M}$, and a set of rules $R$. Such that the domains and co-domains of
all models in $\mathcal{M}$ are elements of $\mathcal{U}$, and the class of
models is closed under composition when the rules are satisfied. If $R(M_1,
\dots M_n)$ then $\odot\left(M_1\dotsM_n\right)\in \mathcal{M}$. Composition of
models is defined as 

$$
  \odot(M_1, \dots, \M_n)=(D_1\times\dots\times D_{n-1},
                           R_1\times\dots\times R_{n-1},  
                           f_n(x_1,\dots x_{n-1})(f_1(x_1),\dots f_{n_1}(x_{n-1}))
$$ 

In order to build a useful DAG, a class of models should contain models such as
constants, identity, projections, boolean logic, arithmetic, and elementary
functions.

We also need to handle the case of model identification. There are certain
models within a framework that are essentially equivalent. For example if $D_1$
and $D_2$ are sets with homomorphism $g:D_2\mapsto D_1$, then $M_1 = (D_1, R, f)
= (D_2, R, f \odot g)$ are equivalent as models. In fact $(D_2, D_1, g)$ should
be included in the class of models in a modeling framework.

We need a good theoretical foundation for proving theorems about manipulating
models and combining them. [Category Theory](@ref Categories for Science) may be
that foundation.
