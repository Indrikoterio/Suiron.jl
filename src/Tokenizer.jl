# Tokenizer.jl - parses Suiron's facts and rules.
#
# Cleve Lendon
# 2022

# letter_number_hyphen - determines whether the given character
# is a letter, a number, or a hyphen. This excludes punctuation.
#
# Params:  character
# Return:  true/false
function letter_number_hyphen(ch::Char)::Bool
    if isletter(ch) return true end
    if isdigit(ch) return true end
    # hyphen or soft hyphen
    if ch == '-' || ch == Char(0xAD)
        return true
    end
    if ch == '_' # underscore
        return true
    end
    return false
end

# invalid_between_terms - Tests for an invalid character.
# Quote, hash and 'at' are invalid between terms.
function invalid_between_terms(ch::Char)::Bool
    if ch == '"'
        return true
    end
    if ch == '#'
        return true
    end
    if ch == '@'
        return true
    end
    return false
end

# generate_goal - generates a Goal from a string.
# For example, a string such as "can_swim($X), can_fly($X)"
# will become an And goal, with two complex statements,
# can_swim and can_fly, as subgoals.
#
# Params: string of tokens
# Return: goal
#         error message
#
function generate_goal(str::String)::Tuple{Union{Goal, SComplex}, String}
    tokens, err = tokenize(str)
    if length(err) > 0
        throw(ArgumentError(err))
    end
    base_token = group_tokens(tokens, 1)
    base_token = group_and_tokens(base_token)
    base_token = group_or_tokens(base_token)
    return token_tree_to_goal(base_token)
end

# tokenize - Divides the given string into a series of tokens.
#
# Note: Parentheses can be part of a complex term: likes(Charles, Gina)
# or used to group terms: (father($_, $X); mother($_, $X))
#
# Params: string to parse
# Return: array of tokens
#         error
function tokenize(str::String)::Tuple{Vector{Token}, String}

    tokens = Vector{Token}()

    stk_parenth = Vector{Symbol}()  # Keeps track of parentheses.

    s = strip(str)

    len = length(s)
    if len == 0
        return tokens, "tokenize() - String is empty."
    end

    start_index = 1

    # Find a separator (comma, semicolon), if there is one.
    previous = '#'   # random

    i = start_index
    while i <= len

        # Get top of stack.
        if length(stk_parenth) == 0
            top = :NONE
        else
            top = stk_parenth[end]
        end

        ch = s[i]
        if ch == '"'   # Ignore characters between quotes.
            j = i + 1
            while j <= len
                ch = s[j]
                if ch == '"'
                    i = j
                    break
                end
                j += 1
            end
        elseif ch == '('
            # Is the previous character valid in a functor?
            if letter_number_hyphen(previous)
                push!(stk_parenth, :COMPLEX)
            else
                push!(stk_parenth, :GROUP)
                tokens = push!(tokens, token_leaf("("))
                start_index = i + 1
            end
        elseif ch == ')'
            if top == :NONE
                err = "tokenize() - Unmatched parenthesis: $s"
                return tokens, err
            end
            if length(stk_parenth) == 0
                top = :NONE
            else
                top = pop!(stk_parenth)
            end
            if top == :GROUP
                subgoal = s[start_index: i - 1]
                tokens = push!(tokens, token_leaf(subgoal))
                tokens = push!(tokens, token_leaf(")"))
            elseif top != :COMPLEX
                err = "tokenize() - Unmatched parenthesis: $s"
                return tokens, err
            end
        elseif ch == '['
            push!(stk_parenth, :LINKEDLIST)
        elseif ch == ']'
            if top == :NONE
                err = "tokenize() - Unmatched bracket: $s"
                return tokens, err
            end
            if length(stk_parenth) == 0
                top = :NONE
            else
                top = pop!(stk_parenth)
            end
            if top != :LINKEDLIST
                err = "tokenize() - Unmatched bracket: $s"
                return tokens, err
            end
        else
            # If not inside complex term or linked list...
            if top != :COMPLEX && top != :LINKEDLIST
                if invalid_between_terms(ch)
                    err = "Tokenize() - Invalid character: $s"
                    return tokens, err
                end
                if ch == ','   # and
                    subgoal = string(s[start_index: i - 1])
                    tokens = push!(tokens, token_leaf(subgoal))
                    tokens = push!(tokens, token_leaf(","))
                    start_index = i + 1
                elseif ch == ';'   # or
                    subgoal = s[start_index: i -1]
                    tokens = push!(tokens, token_leaf(subgoal))
                    tokens = push!(tokens, token_leaf(";"))
                    start_index = i + 1
                end
            end
        end    # else

        previous = ch
        i += 1

    end # while

    if length(stk_parenth) > 0
        err = "tokenize() - Invalid character: $s"
        return tokens, err
    end

    if len - start_index >= 0
        subgoal = s[start_index: len]
        push!(tokens, token_leaf(string(subgoal)))
    end

    return tokens, ""

end # tokenize

# group_tokens - collects tokens within parentheses into groups.
# Converts a flat array of tokens into a tree of tokens.
#
# For example, this:  SUBGOAL SUBGOAL ( SUBGOAL  SUBGOAL )
# becomes:
#          GROUP
#            |
# SUBGOAL SUBGOAL GROUP
#                   |
#            SUBGOAL SUBGOAL
#
# There is a precedence order in subgoals. From highest to lowest.
#
#    groups (...)  -> :GROUP
#    conjunction , -> :AND
#    disjunction ; -> :OR
#
# Params: flat array of tokens
#         starting index
# Return: base of token tree
#
function group_tokens(tokens::Vector{Token}, index::Integer)::Token

    new_tokens = Vector{Token}()
    len = length(tokens)

    while index <= len

        token = tokens[index]
        the_type = token.the_type

        if the_type == :LPAREN
            index += 1
            # Make a GROUP token.
            t = group_tokens(tokens, index)
            new_tokens = push!(new_tokens, t)
            # Skip past tokens already processed.
            index += number_of_children(t) + 1  # +1 for right parenthesis
        elseif the_type == :RPAREN
            # Add all remaining tokens to the list.
            return token_branch(:GROUP, new_tokens)
        else
            push!(new_tokens, token)
        end
        index += 1

    end # while

    return token_branch(:GROUP, new_tokens)

end # group_tokens

# group_and_tokens - groups tokens which are separated by commas.
#
# Params:  base of token tree
# Return:  base of token tree
function group_and_tokens(token::Token)::Token

    children     = token.children
    new_children = Vector{Token}()
    and_list     = Vector{Token}()

    for token in children

        the_type = token.the_type

        if the_type == :SUBGOAL
            and_list = push!(and_list, token)
        elseif the_type == :COMMA
            # Nothing to do.
        elseif the_type == :SEMICOLON
            # Must be end of comma separated list.
            len = length(and_list)
            if len == 1
                push!(new_children, and_list[0])
            else
                push!(new_children, token_branch(:AND, and_list))
            end
            new_children = push!(new_children, token)
            and_list = Vector{Token}()
        elseif the_type == :GROUP
            t = group_and_tokens(token)
            t = group_or_tokens(t)
            push!(and_list, t)
        end

    end # for

    len = length(and_list)
    if len == 1
        push!(new_children, and_list[1])
    elseif len > 1
        push!(new_children, token_branch(:AND, and_list))
    end

    token.children = new_children
    return token

end # group_and_tokens

# group_or_tokens - groups tokens which are separated by semicolons.
#
# Params: base of token tree
# Return: base of token tree
#
function group_or_tokens(token::Token)::Token

    children     = token.children
    new_children = Vector{Token}()
    or_list      = Vector{Token}()

    for token in children

        the_type = token.the_type

        if the_type == :SUBGOAL || the_type == :AND || the_type == :GROUP
            push!(or_list, token)
        elseif the_type == :SEMICOLON
            # Nothing to do.
        end

    end # for

    len = length(or_list)
    if len == 1
        push!(new_children, or_list[1])
    elseif len > 1
        push!(new_children, token_branch(:OR, or_list))
    end

    token.children = new_children
    return token

end # group_or_tokens


# token_tree_to_goal - produces a goal from the given token tree.
# Params: base of token tree
# Return: goal
function token_tree_to_goal(token::Token)::Tuple{Union{Goal, SComplex}, String}

    children = Vector{Token}()
    operands = Vector{Union{Goal, SComplex}}()
    err = nothing

    if token.the_type == :SUBGOAL
        return parse_subgoal(token.token)
    end

    if token.the_type == :AND
        operands = Vector{Union{Goal, SComplex}}()
        children = token.children
        for child in children
            if child.the_type == :SUBGOAL
               g, err = parse_subgoal(child.token)
               push!(operands, g)
            elseif child.the_type == :GROUP
               g, err = token_tree_to_goal(child)
               push!(operands, g)
            end
        end
        return SOperator(:AND, operands...), err
    end

    if token.the_type == :OR
        operands = Vector{Goal}()
        children = token.children
        for child in children
            if child.the_type == :SUBGOAL
               g = parse_subgoal(child.token)
               push!(operands, g)
            elseif child.the_type == :GROUP
               g = token_tree_to_goal(child)
               push!(operands, g)
            end
        end
        return Or(operands...)
    end

    if token.the_type == :GROUP
        if number_of_children(token) != 1
            throw(ArgumentError(
                "token_tree_to_goal - Group should have 1 child token.")
            )
        end
        child_token = token.children[1]
        return token_tree_to_goal(child_token)
    end

    return SComplex(), "token_tree_to_goal - Unknown token."

end  # token_tree_to_goal()

# show_tokens - Displays a flat list of tokens for debugging purposes.
# Params: array of tokens
function show_tokens(tokens::Vector{Token})
    first = true
    for token in tokens
        if !first
            print(" ")
        end
        first = false
        the_type = token.the_type
        if the_type == :SUBGOAL
            print(token.token)
        else
            print(String(token.the_type))
        end
    end # for
    print("\n")
end # show_tokens
