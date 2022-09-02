# BIPTemplate
#
# This file is a template for writing built-in predicates (BIP) for Suiron.
#
# Search and replace the string 'BIPTemplate', everywhere it appears,
# with the name of your predicate. Write your predicate specific code
# in the function evaluate(), and change its name to something meaningful.
# Adjust comments appropriately and rename this file.
#
# Cleve Lendon  2022

struct BIPTemplate <: BuiltInPredicate
    type::Symbol
    terms::Vector{Unifiable}
    # Constructor
    # Params: an array of unifiable terms.
    function BIPTemplate(t::Vector{Unifiable})
        if length(t) != 2
            throw(ArgumentError("BIPTemplate - requires 2 arguments."))
        end
        new(:NAME_OF_PREDICATE, t)
    end
end

# make_predicate - Another constructor. Rename this.
# Params: list of Unifiable terms
# Return: built-in predicate struct
function make_predicate(terms::Unifiable...)::BIPTemplate
    t::Vector{Unifiable} = [terms...]
    return BIPTemplate(t)
end  # make_predicate()

#===============================================================
# get_solver - gets a solution node for this predicate.
# Params: built in predicate
#         knowledge base
#         parent solution
#         parent node
# Return: solution node
===============================================================#
function Suiron.get_solver(
                goal::BIPTemplate, kb::KnowledgeBase,
                parent_solution::SubstitutionSet,
                parent_node::Union{SolutionNode, Nothing})::SolutionNode
    return BIPTemplateSolutionNode(goal, kb, parent_solution,
                                   parent_node, false, true)
end

# A solution node holds the current state of the search for a solution.
# It contains the current goal, the number of the last rule fetched
# from the knowledge base, and a substitution set (which represents the
# solution so far).
# Built-in predicates produce only one solution for a given set of
# arguments. The boolean flag 'more_solutions' is set to false after
# the first solution is returned.

mutable struct BIPTemplateSolutionNode <: SolutionNode
    goal::Union{Goal, SComplex}
    kb::KnowledgeBase
    parent_solution::SubstitutionSet
    parent_node::Union{SolutionNode, Nothing}
    no_back_tracking::Bool
    more_solutions::Bool
end

# next_solution() - calls the function evaluate() to evaluate
# the current goal, based on its arguments and the substitution set.
# Params: solution node
# Return:
#    updated substitution set
#    success/failure flag
function Suiron.next_solution(sn::BIPTemplateSolutionNode)::Tuple{SubstitutionSet, Bool}
    if sn.no_back_tracking || !sn.more_solutions
        return sn.parent_solution, false
    end
    sn.more_solutions = false  # Only one solution.
    return evaluate(sn.goal.terms, sn.parent_solution)
end

# evaluate() - Do something with the input and output terms.
# Results should be unified with output terms. See Hyphenate.jl
# in the test folder for reference. Return an updated substitution
# set with the success/failure flag set.
#
# Params:
#      list of arguments
#      substitution set
# Return:
#      updated substitution set
#      success/failure flag
function evaluate(arguments::Vector{Unifiable},
                  ss::SubstitutionSet)::Tuple{SubstitutionSet, Bool}
    return ss, true
end  # evaluate

#===============================================================
 recreate_variables - The scope of a logic variable is the rule
 in which it is defined. Please refer to LogicVar.jl.

 Params:  built in predicate
          previously recreated variables
 Return:  expression
===============================================================#
function Suiron.recreate_variables(bip::BIPTemplate, vars::DictLogicVars)::Expression
    new_terms = Suiron.recreate_vars(bip.terms, vars)
    return BIPTemplate(new_terms)
end
