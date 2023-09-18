## simulation functions
export yule3, bds3
import Distributions
export bdsmodel

struct bdsmodel
    λ::Vector{Float64}
    μ::Vector{Float64}
    η::Float64  
end

yule3 = bdsmodel([0.1, 0.2, 0.3], [0.0, 0.0, 0.0], 0.05)
bds3 = bdsmodel([0.1, 0.2, 0.3], [0.05, 0.15, 0.25], 0.05)

export sim_bdshift

##
function sim_bdshift(model::bdsmodel, maxtime::Float64, maxtaxa::Int64, starting_state::Int64)
    tree = Tree()

    @assert length(model.λ) == length(model.μ)
    @assert starting_state <= length(model.λ)

    n_states = length(model.λ)
    t = 0.0 ## time
    ntaxa = [0]
    #state = 1 ## state in the BDS model

    ## Draw two random event times
    ## left
    N = SparseArrays.spzeros(Int64, n_states, n_states)
    left_bl = 0.0
    states = Int64[]
    state_times = Float64[]
    sim_inner!(model, tree, n_states, tree.Root, N, starting_state, maxtime, ntaxa, maxtaxa, left_bl, states, state_times, t)
    
    ## right
    N = SparseArrays.spzeros(Int64, n_states, n_states)
    right_bl = 0.0
    states = Int64[]
    state_times = Float64[]
    sim_inner!(model, tree, n_states, tree.Root, N, starting_state, maxtime, ntaxa, maxtaxa, right_bl, states, state_times, t)

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
                    n_states::Int64,
                    node::T, 
                    N::SparseArrays.SparseMatrixCSC{Int64,Int64},
                    state::Int64,
                    maxtime, 
                    ntaxa::Vector{Int64},
                    maxtaxa, 
                    b::Float64,
                    states::Vector{Int64}, 
                    state_times::Vector{Float64},
                    t::Float64
    ) where {T <: AbstractNode}

    rates = [model.λ[state], model.μ[state], model.η]
    rate = sum(rates)
    scale = 1.0 / rate
    d = Distributions.Exponential(scale)
    event_time = rand(d)
    b += event_time
    t += event_time

    append!(states, state)
    append!(state_times, event_time)

    event_d = Distributions.Categorical(rates ./ sum(rates))
    event_type = rand(event_d)

    if ntaxa[1] < maxtaxa
        if t > maxtime
            addleaf!(tree, node, b - (t-maxtime), N, states, state_times)
            ntaxa[1] += 1
        else
            if event_type == 2 ## extinction
                addnode!(tree, node, b, N, states, state_times)
            else
                if event_type == 1 ## speciation
                    addnode!(tree, node, b, N, states, state_times)
                    new_node = tree.Nodes[tree.nc-1]

                    # Left subtree
                    Nl = SparseArrays.spzeros(Int64, n_states, n_states)
                    bl = 0.0
                    states = Int64[]
                    state_times = Float64[]
                    sim_inner!(model, tree, n_states, new_node, Nl, state, maxtime, ntaxa, maxtaxa, bl, states, state_times, t)

                    # Right subtree
                    Nr = SparseArrays.spzeros(Int64, n_states, n_states)
                    br = 0.0
                    states = Int64[]
                    state_times = Float64[]
                    sim_inner!(model, tree, n_states, new_node, Nr, state, maxtime, ntaxa, maxtaxa, br, states, state_times, t)
                else ## rate shift
                    possible_states = ones(Float64, n_states)
                    possible_states[state] = 0.0
                    newstate_d = Distributions.Categorical(possible_states ./ sum(possible_states))
                    new_state = rand(newstate_d)
                    
                    N[new_state, state] += 1

                    sim_inner!(model, tree, n_states, node, N, new_state, maxtime, ntaxa, maxtaxa, b, states, state_times, t)
                end
            end
        end
    else
        addnode!(tree, node, 0.0, N, states, state_times)
    end
end

export prune_extinct!

function prune_root!(tree::Tree)
    ## check root
    if (tree.Root.left == nothing) | (tree.Root.right == nothing)
        if tree.Root.left != nothing
            child_branch_idx = tree.Root.left
        elseif tree.Root.right != nothing
            child_branch_idx = tree.Root.right
        else
            error("eherhue")
        end

        child_node_idx = tree.Branches[child_branch_idx].to
        grandchild_branch_indices = [
                                tree.Nodes[child_node_idx].left,
                                tree.Nodes[child_node_idx].right
                                ]

        for branch_index in grandchild_branch_indices
            tree.Branches[branch_index].from = 0
        end

        delete!(tree.Branches, child_branch_idx)
        delete!(tree.Nodes, child_node_idx)
        tree.Root.left = grandchild_branch_indices[1]
        tree.Root.right = grandchild_branch_indices[2]
    end
end

function prune_extinct!(
        tree::Tree
    )
    prune_root!(tree)
    pruned = [1]

    while pruned[end] > 0
        c = 0
        for (node_idx, node) in tree.Nodes        
            ## remove terminals
            if (node.left === nothing) & (node.right === nothing)
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
                c += 1

            ## merge branches for knuckles
            elseif (node.left == nothing) | (node.right == nothing)
                parent_branch_idx = node.inbounds
                parent_node_idx = tree.Branches[parent_branch_idx].from
                if node.left != nothing
                    child_branch_idx = node.left
                elseif node.right != nothing
                    child_branch_idx = node.right
                else
                    error("hello")
                end
                
                tree.Branches[child_branch_idx].N += tree.Branches[parent_branch_idx].N
                tree.Branches[child_branch_idx].bl += tree.Branches[parent_branch_idx].bl
                tree.Branches[child_branch_idx].states = vcat(
                    tree.Branches[child_branch_idx].states,
                    tree.Branches[parent_branch_idx].states
                )
                tree.Branches[child_branch_idx].state_times = vcat(
                    tree.Branches[child_branch_idx].state_times,
                    tree.Branches[parent_branch_idx].state_times
                )

                ## re-assign the outbounds for the parental node
                if parent_node_idx != 0 ## if not root
                    parent_node = tree.Nodes[parent_node_idx]
                    l = parent_node.left
                    r = parent_node.right
                    if l == parent_branch_idx
                        parent_node.left = child_branch_idx
                    elseif r == parent_branch_idx
                        parent_node.right = child_branch_idx
                    else
                        error("asdasd")
                    end
                else ## if parent is root
                    if tree.Root.left == parent_branch_idx
                        tree.Root.left = child_branch_idx
                    elseif tree.Root.right == parent_branch_idx
                        tree.Root.right = child_branch_idx
                    else
                        error("bug here")
                    end
                end
                tree.Branches[child_branch_idx].from = parent_node_idx

                delete!(tree.Nodes, node_idx)
                delete!(tree.Branches, parent_branch_idx)
                c += 1
            end
        end
        append!(pruned, c)
    end

    prune_root!(tree)
end





