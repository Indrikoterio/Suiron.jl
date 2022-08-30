# Add.jl
#
# A built-in function to add two or more numbers together. Eg.:
#
#   $X = add(7, 3, 2),...
#
# Cleve Lendon
# 2022

struct Add <: SFunction
    type::Symbol
    terms::Vector{Unifiable}
    function Add(t::Vector{Unifiable})
        if length(t) < 2
            throw(ArgumentError("Add - requires at least 2 arguments."))
        end
        new(:ADD, t)
    end
end

# make_add - makes an add predicate.
# Params: list of Unifiable terms (SNumber)
# Return: add predicate
function make_add(terms::Unifiable...)::Add
    t::Vector{Unifiable} = [terms...]
    return Add(t)
end

# make_add - makes an add predicate.
# Params: list of numbers
# Return: add predicate
function make_add(args::Number...)::Add
    terms = Vector{Unifiable}()
    for num in args
        if num isa Number
            term = SNumber(num)
        else
            throw(ArgumentError("Add - non-number: $num"))
        end
        push!(terms, term)
    end
    return Add(terms)
end

#----------------------------------------------------------------
# sr_add - Adds all arguments together.
# Arguments must be bound to numbers (SNumber).
#
# Params:
#     list of arguments
#     substitution set
# Returns:
#     new unifiable
#     success/failure flag
#
function sr_add(arguments::Vector{Unifiable},
                ss::SubstitutionSet)::Tuple{Unifiable, Bool}

    ground, has_unground = ground_terms(ss, arguments)
    if has_unground
        s = "Add - Argument list has unground variable."
        throw(ArgumentError(s))
    end

    sum = 0.0
    for arg in ground
        if arg.n isa Number
            sum += arg.n
        else
            throw(ArgumentError("Add - non-number: $arg"))
        end
    end
    return SNumber(sum), true

end # sr_add

#===============================================================
 recreate_variables - The scope of a logic variable is the rule
 in which it is defined. Please refer to LogicVar.jl.

 Params:  function
          previously recreated variables
 Return:  expression
===============================================================#
function recreate_variables(a::Add, vars::NewVars)::Expression
    new_terms = recreate_vars(a.terms, vars)
    return Add(new_terms)
end

#===============================================================
  unify - unifies the result of a function with another term,
  usually a variable.

  Params:
     other unifiable term
     substitution set
  Returns:
     updated substitution set
     success/failure flag
===============================================================#
function unify(a::Add, other::Unifiable,
               ss::SubstitutionSet)::Tuple{SubstitutionSet, Bool}
    result, ok = sr_add(a.terms, ss)
    if !ok
        return ss, false
    end
    return unify(result, other, ss)
end

export make_add
