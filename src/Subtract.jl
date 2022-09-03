# Subtract.jl
#
# A built-in function to subtract numbers. Eg.:
#
#   $X = subtract(7, 3, 2),...   # 7 - 3 - 2
#
# Cleve Lendon
# 2022

struct Subtract <: SFunction
    type::Symbol
    terms::Vector{Unifiable}
    function Subtract(t::Vector{Unifiable})
        if length(t) < 2
            throw(ArgumentError("Subtract - requires at least 2 arguments."))
        end
        new(:SUBTRACT, t)
    end
end

# Subtract - a constructor.
# Params: list of Unifiable terms (SNumber)
# Return: subtract predicate
function Subtract(terms::Unifiable...)::Subtract
    t::Vector{Unifiable} = [terms...]
    return Subtract(t)
end

# Subtract - a constructor.
# Params: list of numbers
# Return: subtract predicate
function Subtract(args::Number...)::Subtract
    terms = Vector{Unifiable}()
    for num in args
        if num isa Number
            term = SNumber(num)
        else
            throw(ArgumentError("Subtract - non-number: $num"))
        end
        push!(terms, term)
    end
    return Subtract(terms)
end

#----------------------------------------------------------------
# sr_subtract - Subtracts arguments from the first argument.
# Arguments must be bound to numbers (SNumber).
#
# Params:
#     list of arguments
#     substitution set
# Returns:
#     new unifiable
#     success/failure flag
#
function sr_subtract(arguments::Vector{Unifiable},
                     ss::SubstitutionSet)::Tuple{Unifiable, Bool}

    ground, has_unground = ground_terms(ss, arguments)
    if has_unground
        s = "Subtract - Argument list has unground variable."
        throw(ArgumentError(s))
    end

    arg = ground[1]
    if arg.n isa Number
        diff = arg.n
    else
        throw(ArgumentError("Subtract - non-number: $arg"))
    end

    for (n, arg) in enumerate(ground)
        if n == 1
            continue
        end
        if arg.n isa Number
            diff -= arg.n
        else
            throw(ArgumentError("Subtract - non-number: $arg"))
        end
    end

    return SNumber(diff), true

end # sr_subtract

#===============================================================
  unify - unifies the result of a function with another term,
  usually a variable.

  Params: Subtract predicate
          other unifiable term
          substitution set
  Returns:
          updated substitution set
          success/failure flag
===============================================================#
function unify(s::Subtract, other::Unifiable,
               ss::SubstitutionSet)::Tuple{SubstitutionSet, Bool}
    result, ok = sr_subtract(s.terms, ss)
    if !ok
        return ss, false
    end
    return unify(result, other, ss)
end

#===============================================================
 recreate_variables - The scope of a logic variable is the rule
 in which it is defined. Please refer to LogicVar.jl.

 Params:  built in predicate
          previously recreated variables
 Return:  expression
===============================================================#
function recreate_variables(s::Subtract, vars::DictLogicVars)::Expression
    new_terms = recreate_vars(s.terms, vars)
    return Subtract(new_terms)
end
