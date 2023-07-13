export Node, Branch, Tree

struct Node
    name::Int64
    inbounds::Union{Branch, Nothing}
    outbounds::Union{Union{Branch, Nothing}, Union{Branch, Nothing}}
end

struct Branch
    name::Int64
    source::Union{Node, Nothing}
    destination::Union{Node, Nothing}
    length::Float64
end

struct Tree
    Nodes::Dict{Int64, Node}
    Branches::Dict{Int64, Branch}
end
