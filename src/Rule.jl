# Rule.jl - defines a rule or a fact.
#
# Rules have the format: head :- body.
# Facts are the same as rules without a body. For example:
#
#   grandfather($G, $C) :- father($G, $A), parent($A, $C).  <-- rule
#   father(john, kaitlyn).                                  <-- fact
#
# Cleve Lendon
# 2022

# head :- body.
struct Rule <: Expression
    head::SComplex
    body::Union{Goal, SComplex, Nothing}
end

# Fact - A constructor.
# A fact is the same as a rule without a body.
# Params: complex term
# Return: fact
function Fact(c::SComplex)::Rule
    return Rule(c, nothing)
end

bad_rule = Rule(error_complex, error_complex)

# parse_rule - creates a fact or rule from a string representation.
# Examples of usage:
#    c, err = parse_rule("male(Harold).")
#    c, err = parse_rule("father($X, $Y) :- parent($X, $Y), male($X).")
# Params: string representation of rule
# Return: rule
#         error message
function parse_rule(str::String)::Tuple{Rule, String}

    s = strip(str)
    len = length(s)

    if len < 4
        err = "parse_rule() - Invalid string. >$s<\n"
        return bad_rule, err
    end

    # Remove final period.
    ch = s[end]
    if ch == '.'
        len = len - 1
        s = s[1:len]
    end
    index_range = findfirst(":-", s)

    if isnothing(index_range)  # Must be a fact (no body).
        c, err = parse_complex(s)
        return Fact(c), err
    else
        index, _ = index_range
        str_head = s[begin: index - 1]
        str_body = s[index + 2: end]

        # Make sure there is not a second ":-".
        index_range = findfirst(":-", str_body)
        if !isnothing(index_range)
            throw(ArgumentError(
              "Rule, parse_rule - Invalid rule.\n$s\n")
            )
        end

        head, err = parse_subgoal(string(str_head))
        if length(err) > 0
            return Fact(head), err
        end

        body, err = generate_goal(string(str_body))
        return Rule(head, body), err
    end

end # parse_rule


#===============================================================
  recreate_variables - creates unique variables whenever the
  inference engine fetches a rule from the knowledge base.

  Rules stored in the knowledge base contain variables which
  have an ID of 0. When a rule is fetched, the variables must
  be recreated, to give each variable a unique ID.

  Please refer to comments in LogicVar.jl

  Params: rule - the rule to be recreated
          vars - previously recreated variables
  Return: expression (new rule)
===============================================================#
function recreate_variables(rule::Rule, vars::NewVars)::Expression
    new_head = recreate_variables(rule.head, vars)
    new_body::Union{Goal, SComplex, Nothing} = nothing
    if !isnothing(rule.body)
        new_body = recreate_variables(rule.body, vars)
        return Rule(new_head, new_body)
    end
    return Rule(new_head, nothing)
end

#===============================================================
  replace_variables - replaces bound variables with their bindings.
  This method is used for displaying final results.
  Params:  rule
           substitution set
  Return:  expression
===============================================================#
function replace_variables(r::Rule, ss::Vector{Unifiable})::Expression
    return replace_variables(r.body, ss)
end # replace_variables()

# get_key - creates a key from the head term for indexing.
# Eg. loves(Chandler, Monica) --> loves/2
# Params: complex term
# Return: key as string
function get_key(rule::Rule)::String
    return get_key(rule.head)
end

# get_head - returns the head of this rule, which is SComplex type.
function get_head(r::Rule)::SComplex
    return r.head
end

# get_body - returns the body of this rule, which is Goal type.
function get_body(r::Rule)::Goal
    return r.body
end

# to_string - Formats a rule for display.
# Eg: grandfather($G, $C) :- father($G, $A), parent($A, $C).
# Params: rule
# Return: string representation
function to_string(r::Rule)::String
    str_head = to_string(r.head)
    if isnothing(r.body)
        return "$str_head."  # This is a fact.
    end
    str_body = to_string(r.body)
    return "$str_head :- $str_body."
end  # to_string


# For printing complex terms. Eg.: employee(John, president)
function Base.show(io::IO, r::Rule)
    print(io, to_string(r))
end

export parse_rule
