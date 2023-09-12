export addnode!, addbranch!, parent
export addleaf!
export treeheight
export treelength
export get_children

function addnode!(tree::Tree)  
    node = Node(tree.nc)
    tree.Nodes[tree.nc] = node
    tree.nc += 1

    return(node)
end

function addnode!(
        tree::Tree, 
        n::T, 
        bl::Float64, 
        N::SparseArrays.SparseMatrixCSC{Int64,Int64},
        states::Vector{Int64},
        state_times::Vector{Float64}
    ) where {T <: AbstractNode}

    #state_times = Float64[bl]
    #states = Int64[state]
    
    if n.left == nothing
        new_node = addnode!(tree)
        addbranch!(tree, n, new_node, bl, N, states, state_times)
        new_node.inbounds = tree.bc 
        n.left = tree.bc
    elseif n.right == nothing
        new_node = addnode!(tree)
        addbranch!(tree, n, new_node, bl, N, states, state_times)
        new_node.inbounds = tree.bc
        n.right = tree.bc
    else
        error("cant add more than two children") 
    end
end

function addleaf!(tree::Tree)
    leaf = Leaf(tree.nc)
    tree.Leaves[tree.nc] = leaf
    tree.nc += 1

    return(leaf)
end

function addleaf!(
         tree::Tree,
         n::T,
         bl::Float64,
         N::SparseArrays.SparseMatrixCSC{Int64, Int64},
         states::Vector{Int64},
         state_times::Vector{Float64}
        ) where {T <: AbstractNode}

    #state_times = Float64[bl]
    #states = Int64[state]

    if n.left == nothing
        leaf = addleaf!(tree)
        addbranch!(tree, n, leaf, bl, N, states, state_times)
        leaf.inbounds = tree.bc
        n.left = tree.bc
    elseif n.right == nothing
        leaf = addleaf!(tree)
        addbranch!(tree, n, leaf, bl, N, states, state_times)
        leaf.inbounds = tree.bc
        n.right = tree.bc
    else
        error("cant add more than two children")
    end
end



function treelength(tree::Tree)
    tl = 0.0
    for (i, branch) in tree.Branches
        tl += branch.bl
    end
    return(tl)
end

function treeheight(tree::Tree)
    t = [0.0]
    branch_index = tree.Root.left
    treeheight_inner(tree, branch_index, t)
    return(t[1])
end

function treeheight_inner(
    tree::Tree,
    branch_index::Int64,
    t::Vector{Float64}
    )
    branch = tree.Branches[branch_index]
    t[1] += branch.bl
    idx = branch.to

    if idx ∉ keys(tree.Leaves)
        left_branch_index = tree.Nodes[idx].left
        treeheight_inner(tree, left_branch_index, t)
    end
end

function addbranch!(
        tree::Tree,
        n1::T1, 
        n2::T2, 
        bl::Float64, 
        N::SparseArrays.SparseMatrixCSC{Int64, Int64},
        states::Vector{Int64}, 
        state_times::Vector{Float64}
    ) where {T1 <: AbstractNode, T2 <: AbstractNode}
    tree.bc += 1
    #state_times = Float64[bl]
    #states = Int64[state]

    b = Branch(n1.name, n2.name, bl, N, states, state_times) 
    tree.Branches[tree.bc] = b
end

function removenode!(tree::Tree, n::Node)
    ## remove tip

    ## collapse knuckle
end

function parent(tree::Tree, n::Node)
    parent_branch = tree.Branches[n.inbounds]
    parent_node = parent_branch.from
    if parent_node == 0
        res = t.Root
    else   
        res = t.Nodes[parent_node]
    end
    return(res)
end

function get_children(tree::Tree, node::N) where {N <: AbstractNode}
    left_branch_index = node.left
    right_branch_index = node.right

    left_branch = tree.Branches[left_branch_index]
    right_branch = tree.Branches[right_branch_index]

    children = [
        left_branch,
        right_branch
    ]
    return(children)
end
