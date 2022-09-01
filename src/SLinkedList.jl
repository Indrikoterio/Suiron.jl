# SLinkedList.jl
#
# Suiron supports singly linked lists (called SLinkedList), which are
# represented as a list of items between square brackets, as in Prolog:
#
#    []            # empty list
#    [a, b, c, d]
#    [a, b | $Z]   # vertical bar separates head and tail
#
# Linked lists are implemented as a chain of structs. Each link (node)
# of the list has a value (the term), and a link to the next node
# of the list. The last element of the list is an empty list.
#
# A vertical bar (or pipe) '|', is used to divide the list between head
# terms and the tail, which is everything left over. When two lists are
# unified, a tail variable binds with all the left-over tail items in
# the other list. For example, in the following code,
#
#    [a, b, c, d, e] = [$X, $Y | $Z]
#
# Variable $X binds to a.
# Variable $Y binds to b.
# Variable $Z binds to [c, d, e].
#
# There are two are functions to create an SLinkedList from within Julia
# source code: make_linked_list() or parse_linked_list().
#
# make_linked_list() takes a boolean and a variable number of arguments.
# The boolean indicates that the last argument is a tail variable, when
# true. Examples:
#
#   list = make_linked_list(false, a, b, c)    # [a, b, c]
#   list = make_linked_list(true, a, b, c, X)  # [a, b, c | $X]
#
# parse_linked_list() parses a string to produce a SLinkedList:
#
#   list = parse_linked_list("[a, b, c]")
#   list = parse_linked_list("[a, b, c | $X]") # X is a tail variable
#
# Cleve Lendon
# 2022

mutable struct SLinkedList <: Unifiable
    term::Union{Unifiable, Nothing}
    next::Union{SLinkedList, Nothing}
    count::Integer  # number of terms in the list
    is_tail_var::Bool
end

# About is_tail_var:
# It is necessary to distinguish between
#
#     [$A, $B, $X]
# and
#     [$A, $B | $Y]
#
# If the last item in a list is a variable, it can be an ordinary
# list term ($X), or a tail variable ($Y). A tail variable will unify
# with the tail of another list. A non-tail variable will not - it
# can only unify with one term from the other list. The is_tail_var
# flag is used to indicate that the last variable is a tail variable,
# as in the second case above.

empty_list = SLinkedList(nothing, nothing, 0, false)

# get_empty_list - Returns an empty SLinkedList.
# Return: empty list
function get_empty_list()::SLinkedList
    return empty_list
end

# make_linked_list - makes a singly-linked list, such as [a, b, c]
#
#    list = make_linked_list(false, a, b, c)
#
# The first parameter, vbar, is set true for lists which have a tail
# variable, such as [a, b, c | $Tail]
#
#    list = make_linked_list(true, a, b, c, $Tail)
#
# Params:  vbar - vertical bar flag
#          args - list of unifiable arguments
# Return:  linked list
#
function make_linked_list(vbar::Bool, args::Unifiable...)::SLinkedList

    n_args = length(args)
    if n_args == 0
        return get_empty_list()
    end

    tail = get_empty_list()  # Point to empty list
    is_tail_var = vbar  # Last variable is a tail variable.

    num = 1
    last_index = n_args

    i = last_index
    while i > 1

        term = args[i]
        if i == last_index && typeof(term) == SLinkedList
            tail = term
            if tail.term != nothing
               num = tail.count + 1
            end
        else
            tail = SLinkedList(term, tail, num, is_tail_var)
            num += 1
        end
        is_tail_var = false
        i -= 1
    end
    return SLinkedList(args[1], tail, num, is_tail_var)
end

# equal_escape - compares the indexed character with the given
# character. If they are equal, the function will return true,
# except if the indexed character is proceeded by an backslash.
# Because...
# characters which are escaped by a backslash should not be
# interpreted by the parser; they need to be included as they
# are. Examples:
#
#   text = "OK, sure."
#   if compare_escape(text, 2, ',')  # returns true
#
#   text2 = "OK\\, sure."  # double backslash escape in code
#   if compare_escape(text2, 3, ',')  # returns false
#
function equal_escape(str::String, index::Integer, ch::Char)::Bool
    if str[index] == ch
        if index > 0
            previous = str[index]
            if previous == '\\'
                return false
            end
        end
        return true
    end
    return false
end # equal_escape

# parse_linked_list - parses a string to create a linked list.
# For example,
#     list, err = parse_linked_list("[a, b, c | $X]")
# Produces an error if the string is invalid.
# Params:  string representation
# Return:  linked list
#          error message
function parse_linked_list(str::String)::Tuple{SLinkedList, String}

    s = string(strip(str))
    len = length(s)

    list = SLinkedList(nothing, nothing, 0, false) # empty list

    if len < 2
        err = format_ll_error("String is too short", s)
        return list, err
    end

    first = s[1]
    if first != '['
        err = format_ll_error("Missing opening bracket", s)
        return list, err
    end

    last = s[end]
    if last != ']'
        err = format_ll_error("Missing closing bracket", s)
        return list, err
    end

    if len == 2
        return list, ""
    end

    arguments = string(s[2: len-1])    # remove brackets
    arg_length = length(arguments)

    vbar         = false
    end_index    = arg_length

    open_quote   = false
    num_quotes   = 0
    round_depth  = 0   # depth of round parentheses (())
    square_depth = 0   # depth of square brackets [[]]

    i = arg_length
    while i > 0
        if open_quote
            if equal_escape(arguments, i, '"')
                open_quote = false
                num_quotes += 1
            end
        else
            if equal_escape(arguments, i, ']')
                square_depth += 1
            elseif equal_escape(arguments, i, '[')
                square_depth -= 1
            elseif equal_escape(arguments, i, ')')
                 round_depth += 1
            elseif equal_escape(arguments, i, '(')
                 round_depth -= 1
            elseif round_depth == 0 && square_depth == 0
                if equal_escape(arguments, i, '"')
                    open_quote = true  # first quote
                    num_quotes += 1
                elseif equal_escape(arguments, i, ',')
                    str_term = string(arguments[i + 1: end_index])
                    str_term = string(strip(str_term))
                    if length(str_term) == 0
                        err = format_ll_error("Missing argument", s)
                        return list, err
                    end
                    error = check_quotes(str_term, num_quotes)
                    if length(error) > 0
                        return list, error
                    end
                    term, err = parse_term(str_term)
                    if length(err) == 0
                        list = link_front(term, false, list)
                        end_index = i - 1
                    else
                        return empty_list, err
                    end
                    num_quotes = 0
                elseif equal_escape(arguments, i, '|')  # Must be a tail variable.

                    if vbar
                        err = format_ll_error("Too many vertical bars.", s)
                        return list, err
                    end

                    str_term = string(arguments[i + 1: end_index])
                    str_term = string(strip(str_term))

                    if length(str_term) == 0
                        err = format_ll_error("Missing argument", s)
                        return list, err
                    end

                    # After a pipe '|', there must be a logic variable.
                    # Check for dollar sign.
                    if str_term[begin] != '$'
                        err = format_ll_error(
                                  "Require variable after vertical bar", s)
                        return list, err
                    end

                    term = LogicVar(str_term)
                    vbar = true
                    list = link_front(term, true, list);  # tail variable
                    end_index = i - 1
                end
            end
        end # open_quote

        if i == 1
            str_term = string(arguments[1: end_index])
            str_term = string(strip(str_term))
            if length(str_term) == 0
                err = format_ll_error("Missing argument", str_term)
                return list, err
            end
            error = check_quotes(str_term, num_quotes)
            if length(error) > 0
                return list, error
            end
            term, err = parse_term(str_term)
            if length(err) > 0
                return list, err
            end
            list = link_front(term, false, list)
            end_index = i
        end

        i -= 1
    end # for

    return list, ""
end # parse_linked_list()

# link_front - Adds a term to the front of the given linked list.
# Params:  term to add in
#          tail variable flag
#          linked list
# Return:  new linked list
# Note: The tail variable flag is true when the term is tail variable
function link_front(term::Unifiable, is_tail_var::Bool,
                   list::SLinkedList)::SLinkedList
    count = list.count + 1
    return SLinkedList(term, list, count, is_tail_var)
end

# format_ll_error - formats an error for parse_linked_list().
# Params:
#     msg - error message
#     str - string which caused the error
# Return: formatted error message
function format_ll_error(msg::String, str::String)::String
    return "parse_linked_list() - $msg: $str"
end


# flatten - partially flattens a linked list.
# If the number of terms requested is two, this function will return
# an array of the first and second terms, and the tail of the linked
# list. In other words, the list [a, b, c, d] becomes an array containing
# a, b, and the linked list [c, d]. The function returns the resulting
# array and a boolean to indicate success or failure.
# Params: linked list
#         number of terms (requested)
#         substitution set
# Return: array of unifiables
function flatten(ll::SLinkedList, num_of_terms::Integer,
                 ss::SubstitutionSet)::Tuple{Vector{Unifiable}, Bool}

    ptr = ll
    out_list = Vector{Unifiable}()
    if num_of_terms < 1
        return out_list, false
    end

    for i in 1:num_of_terms

        if ptr == nothing
            return out_list, false    # fail
        end

        term = ptr.term
        if ptr.is_tail_var   # Is this node a tail variable?
            var_term = term
            list, ok = cast_linked_list(ss, var_term)
            if ok
                ptr = list
                term = ptr.term
            end
        end
        if term == nothing
            return out_list, false
        end
        push!(out_list, term)
        ptr = ptr.next
    end

    if ptr != nothing
        push!(out_list, ptr)
    end
    return out_list, true

end # flatten

#===============================================================
  unify - unifies a linked list with a logic variable or another
          linked list.
  Two lists can unify if they have the same number of items,
  and each corresponding pair of items can unify. Or, if one
  of the lists ends in a tail Variable (eg. [a, b, | $X]), the
  tail variable can unify with the remainder of the other list.
  The method returns an updated substitution set and a boolean
  flag which indicates success or failure.
  Params:  linked list
           other unifiable term
           substitution set
  Return:  substitution set
           success flag
===============================================================#
function unify(ll::SLinkedList, other::Unifiable,
               ss::SubstitutionSet)::Tuple{SubstitutionSet, Bool}

    other_type = typeof(other)

    if other_type == SLinkedList

        new_ss = ss

        # Empty lists unify. [] = []
        if ll.term == nothing && other.term == nothing
            return ss, true
        end

        this_list  = ll
        other_list = other

        while this_list != nothing && other_list != nothing

            this_term  = this_list.term
            other_term = other_list.term
            this_tail_var  = this_list.is_tail_var
            other_tail_var = other_list.is_tail_var

            term_type  = typeof(this_term)
            other_type = typeof(other_term)

            if this_tail_var && other_tail_var
                if other_type == Anonymous
                    return new_ss, true
                end
                if term_type == Anonymous
                    return new_ss, true
                end
                return unify(this_term, other_term, new_ss)
            elseif this_tail_var
                return unify(this_term, other_list, new_ss)
            elseif other_tail_var
                return unify(other_term, this_list, new_ss)
            else
               if this_term == nothing && other_term == nothing
                   return new_ss, true
               end
               if this_term == nothing || other_term == nothing
                   return ss, false
               end
               new_ss, ok = unify(this_term, other_term, new_ss)
               if !ok
                   return ss, false
               end
            end
            this_list  = this_list.next
            other_list = other_list.next
        end # while

        return ss, false

    elseif other_type == LogicVar
        return unify(other, ll, ss)
    end

    return ss, false  # failure

end # unify

# get_term - returns the top term of this list.
function get_term(ll::SLinkedList)::Union{Unifiable, Nothing}
    return ll.term
end

# get_next - returns the rest of the list.
function get_next(ll::SLinkedList)::SLinkedList
    return ll.next
end

# get_count - returns the number of items in the list.
function get_count(ll::SLinkedList)::Integer
    return ll.count
end


#===============================================================
 recreate_variables - The scope of a logic variable is the rule
 in which it is defined. When the inference engine tries to solve
 a goal, it calls this function to ensure that the variables are
 unique.

 Please refer to LogicVar.jl for a detailed description of this
 function.

 Params:  linked list
          previously recreated variables
 Return:  expression
===============================================================#
function recreate_variables(ll::SLinkedList, vars::DictLogicVars)::Expression
    new_terms = Vector{Unifiable}()
    this_list = ll
    vbar = this_list.is_tail_var
    term = this_list.term
    if term == nothing
        return empty_list
    end
    while term != nothing
        push!(new_terms, recreate_variables(term, vars))
        vbar = this_list.is_tail_var
        this_list = this_list.next
        if (this_list == nothing)
            break
        end
        term = this_list.term
    end
    new_linked_list = make_linked_list(vbar, new_terms...)
    return new_linked_list
end # recreate_variables()


#===============================================================
  replace_variables - replaces variables with their bindings.
  This is required in order to display solutions.

  Params: linked list
          substitution set (contains bindings)
  Return: expression
===============================================================#
function replace_variables(ll::SLinkedList, ss::SubstitutionSet)::Expression
    new_terms = Vector{Unifiable}()
    this_list = ll
    term      = this_list.term
    if term == nothing
        return ll
    end
    while term != nothing
        new_term = replace_variables(term, ss)
        tt = typeof(new_term)
        if tt == SLinkedList
            list = new_term
            ptr = list
            head = ptr.term
            while head != nothing
                push!(new_terms, head)
                ptr = ptr.next
                if ptr == nothing
                    break
                end
                head = ptr.term
            end
        else  # not a list
            push!(new_terms, new_term)
        end
        this_list = this_list.next
        if this_list == nothing
            break
        end
        term = this_list.term
    end
    
    result = make_linked_list(false, new_terms...)
    return result

end # replace_variables()

# to_string - Formats a linked list as a string for display.
# Params: linked list
# Return: string representation
function to_string(ll::SLinkedList)::String
    ptr = ll
    if ptr.term == nothing
        return "[]"
    end
    str = "[$(ptr.term)"
    while ptr.next != nothing
        ptr = ptr.next
        if ptr.term == nothing
            break
        elseif ptr.is_tail_var
            str *= " | $(ptr.term)"
        else
            str *= ", $(ptr.term)"
        end
    end
    str *= "]"
    return str
end

# For printing linked lists.
function Base.show(io::IO, sll::SLinkedList)
    print(io, to_string(sll))
end

#=
    Scan the list from head to tail,
    Curse recursion, force a fail.
    Hold your chin, hypothesize.
    Predicate logic never lies.
=#
