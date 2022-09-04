# RuleReader.jl - reads Suiron facts and rules from a file.
#
# Cleve Lendon 2022

# separate_rules - divides a text string to create an array of rules.
# Each rule or fact ends with a period.
#
# Params: original text
# Return: array rules
#         error message, if any
function separate_rules(text::String)::Tuple{Vector{String}, String}

    str = ""
    rules = Vector{String}()

    round_depth  = 0
    square_depth = 0
    quote_depth  = 0

    for ch in text
        str *= ch
        if ch == '.' && round_depth == 0 &&
           square_depth == 0 && (quote_depth % 2) == 0
            push!(rules, str)
            str = ""
        elseif ch == '('
            round_depth += 1
        elseif ch == '['
            square_depth += 1
        elseif ch == ')'
            round_depth -= 1
        elseif ch == ']'
            square_depth -= 1
        elseif ch == '"'
            quote_depth += 1
        end
    end # for

    # Check for unmatched brackets here.
    err = unmatched_bracket(str, round_depth, square_depth)
    return rules, err

end # separate_rules


# unmatched_bracket - checks for an unmatched bracket. If there is an
# unmatched bracket, returns an error.
# If there is no error, return nil.
# Params:  previous string, for context
#          depth of round brackets (int)
#          depth of square brackets (int)
# Return:  error, if any
function unmatched_bracket(str::String,
                           round_depth::Integer,
                           square_depth::Integer)::String

    # If no error, return "".
    if round_depth == 0 && square_depth == 0
        return ""
    end

    msg  = ""
    msg2 = ""

    if round_depth > 0
        msg = "unmatched bracket: (\n"
    elseif round_depth < 0
        msg = "unmatched bracket: )\n"
    elseif square_depth > 0
        msg = "unmatched bracket: [\n"
    elseif square_depth < 0
        msg = "unmatched bracket: ]\n"
    end

    if length(str) == 0
        msg2 = "Check start of file."
    else
        if length(str) > 60
            str = str[start: 60]
        end
        msg2 = "Error occurs after: " * str
    end
    return "Error - $msg $msg2"

end  # unmatched_bracket


# strip_comments - strips comments from a line.
# In Suiron, valid comment delimiters are:
#
#   %  Comment
#   #  Comment
#   // Comment
#
# Any text which occurs after these delimiters is considered
# a comment, and removed from the line. But, if these delimiters
# occur within braces, they are not treated as comment delimiters.
# For example, in the line
#
#    print(Your rank is %s., $Rank),   % Print user's rank.
#
# the first percent sign does not start a comment, but the second
# one does.
#
# Params: original line
# Return: trimmed line
#
function strip_comments(line::String)::String

    previous    = 'x'
    round_depth  = 0
    square_depth = 0

    index = 0
    for (i, ch) in enumerate(line)
        if ch == '('
            round_depth += 1
        elseif ch == '['
            square_depth += 1
        elseif ch == ')'
            round_depth -= 1
        elseif ch == ']'
            square_depth -= 1
        elseif round_depth == 0 && square_depth == 0
            if ch == '#' || ch == '%'
                index = i
                break
            elseif ch == '/' && previous == '/'
               index = i - 1
               break
            end
        end
        previous = ch
    end # for

    if index > 0
        return string(strip(line[begin: index - 1]))
    else
        return string(strip(line))
    end

end  # strip_comments

# read_facts_and_rules - Reads Suiron facts and rules from a text file.
# Strips out all comments. (Comments are preceded by #, % or # .)
# Params:  file name
# Return: array (slice) of rules
#         error
function read_facts_and_rules(file_name::String)::Tuple{Vector{String}, String}

    line_num = 1
    str = ""
    for line in eachline(file_name)
        stripped_line = strip_comments(line)
        if length(stripped_line) > 0
            err = check_end_of_line(stripped_line, line_num)
            if length(err) > 0
                return [""], err
            end
            str *= "$stripped_line "
        end
        line_num += 1
    end

    roolz, err = separate_rules(str)
    return roolz, err

end  # read_facts_and_rules


# check_end_of_line - Checks to ensure that a line read from
# a file ends with a valid character. Why?
# Rules and facts can be split over several lines. For example,
# it is valid to write a rule as:
#
#   parse($In, $Out) :-
#         words_to_pos($In, $In2),
#         remove_punc($In2, $In3),
#         sentence($In3, $Out).
#
# The lines above end in dash, comma, comma and period.
# If a line were a simple word, such as:
#
#   sentence
#
# That would likely be an error, and should be flagged.
#
# Params: line of text to check
#         number of line to check
# Return: error, if any
function check_end_of_line(line::String, num::Integer)::String
    if length(line) > 0
        last = line[end]
        if last != '-' && last != ',' &&
           last != '.' && last != '='
            return "Check line $num: $line"
        end
    end
    return ""
end

# load_kb_from_file - Reads rules and facts from a text file, parses
# them, then adds them to the knowledge base. If a parsing error is
# generated, add the previous line to the error message.
#
# Params: knowledge base
#         filename
# Return: error message, if any
#
function load_kb_from_file(kb::KnowledgeBase, file_name::String)::String
    facts_and_rules, err = read_facts_and_rules(file_name)
    if length(err) != 0
        return err
    end
    previous = ""
    for str in facts_and_rules
        fact_or_rule, err = parse_rule(str)
        if length(err) > 0
            return load_parse_error(previous, err)
        end
        add_facts_rules(kb, fact_or_rule)
        previous = str
    end
    return ""
end  # load_kb_from_file

# load_parse_error - If a parse error occurs while loading rules,
# this function adds the previous line for context.
# Params: previous line
#         error message
# Return: new error
function load_parse_error(previous::String, err::String)::String
    if length(previous) == 0
        return "$err - Check start of file."
    else
        return "Error occurs after: $previous"
    end
end  # load_parse_error
