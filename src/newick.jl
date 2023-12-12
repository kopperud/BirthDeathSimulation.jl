export writenewick
export newick
export node_data
export average_rates

## write a newick file
@doc raw"""
writenewick(filename, tree)

writes a newick file with the rate values as comments

Example:
```julia
using BirthDeathSimulation

λ = [0.1, 0.2]
μ = [0.05, 0.15]
η = 0.01

tree = sim_bdshift(λ, μ, η)

writenewick("/tmp/newick.tre", tree, model)
```
"""
function writenewick(filename::String, tree::Tree, model::bdsmodel)
    newick_string = newick(tree, model)

    open(filename, "w") do io
        write(io, newick_string)
        write(io, "\n")
    end
end

function average_rates(tree::Tree, model::bdsmodel)
    res = Dict()
    for (edge_index, branch) in tree.Branches
        rates = [
            model.λ,
            model.μ,
            model.λ .- model.μ,
            model.μ ./ model.λ
        ]
        for (j, rate) in enumerate(rates)
            x = 0.0
            for (t, state) in zip(branch.state_times, branch.states)
                x += rate[state] * t
            end
            x = x / sum(branch.state_times)
            res[edge_index,j] = x
        end
    end
    return(res)
end

function node_data(tree::Tree, model::bdsmodel)
    avg_rates = average_rates(tree, model)
    res = Dict{Int64,String}()


    for (i, branch) in tree.Branches
        #parent_branch_index = node.inbounds
        N = branch.N
        entries = [Printf.@sprintf "%u" x for x in vcat(N...)]
#        entries = string.(vcat(N...))

        nd = String[]
        append!(nd, ["[&N={"])
        ## this is the bottleneck. Very inefficient to print all the 0's in a sparse matrix
        append!(nd, [join(entries, ",")]) 
        append!(nd, ["},"])

        ## average rates
        append!(nd, ["lambda="])
        append!(nd, [string(avg_rates[i,1])])
        append!(nd, [",mu="])
        append!(nd, [string(avg_rates[i,2])])
        append!(nd, [",r="])
        append!(nd, [string(avg_rates[i,3])])
        append!(nd, [",epsilon="])
        append!(nd, [string(avg_rates[i,4])])
        append!(nd, ["]"])


        res[i] = join(nd)
    end
    return(res)
end

## create a newick string from the data object
function newick(tree::Tree, model::bdsmodel)
    nd = node_data(tree, model)
    desc_branches = get_children(tree, tree.Root)
    
    s = String[]
    append!(s, ["("])
    n = ntaxa(tree)

    for (i, branch) in enumerate(desc_branches)
        if branch.to in keys(tree.Nodes)
            child_node = tree.Nodes[branch.to]
            addinternal!(s, tree, nd, child_node)
        elseif branch.to in keys(tree.Leaves)
            leaf_node = tree.Leaves[branch.to]
            addterminal!(s, tree, nd, leaf_node)
        end

        if i == 1
            append!(s, [","])
        end
    end
    append!(s, ["):0.0;"])
    
    newick = join(s)
    return(newick)
end

function addinternal!(s, tree, nd, node)
    append!(s, ["("])

    desc_branches = get_children(tree, node)

    for (i, branch) in enumerate(desc_branches)
        if branch.to in keys(tree.Nodes)
            child_node = tree.Nodes[branch.to]
            addinternal!(s, tree, nd, child_node)
        elseif branch.to in keys(tree.Leaves)
            leaf_node = tree.Leaves[branch.to]
            addterminal!(s, tree, nd, leaf_node)
        end

        if i == 1
            append!(s, [","])
        end
    end

    bl = tree.Branches[node.inbounds].bl
    append!(s, [")"])
    append!(s, [nd[node.inbounds]])
    append!(s, [":"])
    append!(s, [string(bl)])
end

function addterminal!(s, tree, nd, leaf_node)
    tl = Random.randstring(10)
    bl = tree.Branches[leaf_node.inbounds].bl

    append!(s, [tl])
    append!(s, [nd[leaf_node.inbounds]])
    append!(s, [":"])
    append!(s, [string(bl)])
end

function nnode(data)
    return (size(data.edges)[1]+1)
end

function ntip(data)
    return(length(data.tiplab))
end

function getRoot(edges)
    descendants = Set(edges[:,2])

    for node in edges[:,1]
        if node ∉ descendants
            return(node)
        end
    end
    throw("root not found")
end

