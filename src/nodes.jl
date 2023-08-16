export addnode!, addbranch!, parent

function addnode!(t::Tree)  
    node = Node(t.nc)
    t.Nodes[t.nc] = node
    t.nc += 1

    return(node)
end

function addnode!(t::Tree, n::N, bl::Float64) where {N <: AbstractNode}
    new_node = addnode!(t)
    addbranch!(t, n, new_node, bl)
    new_node.inbounds = t.bc-1 #t.Branches[t.bc-1]
end

function addbranch!(t::Tree, n1::N, n2::Node, bl::Float64) where {N <: AbstractNode}
    b = Branch(n1.name, n2.name, bl) 

    t.Branches[t.bc] = b
    t.bc += 1
end

function removenode!(t::Tree, n::Node)
    ## remove tip

    ## collapse knuckle
end

function parent(t::Tree, n::Node)
    parent_branch = t.Branches[n.inbounds]
    parent_node = parent_branch.from
    if parent_node == 0
        res = t.Root
    else   
        res = t.Nodes[parent_node]
    end
    return(res)
end
