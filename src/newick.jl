export writenewick
export newick
export node_data

## write a newick file
@doc raw"""
writenewick(filename, tree)

writes a newick file with the rate values as comments

Example:
```julia
using PhylogeneticTrees

λ = [0.1, 0.2]
μ = [0.05, 0.15]
η = 0.01

tree = sim_bdshift(λ, μ, η)

writenewick("/tmp/newick.tre", tree)
```
"""
function writenewick(filename::String, tree::Tree)
    newick_string = newick(tree)

    open(filename, "a") do io
        write(io, newick_string)
        write(io, "\n")
    end
end

function node_data(tree::Tree)
    res = Dict{Int64,String}()
    for (i, branch) in tree.Branches
        #parent_branch_index = node.inbounds
        N = branch.N
        entries = [Printf.@sprintf "%u" x for x in vcat(N...)]
            
        nd = String[]
        append!(nd, ["[&N={"])
        for (i, entry) in enumerate(entries)
            if i > 1
                append!(nd, [","])
            end
            append!(nd, [entry])
        end
        append!(nd, ["}]"])
        res[i] = *(nd...)
    end
    return(res)
end

## create a newick string from the data object
## translated from R-package treeio: https://github.com/YuLab-SMU/treeio/blob/master/R/write-beast.R
function newick(tree::Tree)
    nd = node_data(tree)
    desc_branches = get_children(tree, tree.Root)
    
    s = []
    append!(s, "(")
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
            append!(s, ",")
        end
    end
    append!(s, "):0.0;")
    
    newick = *(s...)
    return(newick)
end

function addinternal!(s, tree, nd, node)
    append!(s, "(")

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
            append!(s, ",")
        end
    end

    bl = tree.Branches[node.inbounds].bl
    append!(s, ")")
    append!(s, nd[node.inbounds])
    append!(s, ":")
    append!(s, string(bl))
end

function addterminal!(s, tree, nd, leaf_node)
    tl = Random.randstring(10)
    bl = tree.Branches[leaf_node.inbounds].bl

    append!(s, tl)
    append!(s, nd[leaf_node.inbounds])
    append!(s, ":")
    append!(s, string(bl))
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

