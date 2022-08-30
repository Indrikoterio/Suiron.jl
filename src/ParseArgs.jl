# ParseArgs.jl
#
# Cleve Lendon
# 2022
#
# A complex term consists of a functor followed by a list of arguments
# (terms) between parentheses: functor(arg1, arg2, arg3). These arguments
# might be Atoms, SNumbers, LogicVars or LinkedLists.
#
# This file contains functions to parse a list of arguments, and return
# a vector of unifiable terms (Atoms, SNumbers, etc.). Arguments are
# comma separated, but if a comma is between double quotes, the comma is
# included in the argument. For example, in the complex term:
#
#      address(London, Baker St., 221B)
#
# there are 3 arguments (arity = 3): London, 'Baker St.' and 221B.
#
# In the complex term,
#
#      address("London, Baker St., 221B")
#
# there is one argument (arity = 1): ->London, Baker St., 221B<-
#
# Another way to define a term which contains commas is to escape the
# commas with backslashes:
#
#      address(London\, Baker St.\, 221B).
#
# This complex term above has one argument, as in the previous example.
#
# Any character can be escaped with a backslash, including the double
# quote mark.
#
# Note:
# Complex terms can be parsed from a Suiron program file (a text file),
# as in the examples above, or they can be created from a Julia program.
# For example;
#
#     loves   = Atom("loves")
#     leonard = Atom("Leonard")
#     penny   = Atom("Penny")
#     c1 = SComplex(loves, leonard, penny)
#
# C1 above represents the complex term: loves(Leonard, Penny)
#
# In a text file, a complex term which defines a double quote mark might
# be defined as follows:
#
#      double_quote(\")
#
# The quotation mark is escaped so that it will be interpreted as an Atom,
# not as the start of a quoted term.
#
# The backslash character is also used as an escape character in Julia.
# In a Julia program source file, in order to define the above term, both
# the quotation mark and the backslash would need to be escaped to pass
# through the compiler, as follows:
#
#      c = parse_complex("double_quote(\\\")")
#
# Another example,
#
#      inspiration("\"Do or do not. There is no try.\" -- Yoda")
#
# In this complex term, there is one argument, which includes quote marks.
#
#      "Do or do not. There is no try." -- Yoda
#
# In a Julia program file:
#
#      c = parse_complex("\\\"Do or do not. There is no try.\\\" -- Yoda")
#
# There are 2 kinds of constants in Suiron, Atoms and SNumbers.
# In the following complex term,
#
#      person(Cleve Lendon, 1961, 1.78)
#
# 'Cleve Lendon' is an Atom (= string). 1961 and 1.78 are SNumbers.
#
# Any term between double quotation marks will be parsed as an Atom.
#
#      person("Cleve Lendon", "1961", "1.78")
#
# In the above complex term, all three arguments are Atoms.
#
# Variables start with a dollar sign, followed by at least one letter:
#
#      father(Alfred, $Son)
#
# Of course, the dollar sign can be escaped with a backslash, or put
# inside quotes:
#
#      dollar_sign("$")
#      dollar_sign(\$)
#
# Cleve Lendon

empty_unifiable = Array{Unifiable, 1}()

# parse_arguments - parses a comma separated list of arguments.
# Param: string to parse
# Return:
#     array of Unifiables
#     error message
function parse_arguments(str::String)::Tuple{Vector{Unifiable}, String}

    s = strip(str)
    len = length(s)

    if len == 0
        err = format_pa_error("Empty argument list", s)
        return Array{Unifiable, 1}[], err
    end

    if s[begin] == ','
        err = format_pa_error("Missing first argument", s)
        return Array{Unifiable, 1}[], err
    end

    if s[end] == ','
        err = format_pa_error("Missing last argument", s)
        return Array{Unifiable, 1}[], err
    end

    has_digit     = false
    has_non_digit = false
    has_period    = false
    open_quote    = false

    num_quotes   = 0
    round_depth  = 0   # depth of round parentheses (())
    square_depth = 0   # depth of square brackets [[]]

    argument = ""
    arguments = Array{Unifiable, 1}()

    start = 1

    i = start
    while i <= len

        ch = s[i]

        # If this argument is between double quotes,
        # it must be an Atom.
        if open_quote
            argument *= ch
            if ch == '"'
                open_quote = false
                num_quotes += 1
            end
        else
            if ch == '['
                argument *= ch
                square_depth += 1
            elseif ch == ']'
                argument *= ch
                square_depth -= 1
            elseif ch == '('
                argument *= ch
                round_depth += 1
            elseif ch == ')'
                argument *= ch
                round_depth -= 1
            elseif round_depth == 0 && square_depth == 0 
                if ch == ','
                    s2 = string(strip(argument))
                    err = check_quotes(s2, num_quotes)
                    if length(err) > 0
                        return empty_unifiable, err
                    end
                    num_quotes = 0
                    c, err = make_term(s2, has_digit, has_non_digit, has_period)
                    if length(err) > 0
                        return empty_unifiable, err
                    end
                    arguments   = push!(arguments, c)
                    argument    = ""
                    has_digit   = false
                    has_non_digit = false
                    has_period  = false
                    start = i + 1    # past comma
                elseif ch >= '0' && ch <= '9'
                    argument *= ch
                    has_digit = true
                elseif ch == '.'
                    argument *= ch
                    has_period = true
                elseif ch == '\\'  # escape character, must include next character
                    if i < len
                        i += 1
                        argument *= s[i]
                    else  # must be at end of argument string
                        argument *= ch
                    end
                elseif ch == '"'
                    argument *= ch
                    open_quote = true  # first quote
                    num_quotes += 1
                else
                    argument *= ch
                    if ch > ' '
                        has_non_digit = true
                    end
                end
            else
                # Must be between () or []. Just add character.
                argument *= ch
            end
        end # not open_quote

        i += 1

    end # while

    if start <= len
        s2 = string(strip(argument))
        err = check_quotes(s2, num_quotes)
        if length(err) > 0
            return empty_unifiable, err
        end
        c, err = make_term(s2, has_digit, has_non_digit, has_period)
        if length(err) > 0
            return empty_unifiable, err
        end
        arguments = push!(arguments, c)
    end

    if round_depth != 0
        err = format_pa_error("Unmatched parentheses", s)
        return arguments, err
    end

    if square_depth != 0
        err = format_pa_error("Unmatched brackets", s)
        return arguments, err
    end

    return arguments, ""

end # parse_arguments()


# make_term - determines whether the given string represents an integer,
# a floating point number, an atom (text string), a logic variable or
# a linked list, and returns the appropriate term.
# If the programmer makes a coding error, for example, typing $1X when
# he/she intended $X1, this function will return $1X as an Atom.
# Params:
#    str           - string to parse
#    has_digit     - string to parse has digit
#    has_non_digit - string to parse has non-digit
#    has_period    - avoid argument
# Return:
#    unifiable term
#    error message, or "" if none
function make_term(str::String, has_digit::Bool,
                   has_non_digit::Bool,
                   has_period::Bool)::Tuple{Unifiable, String}

    s = string(strip(str))
    err = ""

    len = length(s)
    if len == 0
        err = format_mt_error("Length of term is 0.", s)
        return Atom(s), err
    end

    first = s[begin]
    if first == '$' || first == '%'

        # Anonymous variable.
        if s == "\$_"
            return Anonymous(), ""
        end

        return LogicVar(s), ""
    end

    # If the argument begins and ends with a quotation mark,
    # the argument is an Atom. Strip off quotation marks.
    if len >= 2
        last = s[end]
        if first == '"'
            if last == '"'
                s2 = string(s[2: end - 1])
                if length(s2) == 0
                    err = format_mt_error("Invalid term. Length is 0.", str)
                    return Atom(s), err
                end
                return Atom(s2), ""
            else
                err = format_mt_error("Invalid term. Unmatched quote mark.", str)
                return Atom(s), err
            end
        elseif first == '[' && last == ']'

            term, err = parse_linked_list(s)
            return term, err

        # Try complex terms, eg.:  job(programmer)
        elseif first != '(' && last == ')'
            # Check for built-in functions.
            if startswith(s, "add(")
                return parse_function(s)
            end
            if startswith(s, "subtract(")
                return parse_function(s)
            end
            if startswith(s, "multiply(")
                return parse_function(s)
            end
            if startswith(s, "divide(")
                return parse_function(s)
            end
            c, err = parse_complex(s)
            return c, err
        end
    end # length > 2

    if has_digit && !has_non_digit   # Must be SNumber.
        if has_period
            f, err = try
                parse(Float64, s), ""
            catch
                0, "Invalid float. $s"
            end
            if length(err) == 0
                return SNumber(f), ""
            end
        else
            i, err = try
                parse(Int64, s), ""
            catch
                0, "Invalid integer. $s"
            end
            if length(err) == 0
                return SNumber(i), ""
            end
        end
    end

    return Atom(s), err

end  # make_term

# check_quotes - checks syntax of double quote marks (") and
# produces an error if there is a problem. An argument may be
# enclosed in double quotation marks at the beginning and end,
# eg. "Sophie". Quotation marks which have been escaped with
# a backslash, (\"), are not counted.
# Arguments such as "Hello"" or "Hello are quite wrong.
# Params:
#     original string
#     number of quote marks
# Return: error message, or "" if none
function check_quotes(str::String, count::Integer)::String
    if count == 0
        return ""  # No problem.
    end
    if count != 2
        return "Unmatched quotes: $str"
    end
    if str[begin] != '"'
        return "Text before opening quote: $str"
    end
    if str[end] != '"'
        return "Text after closing quote: $str"
    end
    return "" # No problem.
end

# format_pa_error - formats an error message for parse_arguments().
# Params:
#    msg - error message
#    str - string which caused the error
# Returns: formatted error message
function format_pa_error(msg::String, str::String)::String
    return "parse_arguments() - $msg: >$str<\n"
end

# format_mt_error - formats an error for make_term().
# Params:
#    msg - error message
#    str - string which caused the error
# Returns: formatted error message
function format_mt_error(msg::String, str::String)::String
    return "make_term() - $msg: >$str<\n"
end

# parse_term - determines whether the given string represents a floating
# point number, an integer, a logic variable, etc., and returns the
# appropriate term. If the programmer makes a coding error, for example,
# typing $1X when he/she intended $X1, the function will return $1X as
# an Atom (= string).
#
# Params: str - string to parse
# Return: unifiable term
#         error message
function parse_term(str::String)::Tuple{Unifiable, String}

    s = strip(str)

    has_digit     = false
    has_non_digit = false
    has_period    = false

    for ch in s
        if ch != '\\'
            if ch >= '0' && ch <= '9'
                has_digit = true
            elseif ch == '.'
                has_period = true
            else
                has_non_digit = true
            end
        end
    end
    return make_term(str, has_digit, has_non_digit, has_period)

end # parse_term
