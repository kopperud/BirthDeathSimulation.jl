export addnode!, addbranch!

function addnode!(t::Tree)  
    node = Node(t.nc)
    t.Nodes[t.nc] = node
    t.nc += 1

    return(node)
end

function addnode!(t::Tree, n::Node, bl::Float64)  
    new_node = addnode!(t)

    addbranch!(t, n, new_node, bl)

    
end


function addbranch!(t::Tree, n1::Node, n2::Node, bl::Float64)
    b = Branch(n1.name, n2.name, bl) 

    t.Branches[t.bc] = b
    t.bc += 1
end
