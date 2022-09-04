# ParseGoals.jl
#
# Cleve Lendon
# 2022

# identify_infix - Determines whether the given string contains an infix.
# If it does, returns the infix type and the index. For example,
#    $X < 6
# ...contains the LESS_THAN infix, index 4.
#
# Params: string to parse
# Return: identifier (symbol)
#         index
function identify_infix(str::String)::Tuple{Symbol, Integer}

    len = length(str)

    for i = 1:len
        c1 = str[i]
        if c1 == '"'
            for j = i + 1:len
                c2 = str[j]
                if c2 == '"'
                    i = j
                    break
                end
            end
        elseif c1 == '('
            for j = i + 1:len
                c2 = str[j]
                if c2 == ')'
                    i = j
                    break
                end
            end
        else
            # Can't be last character.
            if i == len
                break
            end
            if c1 == '<'
                c2 = str[i+1]
                if c2 == '='
                    return :LESS_THAN_OR_EQUAL, i
                end
                return :LESS_THAN, i
            end
            if c1 == '>'
                c2 = str[i+1]
                if c2 == '='
                    return :GREATER_THAN_OR_EQUAL, i
                end
                return :GREATER_THAN, i
            end
            if c1 == '='
                c2 = str[i+1]
                if c2 == '='
                    return :EQUAL, i
                end
                return :UNIFICATION, i
            end
        end
        i += 1
    end # for

    return :NONE, -1  # failed to find infix

end # identify_infix

# get_left_and_right - This function is used to parse built-in predicates,
# which are represented with an infix, such as "$X = verb" or "$X <= 47".
# It separates the two terms. If there is an error in parsing a term,
# the function throws an error.
# Params: string to parse
#         index of infix
#         size of infix
# Return: term1, term2
function get_left_and_right(str::String, index::Integer,
                            size::Integer)::Tuple{Unifiable, Unifiable}
   arg1 = str[1: index - 1]
   arg2 = str[index + size: end]
   term1, err = parse_term(string(arg1))
   if length(err) > 0
       throw(ArgumentError(err))
   end
   term2, err = parse_term(string(arg2))
   if length(err) > 0
       throw(ArgumentError(err))
   end
   return term1, term2
end # get_left_and_right()

# split_complex_term - splits a string representation of a complex
# term into its functor and terms. For example, if the complex term is:
#
#    "father(Philip, Alize)"
#
# and the indices (index1, index2) are 7 and 21, the function will
# return: "father", "Philip, Alize"
#
# This method assumes that index1 and index2 are valid.
#
# Params: complex term (string)
#         index1
#         index2
# Return: functor (string)
#         terms   (string)
#
function split_complex_term(comp::String,
                            index1::Integer,
                            index2::Integer)::Tuple{String, String}

      functor = comp[1: index1 - 1]
      terms   = comp[index1 + 1: index2 - 1]
      return string(functor), string(terms)

end # split_complex_term

# indices_of_parentheses - if a string has parentheses, this function
# will return their indices. If there are no parentheses, the indices
# will be -1.
#
# Params: string
# Return: index of left parenthesis  (, or -1
#         index of right parenthesis ), or -1
#         error message
function indices_of_parentheses(str::String)::Tuple{Integer, Integer, String}

    first  = -1  # index of first parenthesis
    second = -1
    count_left  = 0
    count_right = 0

    i = 1
    for ch in str
        if ch == '('
            if first == -1
                first = i
            end
            count_left += 1
        elseif ch == ')'
            second = i
            count_right += 1
        end
        i += 1
    end

    if second < first
        err = "indices_of_parentheses() - Invalid parentheses: $str"
        return first, second, err
    end

    if count_left != count_right
        err = "indices_of_parentheses() - Unbalanced parentheses: $str"
        return first, second, err
    end

    return first, second, ""

end # indices_of_parentheses

# parse_subgoal
#
# This function parses all subgoals. It returns a goal object, and an error.
#
# The Not and Time operators are dealt with first, because they enclose subgoals.
# Eg.
#    not($X = $Y)
#    time(qsort)
#
# Params: subgoal as string
# Return: subgoal as Goal (SComplex)
#         error message
function parse_subgoal(subgoal::String)::Tuple{Union{Goal, SComplex}, String}

    s = string(strip(subgoal))
    len = length(s)

    if len == 0
        err = "parse_subgoal() - Empty string."
        return SComplex(), err
    end

    # not() looks like a built-in predicate
    # but it's actually an operator.
    if startswith(s, "not(")
        s2 = s[5: len - 1]
        operand, err = parse_subgoal(s2)
        if length(err) > 0
            return SComplex(), err
        end
        return SOperator(:NOT, operand), ""
    end

    if s == "!"  # cut
        return SOperator(:CUT), ""
    elseif s == "fail"
        return SOperator(:FAIL), ""
    elseif s == "nl"
        return NL(), ""
    end

    #--------------------------------------
    # Handle infixes: = > < >= <= == =
    infix, index = identify_infix(string(s))
    if infix != :NONE
        if infix == :UNIFICATION
            term1, term2 = get_left_and_right(s, index, 1)
            return Unification(term1, term2), ""
        end
        if infix == :LESS_THAN
            term1, term2 = get_left_and_right(s, index, 2)
            return LessThan(term1, term2), ""
        end
        if infix == :LESS_THAN_OR_EQUAL
            term1, term2 = get_left_and_right(s, index, 2)
            return LessThanOrEqual(term1, term2), ""
        end
        if infix == :GREATER_THAN
            term1, term2 = get_left_and_right(s, index, 2)
            return GreaterThan(term1, term2), ""
        end
        if infix == :GREATER_THAN_OR_EQUAL
            term1, term2 = get_left_and_right(s, index, 2)
            return GreaterThanOrEqual(term1, term2), ""
        end
        if infix == :EQUAL
            term1, term2 = get_left_and_right(s, index, 2)
            return Equal(term1, term2), ""
        end
        return SComplex(),  "identify_infix() - Missing an infix?"
    end

    # Check for parentheses.
    left_index, right_index, err = indices_of_parentheses(string(s))
    if length(err) > 0
        return SComplex(), err
    end

    if left_index == -1   # If left is -1, right is too.
        # This is OK.
        # A 'goal' can be a simple word, without parentheses.
        return parse_functor_terms(s, "")
    end

    str_functor, str_args = split_complex_term(string(s),
                                      left_index, right_index)

    # Check for built-in predicates.
    if str_functor == "time"
        goal, err = parse_complex(str_args)
        if length(err) > 0
            return goal, err
        end
        return Time(goal), ""
    end

    args, err = parse_arguments(str_args)
    if length(err) > 0
        return SComplex(), err
    end

    if str_functor == "append"
        return Append(args...), ""
    end
    if str_functor == "print"
        return Print(args...), ""
    end
    if str_functor == "functor"
         return Functor(args...), ""
    end
    if str_functor == "include"
        return Include(args...), ""
    end
    if str_functor == "exclude"
        return Exclude(args...), ""
    end
    if str_functor == "print_list"
        return PrintList(args...), ""
    end
    if str_functor == "time"
        return Time(args...), ""
    end

    # Create a complex term.
    f = Atom(str_functor)
    unifiables = Vector{Unifiable}()
    push!(unifiables, f)
    append!(unifiables, args)
    return SComplex(unifiables), ""

end # parse_subgoal

# parse_function - parses a string to produce a built-in Suiron function.
# parse_function() is similar to parse_complex() in SComplex.jl.
# Perhaps some consolidation could be done in future.
#
# Example of usage:
#     c = parse_function("add(7, 9, 4)")
#
# Params: string representation
# Return: built-in suiron function
#         error
#
function parse_function(str::String)::Tuple{SFunction, String}

    s = string(strip(str))
    len = length(s)

    if len > 1000
        err = "Parse Function - String is too long: $s"
        return SFunction(), err
    end

    # Get indices.
    left, right, err = indices_of_parentheses(s)
    if length(err) != 0
        return SFunction(), err
    end

    functor = string(strip(s[1: left - 1]))
    args    = string(strip(s[left + 1: right - 1]))

    t, err = parse_arguments(args)
    if length(err) != 0
        return SFunction(), err
    end

    unifiables = Vector{Unifiable}()
    append!(unifiables, t)

    if functor == "add"
        return Add(unifiables), ""
    elseif functor == "subtract"
        return Subtract(unifiables), ""
    elseif functor == "multiply"
        return Multiply(unifiables), ""
    elseif functor == "divide"
        return Divide(unifiables), ""
    end

    return SFunction(), "ParseFunction - Unknown function: $functor"

end # parse_function
