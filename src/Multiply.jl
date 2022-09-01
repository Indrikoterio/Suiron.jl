# Multiply.jl
#
# A built-in function to multiply numbers. Eg.:
#
#  $X = multiply(7, 3, 2),...
#
# Cleve Lendon
# 2022

struct Multiply <: SFunction
    type::Symbol
    terms::Vector{Unifiable}
    function Multiply(t::Vector{Unifiable})
        if length(t) < 2
            throw(ArgumentError("Multiply - requires at least 2 arguments."))
        end
        new(:MULTIPLY, t)
    end
end

# Multiply - a constructor.
# Params: list of Unifiable terms (SNumber)
# Return: multiply predicate
function Multiply(terms::Unifiable...)::Multiply
    t::Vector{Unifiable} = [terms...]
    return Multiply(t)
end

# Multiply - a constructor
# Params: list of numbers
# Return: multiply predicate
function Multiply(args::Number...)::Multiply
    terms = Vector{Unifiable}()
    for num in args
        if num isa Number
            term = SNumber(num)
        else
            throw(ArgumentError("Multiply - non-number: $num"))
        end
        push!(terms, term)
    end
    return Multiply(terms)
end

#----------------------------------------------------------------
# sr_multiply - Multiplies all arguments together.
# Arguments must be bound to numbers (SNumber).
#
# Params:
#     list of arguments
#     substitution set
# Returns:
#     new unifiable
#     success/failure flag
#
function sr_multiply(arguments::Vector{Unifiable},
                     ss::SubstitutionSet)::Tuple{Unifiable, Bool}

    ground, has_unground = ground_terms(ss, arguments)
    if has_unground
        s = "Multiply - Argument list has unground variable."
        throw(ArgumentError(s))
    end

    arg = ground[1]
    if arg.n isa Number
        total = arg.n
    else
        throw(ArgumentError("Multiply - non-number: $(arg.n)"))
    end
    for (n, arg) in enumerate(ground)
        if n == 1
            continue
        end
        if arg.n isa Number
            total *= arg.n
        else
            throw(ArgumentError("Multiply - non-number: $(arg.n)"))
        end
    end
    return SNumber(total), true

end # sr_multiply

#===============================================================
 recreate_variables - The scope of a logic variable is the rule
 in which it is defined. Please refer to LogicVar.jl.

 Params:  built in predicate
          previously recreated variables
 Return:  expression
===============================================================#
function recreate_variables(m::Multiply, vars::DictLogicVars)::Expression
    new_terms = recreate_vars(m.terms, vars)
    return Multiply(new_terms)
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
function unify(m::Multiply, other::Unifiable,
               ss::SubstitutionSet)::Tuple{SubstitutionSet, Bool}
    result, ok = sr_multiply(m.terms, ss)
    if !ok
        return ss, false
    end
    return unify(result, other, ss)
end
