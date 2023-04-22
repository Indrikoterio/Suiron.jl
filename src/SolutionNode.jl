# SolutionNode.jl - represents a node in a 'proof tree'.
#
# Complex terms and operators (And, Or, Unify, etc.) implement a
# method called get_solver(), which returns a SolutionNode specific
# to that complex term or operator.
#
# The method next_solution() starts the search for a solution.
# When a solution is found, the search stops. Each node preserves
# its state (goal, rule_number, etc.). Calling next_solution()
# again will continue the search from where it left off.
#
# Cleve Lendon
# 2022

struct BasicSolutionNode <: SolutionNode
    goal::Union{Goal, SComplex}
    kb::KnowledgeBase
    parent_solution::SubstitutionSet
    parent_node::Union{SolutionNode, Nothing}
    no_back_tracking::Bool
    rule_number::Integer
    count::Integer  # counts number of rules/facts
end

# make_solution_node - makes a solution node with the given arguments:
# Params:  goal
#          knowledge base
#          parent solution (substitution set)
#          solution node of parent
# Return: a solution node
function make_solution_node(goal::Union{Goal, SComplex},
                  kb::KnowledgeBase,
                  parent_solution::SubstitutionSet,
                  parent_node::Union{SolutionNode, Nothing})::SolutionNode

    node = BasicSolutionNode(goal, kb, parent_solution,
                             parent_node, false, 0, 0)
    return node
end

# set_no_back_tracking - sets the no_back_tracking flag.
# This flag is used to implement the Cut operator
# Params: solution node
function set_no_back_tracking(sn::SolutionNode)
    sn.no_back_tracking = true
    t = typeof(sn)
    if t == AndSolutionNode || t == OrSolutionNode
        if sn.head_solution_node != nothing
            sn.head_solution_node.no_back_tracking = true
        end
    end
end

# get_parent_node
# Params: solution node
# Return: parent node
function get_parent_node(n::SolutionNode)::Union{SolutionNode, Nothing}
    return n.parent_node
end

# get_child - returns the child node.
# Params: solution node
# Return: child node
function get_child(n::SolutionNode)::Union{SolutionNode, Nothing}
    return n.child
end

