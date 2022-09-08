# TooLong.jl - this predicate sleeps, in order to test the "Time out"
# feature of solve(), in Solutions.jl. The test is in TestSolve.jl.
#
# Note: Because this predicate is defined in the test folder, and not
# in the module Suiron, functions which are defined in Suiron must
# be prefixed with 'Suiron.', or 'sr.'. For example: sr.next_solution()
#
# Cleve Lendon
# 2022

struct TooLong <: sr.BuiltInPredicate
    type::Symbol
    terms::Vector{sr.Unifiable}
    function TooLong()
        new(:TOO_LONG, [])
    end
end

#===============================================================
# get_solver - gets a solution node for this predicate.
# Params: built in predicate
#         knowledge base
#         parent solution
#         parent node
# Return: solution node
===============================================================#
function sr.get_solver(
                 goal::TooLong, kb::sr.KnowledgeBase,
                 parent_solution::sr.SubstitutionSet,
                 parent_node::Union{sr.SolutionNode, Nothing})::sr.SolutionNode
    return TooLongSolutionNode(goal, kb, parent_solution, parent_node, false, true)
end

mutable struct TooLongSolutionNode <: sr.SolutionNode
    goal::Union{sr.Goal, sr.SComplex}
    kb::sr.KnowledgeBase
    parent_solution::sr.SubstitutionSet
    parent_node::Union{sr.SolutionNode, Nothing}
    no_back_tracking::Bool
    more_solutions::Bool
end

# next_solution - calls sleeping_function() which spends time sleeping.
# Params: count solution node
# Return:
#    updated substitution set
#    success/failure flag
function sr.next_solution(tlsn::TooLongSolutionNode)::Tuple{sr.SubstitutionSet, Bool}
    if tlsn.no_back_tracking || !tlsn.more_solutions
        return tlsn.parent_solution, false
    end
    tlsn.more_solutions = false  # Only one solution.
    sleep(10)  # Sleep for 10 seconds
    return tlsn.parent_solution, true
end

# to_string - Converts the TooLong predicate to a string for display.
# This method is useful for diagnostics.
# Params: TooLong predicate
# Return: string representation
function sr.to_string(tl::TooLong)::String
    return "TooLong"
end  # to_string

# For printing this predicate: TOO_LONG()
function Base.show(io::IO, tl::TooLong)
    print(io, "TooLong")
end
