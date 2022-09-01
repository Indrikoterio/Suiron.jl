# Functor.jl
#
# Functor() is a built-in predicate to get the functor and arity
# of a complex term. Eg.:
#
#     functor(boss(Zack, Stephen), $Func, $Arity)
#
# The first term must be the complex term to be tested.
#
# $Func will bind to 'boss' and $Arity will bind to the integer
# 2 (because there are two arguments, Zack and Stephen). Arity
# is optional:
#
#     functor(boss(Zack, Stephen), $Func)
#
# The following goal will succeed.
#
#     $X = boss(Zack, Stephen), functor($X, boss)
#
# The next goal will not succeed, because the arity is incorrect:
#
#     functor($X, boss, 3)
#
# If the second argument has an asterisk at the end, the match will
# test only the start of the string. For example, the following
# will succeed:
#
#     $X = noun_phrase(the blue sky), functor($X, noun*)
#
# TODO:
# Perhaps the functionality could be expanded to accept a regex
# string for the second argument.
#
# Cleve Lendon   2022

struct Functor <: BuiltInPredicate
    type::Symbol
    terms::Vector{Unifiable}
    function Functor(t::Vector{Unifiable})
        len = length(t)
        if len != 2 && len != 3
            throw(ArgumentError("Functor - takes 2 or 3 arguments."))
        end
        new(:FUNCTOR, t)
    end
end

# Functor - A constructor.
# Params: complex term
#         functor (out)
# Return: Functor predicate
function Functor(term::Unifiable, func::Unifiable)::Functor
    args::Vector{Unifiable} = [term, func]
    return Functor(args)
end

# Functor - A constructor.
# Params: complex term
#         functor (out)
#         arity   (out)
# Return: Functor predicate
function Functor(term::Unifiable, func::Unifiable,
                 arity::Unifiable)::Functor
    args::Vector{Unifiable} = [term, func, arity]
    return Functor(args)
end

mutable struct FunctorSolutionNode <: SolutionNode
    goal::Union{Goal, SComplex}
    kb::KnowledgeBase
    parent_solution::SubstitutionSet
    parent_node::Union{SolutionNode, Nothing}
    no_back_tracking::Bool
    more_solutions::Bool
end

# get_solver - gets solution node for Functor predicate.
# Params: Functor predicate
#         knowledge base
#         parent solution
#         parent node
# Return: solution node
function get_solver(goal::Functor, kb::KnowledgeBase,
                    parent_solution::SubstitutionSet,
                    parent_node::Union{SolutionNode, Nothing})::SolutionNode
    return FunctorSolutionNode(goal, kb, parent_solution,
                               parent_node, false, true)
end

#===============================================================
 recreate_variables - The scope of a logic variable is the rule
 in which it is defined. Please refer to LogicVar.jl.

 Params:  built in predicate
          previously recreated variables
 Return:  expression
===============================================================#
function recreate_variables(f::Functor, vars::DictLogicVars)::Expression
    new_terms = recreate_vars(f.terms, vars)
    return Functor(new_terms)
end

# next_solution - calls a function to evaluate the current goal.
# Params: functor solution node
# Return: updated substitution set
#         success/failure flag
function next_solution(sn::FunctorSolutionNode)::Tuple{SubstitutionSet, Bool}
    if sn.no_back_tracking || !sn.more_solutions
        return sn.parent_solution, false
    end
    sn.more_solutions = false  # Only one solution.
    return get_functor_arity(sn.goal.terms, sn.parent_solution)
end

# get_functor_arity - determines the functor and arity of the first
# argument. Binds the functor to the second argument, and the arity
# to the third argument, if there is one. Returns the new substitution
# set and a success/failure flag.
# Params:
#      unifiable terms
#      substitution set
# Return:
#      new substitution set
#      success/failure flag
function get_functor_arity(terms::Vector{Unifiable},
                           ss::SubstitutionSet)::Tuple{SubstitutionSet, Bool}

    num_args = length(terms)
    if num_args < 2 || num_args > 3
        return ss, false
    end

    first, ok = cast_complex(ss, terms[1])
    if !ok
        return ss, false
    end

    functor = get_functor(first)
    str_func = functor.str

    new_ss = ss

    # Get second argument (functor)
    second = terms[2]
    if typeof(second) == Atom
        str = second.str
        len = length(str)
        if str[end] == '*'  # Eg: noun*
            if !startswith(str_func, str[1: end-1])
                return ss, false
            end
        else
            if str_func != str
                return ss, false
            end
        end
    else
        new_ss, ok = unify(second, functor, ss)
        if !ok
            return new_ss, false
        end
    end

    if num_args == 3
        third = terms[3]
        ar = arity(first)
        return unify(third, SNumber(ar), new_ss)
    end

    return new_ss, true

end  # get_functor_arity
