export Node, Branch, Tree, RootNode, Leaf

abstract type AbstractNode end

abstract type AbstractBranch end

## Indexed tree
mutable struct Branch <: AbstractBranch
    from::Union{Int64, Nothing}
    to::Union{Int64, Nothing}
    bl::Float64
    N::SparseArrays.SparseMatrixCSC{Int64, Int64}
    states::Vector{Int64}
    state_times::Vector{Float64}
end

mutable struct Node <: AbstractNode
    name::Int64
    inbounds::Union{Int64, Nothing}
    left::Union{Int64, Nothing}
    right::Union{Int64, Nothing}

    function Node(name::Int64)
        return new(name, nothing, nothing, nothing)
    end
end

mutable struct Leaf <: AbstractNode
    name::Int64
    inbounds::Union{Int64, Nothing}

    function Leaf(name::Int64)
        return new(name, nothing)
    end
end

mutable struct RootNode <: AbstractNode
    name::Int64
    left::Union{Int64, Nothing}
    right::Union{Int64, Nothing}

    function RootNode()
        return new(0, nothing, nothing)
    end
end

mutable struct Tree
    Root::RootNode
    Nodes::Dict{Int64, Node}
    Leaves::Dict{Int64, Leaf}
    Branches::Dict{Int64, Branch}
    nc::Int64
    bc::Int64

    function Tree()
        Nodes = Dict{Int64, Node}()
        Leaves = Dict{Int64, Leaf}()
        Branches = Dict{Int64, Branch}()
        nc = 1 # node counter
        bc = 0 # branch counter

        root = RootNode()
        return new(root, Nodes, Leaves, Branches, nc, bc)
    end
end
