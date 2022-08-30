# CutSolutionNode.jl - Solution node for the :CUT operator (!).
#
# The cut operator stops backtracking. If the goals after a cut
# fails, the inference engine will not backtrack past the cut.
#
# Cleve Lendon
# 2022

mutable struct CutSolutionNode <: SolutionNode
    goal::Union{Goal, SComplex}
    kb::KnowledgeBase
    parent_solution::SubstitutionSet
    parent_node::Union{SolutionNode, Nothing}
    no_back_tracking::Bool
end

# next_solution
# Params: 'cut' solution node
# Return: substitution set
#         success flag
function next_solution(sn::CutSolutionNode)::Tuple{SubstitutionSet, Bool}

    if sn.no_back_tracking
        return sn.parent_solution, false
    end
    sn.no_back_tracking = true

    # Set no_back_tracking on all ancestors.
    parent = sn.parent_node
    while !isnothing(parent)
        set_no_back_tracking(parent)
        parent = get_parent_node(parent)
    end

    return sn.parent_solution, true  # Always succeeds.
end
