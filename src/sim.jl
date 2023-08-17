## simulation functions
export yule3
import Distributions

struct bdsmodel
    λ::Vector{Float64}
    μ::Vector{Float64}
    η::Float64  
end

yule3 = bdsmodel([0.1, 0.2, 0.3], [0.0, 0.0, 0.0], 0.05)
bds3 = bdsmodel([0.1, 0.2, 0.3], [0.05, 0.15, 0.25], 0.05)

export sim_bdshift

##
function sim_bdshift(model::bdsmodel, maxtime::Float64, maxtaxa::Int64)
    tree = Tree()
    left = tree.Root.left
    right = tree.Root.right
    t = 0.0 ## time
    ntaxa = [0]
    state = 1 ## state in the BDS model

    ## Draw two random event times
    ## left
    N = SparseArrays.spzeros(Int64, 3, 3)
    left_bl = 0.0
    sim_inner!(model, tree, tree.Root, N, state, maxtime, ntaxa, maxtaxa, left_bl, t)
    
    ## right
    N = SparseArrays.spzeros(Int64, 3, 3)
    right_bl = 0.0
    sim_inner!(model, tree, tree.Root, N, state, maxtime, ntaxa, maxtaxa, right_bl, t)

    return(tree)
end

export ntaxa, nnodes
function ntaxa(tree::Tree)
    nt = length(tree.Leaves)
    return(nt)
end

function nnodes(tree::Tree)
    nn = length(tree.Nodes)
    return(nn)
end

function sim_inner!(
                    model::bdsmodel, 
                    tree::Tree, 
                    node::T, 
                    N::SparseArrays.SparseMatrixCSC{Int64,Int64},
                    state::Int64,
                    maxtime, 
                    ntaxa::Vector{Int64},
                    maxtaxa, 
                    bl::Float64,
                    t
    ) where {T <: AbstractNode}

    rates = [model.λ[state], model.μ[state], model.η]
    rate = sum(rates)
    scale = 1.0 / rate
    d = Distributions.Exponential(scale)
    event_time = rand(d)
    bl += event_time
    t += event_time

    event_d = Distributions.Categorical(rates ./ sum(rates))
    event_type = rand(event_d)
    #parent_node = t.Branches[branch].inbounds

    if ntaxa[1] < maxtaxa
        if t > maxtime
            addleaf!(tree, node, bl - (t-maxtime), N)
            ntaxa[1] += 1
        else
            if event_type == 2 ## extinction
                addnode!(tree, node, bl, N)
            else
                if event_type == 1 ## speciation
                    addnode!(tree, node, bl, N)
                    new_node = tree.Nodes[tree.nc-1]

                    # Left subtree
                    N = SparseArrays.spzeros(Int64, 3, 3)
                    bl = 0.0
                    sim_inner!(model, tree, new_node, N, state, maxtime, ntaxa, maxtaxa, bl, t)

                    # Right subtree
                    N = SparseArrays.spzeros(Int64, 3, 3)
                    bl = 0.0
                    sim_inner!(model, tree, new_node, N, state, maxtime, ntaxa, maxtaxa, bl, t)
                else ## rate shift
                    possible_states = ones(Float64, 3)
                    possible_states[state] = 0.0
                    newstate_d = Distributions.Categorical(possible_states ./ sum(possible_states))
                    new_state = rand(newstate_d)
                    
                    N[new_state, state] += 1
                    state = new_state

                    sim_inner!(model, tree, node, N, state, maxtime, ntaxa, maxtaxa, bl, t)
                end
            end
        end
    else
        addnode!(tree, node, 0.0, N)
    end
end

export prune_extinct!

function prune_extinct!(
        tree::Tree
    )
#    while nnodes(tree) 
    for (node_idx, node) in tree.Nodes        
        ## remove terminals
        if (node.left == nothing) & (node.right == nothing)
            parent_branch_idx = node.inbounds
            parent_node_idx = tree.Branches[parent_branch_idx].from
            if parent_node_idx != 0 ## if not root
                l = tree.Nodes[parent_node_idx].left
                r = tree.Nodes[parent_node_idx].right
                if l == parent_branch_idx
                    tree.Nodes[parent_node_idx].left = nothing
                elseif r == parent_branch_idx
                    tree.Nodes[parent_node_idx].right = nothing
                else
                    error("asdasd")
                end
            else ## if parent is root
                if tree.Root.left == parent_branch_idx
                    tree.Root.left = nothing
                elseif tree.Root.right == parent_branch_idx
                    tree.Root.right = nothing
                else
                    error("bug here")
                end
            end
            delete!(tree.Nodes, node_idx)
            delete!(tree.Branches, parent_branch_idx)

        ## merge branches for knuckles
        elseif (node.left == nothing) | (node.right == nothing)
            parent_branch_idx = node.inbounds
            parent_node_idx = tree.Branches[parent_branch_idx].from
            if node.left != nothing
                child_branch_idx = node.left
            else
                child_branch_idx = node.right
            end
            
            tree.Branches[child_branch_idx].N += tree.Branches[parent_branch_idx].N
            tree.Branches[child_branch_idx].bl += tree.Branches[parent_branch_idx].bl

            ## TODO: Need to re-assign the outbounds for the parental node
            if parent_node_idx != 0
                    addbranch!(t, n, new_node, bl, N)
                    new_node.inbounds = t.bc
                    n.left = t.bc
                elseif n.right == nothing
                    new_node = addnode!(t)
                    N = SparseArrays.spzeros(Int64, 4,4)
                  #  addbranch!(t, n, new_node, bl, N)
                    new_node.inbounds = t.bc
                    n.right = t.bc
                else
                    error("cant add more than two children")
                end
            end



#            child_node_idx = tree.Branches[child_branch_idx].to

            tree.Branches[child_branch_idx].from = parent_node_idx

            if tree.Nodes[parent_node_idx].left = 
#            if child_node_idx in keys(tree.Leaves)
            ## if child node is leaf
#                tree.Leaves[child_node_idx].inbounds = parent_branch_idx
#            else
            ## if child node is internal
#                tree.Nodes[child_node_idx].inbounds = parent_branch_idx
#            end            
            delete!(tree.Branches, parent_branch_idx)
            delete!(tree.Nodes, node_idx)
        end
    end

    ## check root
    if (tree.Root.left == nothing)
        child_branch_idx = tree.Root.right
        child_node_idx = tree.Branches[child_branch_idx].to

        grandchild_branches = [
                               tree.Nodes[child_node_idx].left,
                               tree.Nodes[child_node_idx].right
                              ]

        for grandchild_branch in grandchild_branches
            tree.Branches[grandchild_branch].from = 0
        end
        delete!(tree.Branches, child_branch_idx)
        tree.Root.left = grandchild_branches[1]
        tree.Root.right = grandchild_branches[2]
    end
end





