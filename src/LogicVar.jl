# LogicVar.jl - Struct and functions related to logic variables.
#
# Prolog variables are represented by strings which begin with
# a capital letter, eg. X, Y, Noun. In a Suiron source program,
# a logic variable begins with a dollar sign and a letter:
# $X, $Y, $Noun.
#
# Note: In the Go implementation of Suiron, a logic variable is
# instantiated in Go-source code as follows:
#
#    X, _ := LogicVar("$X")
#
# This is a problem for Julia, because the compiler interprets
# $X within a string as the variable X (which we are defining).
#    X = LogicVar("$X")
# will cause the compiler to throw an error:
#    LoadError: UndefVarError: X not defined
#
# To get around this problem, the dollar sign can be escaped
# with a backslash:
#    X = LogicVar("\$X")
# or the dollar sign can be dropped for LogicVar:
#    X = LogicVar("X")
#
# For other parsing functions, such as parse_complex(), a prefix
# for logic variables cannot be omitted. The dollar sign must be
# escaped with a backslash:
#    parse_complex("father(\$X, Luke)")
# Alternatively, the percent sign can be substituted:
#    parse_complex("father(%X, Luke)")
#
# Cleve Lendon
# 2022

next_var_id = 0 # next ID number for logic variables

const INVALID_VAR = "Invalid logic variable name: "

struct LogicVar <: Unifiable

    id::Integer
    name::String
    name_id::String

    function LogicVar(var_name::String, var_id = 0)

        name = strip(var_name)
        if length(name) < 1
            throw(ArgumentError(INVALID_VAR * "$name"))
        end

        first = name[begin]
        if isletter(first)
            if var_id == 0
                return new(var_id, name, name)
            end
            return new(var_id, name, name * "_$var_id")
        elseif first == '$' || first == '%'
            if length(name) < 2
                throw(ArgumentError(INVALID_VAR * "$name"))
            end
            second = name[2]
            if isletter(second)
                name2 = name[2:end]
                if var_id == 0
                    return new(var_id, name2, name2)
                end
                return new(var_id, name2, name2 * "_$var_id")
            end
        end
        throw(ArgumentError(INVALID_VAR * "$name"))
    end
end

#===============================================================
  unify - Unifies a logic variable with another unifiable
  expression (atom, logic variable, complex term, etc.), if
  the variable is not already bound. A substitution set records
  the bindings made while searching for a solution.

  For example, if the source program has: $X = water, then the
  unify method will add [73 : "water"] to the substitution
  set. (The substitution set in keyed by the variable's index
  number, in this case 73.)

  Params: logic variable
          other unifiable
          substitution set
  Return: substitution set
          success flag
===============================================================#
function unify(v::LogicVar, other::Unifiable,
               ss::SubstitutionSet)::Tuple{SubstitutionSet, Bool}

    # LogicVar() creates variables with an ID of 0, but variables
    # are recreated (given a new ID) when a rule is fetched from the
    # knowledge base.
    # If a variable has an ID of 0 here, something was done incorrectly.
    if v.id == 0
        return ss, false
    end

    # A variable unifies with itself.
    if v == other
        return ss, true
    end

    other_type = typeof(other)

    if other_type == LogicVar
        # A variable unifies with itself.
        if v.id == other.id
            return ss, true
        end
    end

    # The unify method of a function evaluates the function, so
    # if the other expression is a function, call its unify method.
    # if other_type == SFunction  <-- doesn't work
    if other isa SFunction
        return unify(other, v, ss)
    end

    (length_src,) = size(ss)

    if v.id <= length_src && isassigned(ss, v.id)
        u = ss[v.id]
        return unify(u, other, ss)  # try again
    end

    length_dst = length_src
    if v.id > length_dst
        length_dst = v.id
    end

    new_ss = Vector{Unifiable}(undef, length_dst)
    copyto!(new_ss, ss)

    new_ss[v.id] = other
    return new_ss, true
end

#===============================================================
  recreate_variables - creates unique variables whenever the
  inference engine fetches a rule from the knowledge base.

  The scope of a logic variable is the rule in which it is
  defined. For example, in the knowledge base we have:

    grandparent($X, $Y) = parent($X, $Z), parent($Z, $Y).
    parent($X, $Y) :- father($X, $Y).
    parent($X, $Y) :- mother($X, $Y).
    mother(Martha, Jackie)
    ... other facts and rules

  When the rule grandparent/2 is fetched from the knowledge base,
  $X, $Y and $Z are created with unique ID numbers. When the rule
  parent/2 is fetched, its $X and $Y variables must be different
  from the $X and $Y in the grandparent rule. In other words, they
  must have different IDs from the previous variables of the same
  name.

  Params: var - the logic variable to be recreated
          vars - dictionary of newly recreated logic vars
  Return: expression (new variable)

  About vars - if the logic variable $X appears in a rule more
  than once, it should only be recreated once. The second $X is
  the same variable. The dictionary vars holds logic variables
  which have already been recreated for the current rule.

===============================================================#

const DictLogicVars = Dict{String, LogicVar}

function recreate_variables(var::LogicVar, vars::DictLogicVars)::Expression
    new_var = get(vars, var.name_id, nothing)
    if new_var == nothing
        global next_var_id += 1
        new_var = LogicVar(var.name, next_var_id)
        vars[var.name_id] = new_var
    end
    return new_var
end

#===============================================================
  replace_variables - replaces a bound variable with its binding.
  This method is used for displaying final results.
  Params:  logic variable
           substitution set
  Return:  expression
===============================================================#
function replace_variables(v::LogicVar, ss::SubstitutionSet)::Expression
    ground_term, _ = get_ground_term(ss, v)
    return ground_term
end # replace_variables()

# to_string - Formats a LogicVar as a string for display.
# Params: logic variable
# Return: string representation
function to_string(lv::LogicVar)::String
    return "\$$(lv.name_id)"
end  # to_string

# reset_next_var_id() - This function is used to increase speed.
# The inference engine continually copies the substitution set,
# which is indexed by LogicVar ID. The size of the substitution
# set is equal to the highest ID.
# If the var ID is allowed to continually increase, to 10,000,
# for example, then the algorithm will continually copy huge
# arrays. Set the ID to 0 for each query.
function reset_next_var_id()
    global next_var_id = 0
end

# get_next_var_id() - For debugging purposes.
# Return: next_var_id - for logic variables.
function get_next_var_id()
    next_var_id
end

# For printing.
function Base.show(io::IO, lv::LogicVar)
    print(io, to_string(lv))
end
