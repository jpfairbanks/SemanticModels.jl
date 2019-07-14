# Double Pushout Rewriting
\renewcommand{\hom}[2]{{#1}\rightarrow #2}

Cicala 2019 introducing rewriting in a category of open systems using spans and double pushouts.
This can be readily applied to categories of models where a grammar of rewrite rules can be generated. When implementing this framework of metamodeling, the hardest part is to compute the result of a double push out (DPO).

\begin{align*}
 l \leftarrow & c \rightarrow  r \\
  \downarrow\hspace{1em}  &  \downarrow \hspace{1em} \downarrow   \\
 l' \leftarrow & c' \rightarrow  r' 
\end{align*}

The goal is to compute $r'$ given $l,c,r,c',l'$. In this setting $l,c,r$ is the rule, which is composed of 3 models $l$ is the *old model*, $r$ is the *new model* and $c$ is the *intersection*. Then when we go to apply the rule to an existing model $l'$ we need to compute the model $r'$.

Denote morphisms in this category arrows ie. $c \rightarrow l$.

If we had an algorithm for computing pushouts in the category, then given $c \rightarrow l, c\rightarrow r, c\rightarrow c', l \rightarrow l'$ we could computing $l', r'$. In the use case of model augmentation, one would already know one of $l',r'$ and need to compute the other. Note that spans are reversible, so if you can compute DPOs from $l'$ to $r'$, then you can *reverse* the rule and compute $l'$ from $r'$.


### Petri Net Rewriting

Given a petri net DPO, can we solve for the $r'$?

The desired algorithm is 

1. relabel the states so that the states in the image of $\hom{c}{c'}$ and $\hom{c}{r}$ match.
1. relabel the transitions so that the transitions in the image of $\hom{c}{c'}$ and $\hom{c}{r}$ match.
1. $S_{r'} = S_r \cup S_{c'}$
1. $T_{r'} = T_r \cup T_{c'}$

This algorithm works (not yet proven) for applying a pushout. However, modelers often have $l,c,r$ and $l'$ instead of $c'$. So the last step of the algorithm for DPO rewriting for model augmentation requires the inference of $c'$ from $(l,c,r)$ and $l'$
