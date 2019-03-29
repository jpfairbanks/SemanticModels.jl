---
title: 'Simple coalescent model'
permalink: 'chapters/coalescent/intro'
previouschapter:
  url: chapters/phylodynamics
  title: 'Phylodynamic models'
nextchapter:
  url: chapters/coalescent/r
  title: 'R'
redirect_from:
  - 'chapters/coalescent/intro'
---
## Kingman coalescent and the Newick format

Authors:
- Alex Zarebski @aezarebski
- Gerry Tonkin-Hill @gtonkinhill

Date: 2018-10-03

The Kingman coalescent is a stochastic model of genealogies. The model is mathematically convenient (due to some simplifying assumptions it makes). There are numerous extensions to the coalescent, and it is part of the state of the art. One of the significant assumptions made to derive the coalescent is that only a small fraction of the population has been observed. However, it is widely believed that the model is quite robust to deviations to this assumption.

The Newick format is a grammar to represent tree data structures and is one of the established ways to represent genealogies. Wikipedia has an amazingly clear [description](https://en.wikipedia.org/wiki/Newick_format) of this grammar. The following is an example (taken from Wikipedia) of a grammatical sentence.

```
(A:0.1,B:0.2,(C:0.3,D:0.4)E:0.5)F;
```

The components of the Newick grammar are given below (again taken from Wikipedia).

```
Tree: The full input Newick Format for a single tree
Subtree: an internal node (and its descendants) or a leaf node
Leaf: a node with no descendants
Internal: a node and its one or more descendants
BranchSet: a set of one or more Branches
Branch: a tree edge and its descendant subtree.
Name: the name of a node
Length: the length of a tree edge.
```

And the rules for valid combinations of these components are defined by the following rules (again again taken from Wikipedia).

```
Tree → Subtree ";" | Branch ";"
Subtree → Leaf | Internal
Leaf → Name
Internal → "(" BranchSet ")" Name
BranchSet → Branch | Branch "," BranchSet
Branch → Subtree Length
Name → empty | string
Length → empty | ":" number
```

In this notebook we implement the Kingman coalescent and implement some functions for working with trees inspired by Newick format. Newick format is a widely used way to represent tree data structures. Having the genealogy in Newick format makes it easy to read into `ape` --- a popular package in R for working with genealogies --- and use the visualisation functionality it provides.

If you want to translate this code into another language, the essential things that you'll need to do are implement the Kingman coalescent and functions to translate to and from Newick. Hopefully, you are using a language which supports recursion :)