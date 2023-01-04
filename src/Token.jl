# Token.jl
#
# Tokens are used to parse Suiron's goals. Each token represents
# a node in a token tree.
#
# A token leaf can be: :SUBGOAL, :COMMA, :SEMICOLON, :LPAREN, :RPAREN.
# If a token is a branch node, its type will be: :GROUP, :AND, :OR.
#
# For example, for this goal: (mother($X, $Y); father($X, $Y))
# the token types would be: :LPAREN :SUBGOAL :SEMICOLON :SUBGOAL :RPAREN.
#
# There is a precedence to subgoals. From highest to lowest.
#
#    groups (...)  -> :GROUP
#    conjunction , -> :AND
#    disjunction ; -> :OR
#
# Cleve Lendon
# 2022

mutable struct Token
    the_type::Symbol
    token::String
    children::Vector{Token}
    function Token(ty::Symbol, to::String)
        new(ty, to)
    end
end

# token_leaf - produces a leaf node (Token) for the given string.
# Valid leaf node types are: :COMMA, :SEMICOLON, :LPAREN, :RPAREN, :SUBGOAL.
#
# Params: symbol or subgoal (string)
# Return: token
function token_leaf(str::String)::Token
    s = string(strip(str))
    if s == ","
        return Token(:COMMA, s)
    end
    if s == ";"
        return Token(:SEMICOLON, s)
    end
    if s == "("
        return Token(:LPAREN, s)
    end
    if s == ")"
        return Token(:RPAREN, s)
    end
    return Token(:SUBGOAL, s)
end # token_leaf

# token_branch - produces a branch node (Token) with the given
# child nodes. Valid branch node types are: GROUP, AND, OR.
# Params:  type of node
#          child nodes
# Return:  a branch (parent) node
function token_branch(the_type::Symbol, children::Vector{Token})::Token
    t = Token(the_type, "")
    t.children = children
    return t
end # token_branch

# number_of_children - in the given token.
# Params:  token
# Return:  number of children
function number_of_children(ts::Token)::Integer
    return length(ts.children)
end

# to_string - Formats a token for display.
# This method is useful for diagnostics. Eg.:
#    SUBGOAL > sister(Janelle, Amanda)
# Params: token
# Return: string representation
function to_string(token::Token)::String
    str = String(token.the_type)
    if token.the_type == :AND || token.the_type == :OR
        str *= " > "
        for child in token.children
            str *= String(child.the_type) * " "
        end
    elseif token.the_type == :SUBGOAL
        str *= " > $token.token"
    end
    return str
end # to_string
