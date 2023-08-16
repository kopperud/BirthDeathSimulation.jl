export Node, Branch, Tree, RootNode

abstract type AbstractNode end

abstract type AbstractBranch end

mutable struct Branch <: AbstractBranch
    #from::Union{N, Nothing}
    from::Union{Int64, Nothing}
    #to::Union{N, Nothing}
    to::Union{Int64, Nothing}
    bl::Float64

    #function Branch{N}(name::Int64, from::N, to::N, bl::Float64) where {N<:AbstractNode}
#    function Branch{N}(name::Int64, from::N, to::N, bl::Float64) 
#        return new{N}(name, from, to, bl)
#    end
end

mutable struct Node
    name::Int64
    inbounds::Union{Int64, Nothing}
    outbounds::Union{Union{Int64, Nothing}, Union{Int64, Nothing}}

    function Node(name::Int64)
        return new(name, nothing, nothing)
    end
end

mutable struct Leaf
    name::Int64
    inbounds::Union{Int64, Nothing}

    function Leaf(name::Int64)
        return new(name, nothing)
    end
end

mutable struct RootNode <: AbstractNode
    name::Int64
    outbounds::Union{Union{Branch, Nothing}, Union{Branch, Nothing}}

    function RootNode()
        return new(0, nothing)
    end
end

mutable struct Tree
    Root::RootNode
    Nodes::Dict{Int64, Node}
    Branches::Dict{Int64, Branch}
    nc::Int64
    bc::Int64

    function Tree()
        Nodes = Dict{Int64, Node}()
        Branches = Dict{Int64, Branch}()
        nc = 1 # node counter
        bc = 1 # branch counter

        root = RootNode()
        return new(root, Nodes, Branches, nc, bc)
    end
end


