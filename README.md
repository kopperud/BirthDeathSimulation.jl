# BirthDeathSimulation

[![Build Status](https://github.com/kopperud/BirthDeathSimulation.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/kopperud/BirthDeathSimulation.jl/actions/workflows/CI.yml?query=branch%3Amain)

This module contains a data structure to represent a rooted phylogenetic tree in units of time, as well as functions to simulate a tree under the birth-death-shift process, and to write the resulting tree as a newick string. The idea is that we store the nodes and the branches in a `Tree` object. The `Tree` object has three dictionaries and some index counters:
```julia
mutable struct Tree
    Root::RootNode
    Nodes::Dict{Int64, Node}
    Leaves::Dict{Int64, Leaf}
    Branches::Dict{Int64, Branch}
    nc::Int64
    bc::Int64
end
```
The tree is built using two several structs: a `RootNode`, several `Node`s, several `Leaf`s, and `Branch`es. `RootNode` has index 0, and `Node` and `Leaf` have indices 1,2,3 etc. `Branch` starts with index `1` and increments from there.

## Installation
```
using Pkg
Pkg.add(url="https://github.com/kopperud/BirthDeathSimulation.jl")
```

## Create a complete tree
Simulate a complete tree under the birth-death-shift process. First, we load the module, specify our model, and set the simulation conditions
```julia
using BirthDeathSimulation
λ = [0.3, 0.5] ## speciation rates
µ = [0.05, 0.15] ## extinction rates
η = 2.5 ## shift rate
model = bdsmodel(λ, µ, η)

max_time = 25.0
max_taxa = 10_000
starting_state = 1

tree = sim_bdshift(model, max_time, max_taxa, starting_state)
```
This can generate all sorts of trees, including trees where
* no events happened, i.e. a two-taxon tree 
* one of the two lineages descending from the root went extinct
* all lineages went extinct
* the maximum amount of taxa were reached and the simulation was terminated.

Each `Branch` has several objects that record the events on the branch history. With the maatrix `N`, one can count the number of rate shifts that occurred on the branch
```julia
branches = tree.Branches
branches[1].N
```
Each branch also records two vectors `state_times` and an index vector `states`, which can be used to calculate the average branch rate. 
```julia
branches[1].states
branches[1].state_times
```

## Reconstructed tree
To prune the extinct lineages, we can use the following command
```julia
prune_extinct!(tree)
```
This will mutate the object `tree`, by a) removing all extinct lineages, b) collapsing all 2-degree (knuckle) `Node`s such that the reconstructed tree only has 3-degree `Node`s, and c) adding the transition matrices `N` for branches that were concatenated.

## Save to file
To print the newick string, we can do the following
```julia
newick_string = newick(tree, model)
```
In order to write it to a file, we can do this
```julia
writenewick("/tmp/newick.tre", tree, model)
```
