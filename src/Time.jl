# Time.jl - This predicate measures the execution time of a goal.
#
# The following example would print out the execution time of
# the qsort predicate in milliseconds.
#
#   ..., time(qsort()),...
#
# Time accepts only one argument, which must be a complex term.
#
# Cleve Lendon  2022

struct Time <: BuiltInPredicate
    type::Symbol
    terms::Vector{Unifiable}
    function Time(t::Vector{Unifiable})
        if length(t) != 1
            throw(ArgumentError("Time - takes 1 argument."))
        end
        arg = t[1]
        if typeof(arg) != SComplex
            throw(ArgumentError("Time - The argument must be a complex term."))
        end
        new(:TIME, t)
    end
end

# Time - a constructor.
# Params: list of terms
# Return: Time predicate
function Time(terms::Unifiable...)::Time
    t::Vector{Unifiable} = [terms...]
    return Time(t)
end

# get_solver - gets solution node for Functor predicate.
# Params: Functor predicate
#         knowledge base
#         parent solution
#         parent node
# Return: solution node
function get_solver(goal::Time, kb::KnowledgeBase,
                    parent_solution::SubstitutionSet,
                    parent_node::Union{SolutionNode, Nothing})::SolutionNode
    return TimeSolutionNode(goal, kb, parent_solution, parent_node)
end

#===============================================================
 recreate_variables - The scope of a logic variable is the rule
 in which it is defined. Please refer to LogicVar.jl.

 Params:  built in predicate
          previously recreated variables
 Return:  expression
===============================================================#
function recreate_variables(t::Time, vars::DictLogicVars)::Expression
    new_terms = recreate_vars(t.terms, vars)
    return Time(new_terms)
end
