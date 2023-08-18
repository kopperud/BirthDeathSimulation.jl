export Node, Branch, Tree, RootNode, Leaf

export Node2, Branch2, Tree2, RootNode2, Leaf2

abstract type AbstractNode end
abstract type AbstractNode2 end

abstract type AbstractBranch end
abstract type AbstractBranch2 end

## Indexed tree
mutable struct Branch <: AbstractBranch
    from::Union{Int64, Nothing}
    to::Union{Int64, Nothing}
    bl::Float64
    N::SparseArrays.SparseMatrixCSC{Int64, Int64}

#    function Branch(name, from, to, bl)
#        new(branch, from, to, bl, spzeros(4,4))
#    end
    #function Branch{N}(name::Int64, from::N, to::N, bl::Float64) where {N<:AbstractNode}
#    function Branch{N}(name::Int64, from::N, to::N, bl::Float64) 
#        return new{N}(name, from, to, bl)
#    end
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



### Non-indexed tree
mutable struct Node2{B<:AbstractBranch2} <: AbstractNode2
    inbounds::Union{B, Nothing}
    outbounds::Union{Union{B, Nothing}, Union{B, Nothing}}

    function Node2{B}() where {B <: AbstractBranch2}
        return new(nothing, nothing)
    end
    #Incomplete() = new()    
end

mutable struct RootNode2{B <: AbstractBranch2} <: AbstractNode2
    outbounds::Union{Union{B, Nothing}, Union{B, Nothing}}

    function RootNode2{B}() where {B <: AbstractBranch2}
        return new(nothing)
    end
end

mutable struct Branch2 <: AbstractBranch2
    from::Union{RootNode2, Nothing}
    #to::Union{N, Nothing}
    to::Union{Node2, Nothing}
    bl::Float64

    function Branch2(from, to, bl)
        return new(from, to, bl)
    end
end

mutable struct Leaf2
    inbounds::Union{Branch2, Nothing}

    function Leaf2()
        return new(nothing)
    end
end

mutable struct Tree2
    Root::RootNode2

    function Tree2()
        root = RootNode2()
        return new(root)
    end
end

