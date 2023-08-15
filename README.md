# PhylogeneticTrees

[![Build Status](https://github.com/kopperud/PhylogeneticTrees.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/kopperud/PhylogeneticTrees.jl/actions/workflows/CI.yml?query=branch%3Amain)

This module contains a data structure to represent an unrooted phylogenetic tree. The trees are built using two data structures: nodes and branches. Nodes can be degree-2 (knuckles), degree-3 (bifurcating nodes) or degree-1 (leaves). There are two main data types:

Nodes:
- Node name
- inbounds
- outbounds

```julia
struct Node
    name::Int64
    inbounds::Union{Branch, Nothing}
    outbounds::Union{Union{Branch, Nothing}, Union{Branch, Nothing}}
end
```

Branches:
- Inbounds (node)
- Outbounds (node)
- Branch length

```julia
struct Branch
    name::Int64
    source::Union{Node, Nothing}
    destination::Union{Node, Nothing}
    length::Float64
end
```

The idea is that we store the nodes and the branches in a `Tree` object. The `tree` object has two dictionaries:

```julia
struct Tree
    Nodes::Dict{Int64, Node}
    Branches::Dict{Int64, Branch}
end
```

The idea is that we store the nodes and the branches in a `Tree` object. The `tree` object has two dictionaries:

```julia
struct Tree
    Nodes::Dict{Int64, Node}
    Branches::Dict{Int64, Branch}
end
```



The idea is to use the data structure to represent trees, while allowing proposals on the trees to manipulate their branch length and topology. A move on the branch length is simple: change the branch_length field. Asubtree swap is also simple: pick two branches, and swap the outbounds of the branches.
