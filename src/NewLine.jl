# NewLine.jl - Prints out a new line character. The parser recognizes nl.
# For example:
#
#   greeting :- print("Are you OK, world?"), nl.
#
# In a Julia program file, call the function NL() to output a new line.
# The above rule could be written as:
#
#     msg  = Atom("Are you OK, world?")
#     pr   = suiron_print(msg)
#     body = And(pr, NL())
#     head = Complex{Atom("greeting")}
#     rule = Rule(head, body)
#
# Cleve Lendon 2022

struct NL <: BuiltInPredicate
    type::Symbol
    terms::Vector{Unifiable}
    function NL()
        new(:NL, [])
    end
end

mutable struct NLSolutionNode <: SolutionNode
    goal::Union{Goal, SComplex}
    kb::KnowledgeBase
    parent_solution::SubstitutionSet
    parent_node::Union{SolutionNode, Nothing}
    no_back_tracking::Bool
    more_solutions::Bool
end

# get_solver - gets solution node for New Line predicate.
# Params: New Line predicate
#         knowledge base
#         parent solution
#         parent node
# Return: solution node
function get_solver(goal::NL, kb::KnowledgeBase,
                    parent_solution::SubstitutionSet,
                    parent_node::Union{SolutionNode, Nothing})::SolutionNode
    return NLSolutionNode(goal, kb, parent_solution,
                          parent_node, false, true)
end

# next_solution - prints out a new line character
# Params: new line solution node
# Return:
#    updated substitution set
#    success/failure flag
function next_solution(sn::NLSolutionNode)::Tuple{SubstitutionSet, Bool}
    if sn.no_back_tracking || !sn.more_solutions
        return sn.parent_solution, false
    end
    sn.more_solutions = false  # Only one solution.
    print("\n")
    # No changes to substitution set. Never fails.
    return sn.parent_solution, true
end
