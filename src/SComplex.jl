# SComplex.jl - For complex (compound) terms.
#
# In Suiron, as in Prolog, a complex term consists of a functor
# (which must be an atom), and a list of terms, which are atoms,
# numbers, or logic variables, etc.
#
# Format:   functor(term1, term2, ...)
# Examples: owns(john, house),
#           owns($X, house)
#
# Note: 'complex terms' are also called 'compound terms'.
#
# Cleve Lendon
# 2022

struct SComplex <: Unifiable
    terms::Vector{Unifiable}
    function SComplex(t::Vector{Unifiable})
        return new(t)
    end
end

# make_complex
# Params: array of Unifiable terms
# Return: complex term
function make_complex(terms::Unifiable...)::SComplex
    t::Vector{Unifiable} = [terms...]
    return SComplex(t)
end

error_complex = make_complex(Atom("error"))

# parse_complex - parses a string to produce a complex term.
#
# Example of usage:
#     c = parse_complex("symptom(covid, fever)")
# Important: Backslash is used to escape characters, such as the comma.
# For example:
#     c = parse_complex("punctuation(comma, \\,)")
# The backslash is doubled, because the compiler also interprets
# the backslash.
#
# Params: string representation
# Return: complex term
#         error message
#
function parse_complex(str::String)::Tuple{SComplex, String}

    s = string(strip(str))
    len = length(s)

    if len == 0
        err = format_complex_error("Length of string is 0", s)
        return error_complex, err
    end

    if len > 1000
        err = format_complex_error("String is too long", s)
        return error_complex, err
    end

    first =  s[begin]
    if first == '$' || first == '('
        err = format_complex_error("First character is invalid", s)
        return error_complex, err
    end

    # Get indices.
    left, right, err = indices_of_parentheses(s)
    if length(err) > 0
        return error_complex, err
    end

    if left == -1 # If left is -1, right must also be -1.
        # SComplex term without arguments.
        f = Atom(s)
        return SComplex([f]), ""
    end

    functor = String(strip(s[1: left - 1]))
    args    = String(strip(s[left + 1: right - 1]))
    return parse_functor_terms(functor, args)

end   # parse_complex

# parse_functor_terms - produces a complex term from two string
# arguments, the functor and a list of terms. For example:
#
#     c, err = parse_functor_terms("father", "Anakin, Luke")
# produces
#     father(Anakin, Luke)
#
# Params: functor (string)
#         list of terms (string)
# Return: complex term
#         error
#
function parse_functor_terms(functor::String,
                             str_terms::String)::Tuple{Unifiable, String}

    f = Atom(functor)
    if str_terms == ""
        return SComplex([f]), ""
    end

    unifiables = Vector{Unifiable}([f])

    t, err = parse_arguments(str_terms)
    if length(err) > 0
        return error_complex, err
    end

    append!(unifiables, t)
    return SComplex(unifiables), ""

end # parse_functor_terms


# format_complex_error - formats an error message for SComplex terms.
# Params:
#    msg - error message
#    str - string which caused the error
# Return: formatted error message
function format_complex_error(msg::String, str::String)::String
    return "parse_complex() - $msg: >$str<"
end

# arity - Returns the arity of a complex term.
# address(Tokyo, Shinjuku, Takadanobaba) has an arity of 3.
# Params: complex term
function arity(c::SComplex)::Integer
    return length(c.terms) - 1
end

# get_key - creates a key (functor/arity) for indexing the knowledge base.
# Eg. loves(Chandler, Monica) --> loves/2
# Params:  complex term
# Return:  key as string
function get_key(c::SComplex):String
    arity = length(c.terms) - 1
    functor = c.terms[1].str  # functor is an Atom
    return "$functor/$arity"
end

# get_functor - The functor is the first term: [functor, term1, term2, term3]
# Params: complex term
# Return: functor as Atom
function get_functor(c::SComplex)::Atom
    return c.terms[1]
end

# get_term - Returns the indexed term. Term 1 is the functor.
# No error checking.
# Params: index
# Return: term as unifiable
function get_term(c::SComplex, index::Integer)::Unifiable
    return c.terms[index]
end

# unify - Unifies a complex term with another unifiable expression.
# Params:  complex term
#          other unifiable term
#          substitution set
# Return:  substitution set
#          success/failure flag
function unify(c::SComplex, other::Unifiable,
               ss::SubstitutionSet)::Tuple{SubstitutionSet, Bool}

    other_type = typeof(other)

    if other_type == SComplex
        length_other = length(other.terms)
        if length(c.terms) != length_other
            return ss, false  # fail
        end
        new_ss = ss
        ok = false
        for i in 1:length_other
            term_a = c.terms[i]
            term_b = other.terms[i]
            if typeof(term_a) == Anonymous
                continue
            end
            if typeof(term_b) == Anonymous
                continue
            end

            new_ss, ok = unify(term_a, term_b, new_ss)
            if !ok
                return ss, false
            end
        end  # for
        return new_ss, true
    end

    if other_type == LogicVar
        return unify(other, c, ss)
    end
    if other_type == Anonymous
        return ss, true
    end

    return ss, false

end # unify()

#===============================================================
  get_solver - Returns a solution node for SComplex.
  Params:  goal / complex term
           knowledge base
           parent solution (substitution set)
           parent node
  Return:  solution node
===============================================================#
function get_solver(goal::SComplex, kb::KnowledgeBase,
                    parent_solution::SubstitutionSet,
                    parent_node::Union{SolutionNode, Nothing})::SolutionNode

    # Count the number of rules or facts which match the goal.
    count = get_rule_count(kb, goal)

    # Why is parent_node set to nothing? (below)
    # A Complex term will be matched with the rules in the knowledge
    # base. (A rule will be fetched.) If there is a cut (!) in the rule,
    # it will set the no_back_tracking flag to true for all parent nodes,
    # by iterating back through the parent_node field. It must not iterate
    # past the rule in which it is defined.
    return ComplexSolutionNode(goal, kb, parent_solution,
                               nothing, false, 1, count, nothing)
end

#===============================================================
 recreate_variables - The scope of a logic variable is the rule
 in which it is defined. When the inference engine tries to solve
 a goal, it calls this function to ensure that the variables are
 unique.

 Please refer to LogicVar.jl for a detailed description of this
 function.

 Params:  complex term
          previously recreated variables
 Return:  expression
===============================================================#
function recreate_variables(c::SComplex, vars::NewVars)::Expression
    new_terms = Vector{Unifiable}()
    for i in 1:length(c.terms)
        term = c.terms[i]
        push!(new_terms, recreate_variables(term, vars))
    end
    return SComplex(new_terms)
end

#===============================================================
  replace_variables - replaces variables with their bindings.
  This is required in order to display solutions.

  Params: complex term
          substitution set (contains bindings)
  Return: expression
===============================================================#
function replace_variables(c::SComplex, ss::SubstitutionSet)::Expression
    new_terms, _ = ground_terms(ss, c.terms)
    return SComplex(new_terms)
end

# to_string - Formats a complex term for display.
# Eg: employee(John, president)
# Params: linked list
# Return: string representation
function to_string(cplx::SComplex)::String
    out = ""
    functor = true
    first_term = true
    for term in cplx.terms
        if functor
            out = "$term("
            functor = false
        else
            str = to_string(term)
            if first_term
                out *= str
                first_term = false
            else
                out *= ", $str"
            end
        end
    end
    out *= ")"
    return out
end  # to_string

# For printing complex terms. Eg.: employee(John, president)
function Base.show(io::IO, cplx::SComplex)
    print(io, to_string(cplx))
end

export SComplex, make_complex, parse_complex
