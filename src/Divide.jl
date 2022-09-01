# Divide.jl
#
# A built-in function to subtract numbers. Eg.:
#
#   $X = divide(7, 3, 2),...
#
# Cleve Lendon
# 2022

struct Divide <: SFunction
    type::Symbol
    terms::Vector{Unifiable}
    function Divide(t::Vector{Unifiable})
        if length(t) < 2
            throw(ArgumentError("Divide - requires at least 2 arguments."))
        end
        new(:DIVIDE, t)
    end
end

# Divide - a constructor
# Params: list of Unifiable terms (SNumber)
# Return: divide predicate
function Divide(terms::Unifiable...)::Divide
    t::Vector{Unifiable} = [terms...]
    return Divide(t)
end

# Divide - a constructor
# Params: list of numbers
# Return: divide predicate
function Divide(args::Number...)::Divide
    terms = Vector{Unifiable}()
    for num in args
        if num isa Number
            term = SNumber(num)
        else
            throw(ArgumentError("Divide - non-number: $num"))
        end
        push!(terms, term)
    end
    return Divide(terms)
end


#----------------------------------------------------------------
# sr_divide - Divides arguments.
# Arguments must be bound to numbers (SNumber).
#
# Params:
#     list of arguments
#     substitution set
# Returns:
#     new unifiable
#     success/failure flag
#
function sr_divide(arguments::Vector{Unifiable},
                   ss::SubstitutionSet)::Tuple{Unifiable, Bool}

    ground, has_unground = ground_terms(ss, arguments)
    if has_unground
        s = "Divide - Argument list has unground variable."
        throw(ArgumentError(s))
    end

    arg = ground[1]
    if arg.n isa Number
        result = arg.n
    else
        throw(ArgumentError("Divide - non-number: $(arg.n)"))
    end
    for (n, arg) in enumerate(ground)
        if n == 1
            continue
        end
        if arg.n isa Number
            result /= arg.n
        else
            throw(ArgumentError("Divide - non-number: $(arg.n)"))
        end
    end
    return SNumber(result), true

end # sr_divide

#===============================================================
 recreate_variables - The scope of a logic variable is the rule
 in which it is defined. Please refer to LogicVar.jl.

 Params:  built in predicate
          previously recreated variables
 Return:  expression
===============================================================#
function recreate_variables(a::Divide, vars::NewVars)::Expression
    new_terms = recreate_vars(a.terms, vars)
    return Divide(new_terms)
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
function unify(d::Divide, other::Unifiable,
               ss::SubstitutionSet)::Tuple{SubstitutionSet, Bool}
    result, ok = sr_divide(d.terms, ss)
    if !ok
        return ss, false
    end
    return unify(result, other, ss)
end
