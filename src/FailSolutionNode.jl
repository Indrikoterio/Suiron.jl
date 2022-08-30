# FailSolutionNode.jl
#
# Solution node for the fail operator.
# This logic operator always fails.
#
# Cleve Lendon   2022

mutable struct FailSolutionNode <: SolutionNode
    goal::Union{Goal, SComplex}
    kb::KnowledgeBase
    parent_solution::SubstitutionSet
    parent_node::Union{SolutionNode, Nothing}
    no_back_tracking::Bool
end

# next_solution
# Params: fail solution node
# Return: substitution set
#         success flag
function next_solution(sn::FailSolutionNode)::Tuple{SubstitutionSet, Bool}
    return sn.parent_solution, false
end
