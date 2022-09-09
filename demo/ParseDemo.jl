# ParseDemo.jl
#
# This is a demo program which parses simple English sentences, and checks
# for grammatical errors. It is not intended to be complete or practical.
#
# In order to understand the comments below, it is necessary to have
# a basic understanding of logic programming. Here are some references:
#
# http://athena.ecs.csus.edu/~mei/logicp/prolog.html
# https://courses.cs.washington.edu/courses/cse341/12au/prolog/basics.html
#
# The program starts at main. First it...
#   - creates an empty knowledge base
#   - loads part-of-speech data into a map (create_pos_dict)
#   - creates some atoms, logic variables, and rules
#   - stores these rules into the knowledge base
#   - loads additional facts and rules from a file (load_kb_from_file)
#   - read in a text file, sentences.txt
#   - splits the text into sentences (split_into_sentences)
#
# Next, the program calls sentence_to_facts(). This function does several
# things. It calls sentence_to_words() to divide each sentence into words
# and punctuation. For example:
#
#    "They envy us."
#
# becomes...
#
#    ["They", "envy", "us", "."]
#
# Next it creates a linked list by calling MakeLinkedList():
#
#    [They, envy, us, .]
#
# Note: In Prolog, all words which begin with a capital letter are
# variables. In Suiron, variables begin with a dollar sign, eg. $X.
# A capitalized word, such as 'They', is an atom.
#
# sentence_to_facts() calls the function make_facts(). This function
# makes facts which associate each word with a grammatical fact.
# For example:
#
#    word(we, pronoun(we , subject, first, plural))
#
# Note: Many words can have more than one part of speech. The word
# 'envy', for example, can be a noun or a verb. In order to parse
# English sentences, the program needs facts which identify all
# possible parts of speech:
#
#    word(envy, noun(envy, singular)).
#    word(envy, verb(envy, present, base)).
#
# Finally, the program calls the method solve(), which tries to find
# a solution for the goal 'parse'.
#
# The arguments of solve() are:
#     the goal - parse([They, envy, us, .], \$X)
#     knowledge base
#     an empty substitution set
#
# During analysis, the rule words_to_pos/2 is applied to convert
# the input word list, created by sentence_to_facts(), into a list
# of terms which identify part of speech.
#
#   words_to_pos([$H1 | $T1], [$H2 | $T2]) :-
#                          word($H1, $H2), words_to_pos($T1, $T2).
#   words_to_pos([], []).
#
# The sentence "They envy us." will become:
#
# [pronoun(They, subject, third, plural), verb(envy, present, base),
#          pronoun(us, object, first, plural), period(.)]
#
# The inference rule 'sentence' identifies (unifies with) various
# types of sentence, such as:
#
#   subject pronoun, verb
#   subject noun, verb
#   subject pronoun, verb, object
#   subject noun, verb, object
#
# There are rules to check subject/verb agreement of these sentences:
#
#    check_pron_verb
#    check_noun_verb
#
# When a mismatch is found (*He envy), these rules print out an error
# message:
#
# 'He' and 'envy' do not agree.
#
# Cleve (Klivo) Lendon   2022
#

push!(LOAD_PATH, "..")
using Suiron
const sr = Suiron

include("./PartOfSpeech.jl")
include("./Sentence.jl")
include("./Punctuation.jl")

# The demo program starts here.
function main()

    # The knowledge base stores rules and facts.
    kb = sr.KnowledgeBase()

    # Load part of speech data from a text file.
    pos, err = create_pos_dict("part_of_speech.txt")
    if length(err) > 0
        println(err)
        return
    end

    # -------------------------------
    parse        = sr.Atom("parse")
    words_to_pos = sr.Atom("words_to_pos")
    word         = sr.Atom("word")

    # Define variables.
    H1 = sr.LogicVar("H1")
    H2 = sr.LogicVar("H2")
    T1 = sr.LogicVar("T1")
    T2 = sr.LogicVar("T2")
    X  = sr.LogicVar("X")

    #=
     words_to_pos/2 is a rule to convert a list of words into a list
     of parts of speech. For example, the atom 'the' is converted to
     the Complex term 'article(the, definite)':

         words_to_pos([$H1 | $T1], [$H2 | $T2]) :- word($H1, $H2),
                                                   words_to_pos($T1, $T2).
         words_to_pos([], []).

    =#

    head = sr.SComplex(words_to_pos, sr.make_linked_list(true, H1, T1),
                                     sr.make_linked_list(true, H2, T2))

    body = sr.SOperator(:AND, sr.SComplex(word, H1, H2),
                              sr.SComplex(words_to_pos, T1, T2))
    rule = sr.Rule(head, body)

    # Note: The Atom, LogicVar and Rule definitions above can be
    # replaced by a single line:
    # rule = parse_rule("words_to_pos([$H1 | $T1], [$H2 | $T2]) :- " +
    #                  "word($H1, $H2), words_to_pos($T1, $T2)")
    # parse_rule will parse the given string to produce a RuleStruct.
    # In Prolog, variables begin with a capital letter and atoms
    # begin with a lower case letter. Suiron is a little different.
    # The parser requires a dollar sign to identify variables.
    # An atom can begin with an upper case or lower case letter.

    sr.add_facts_rules(kb, rule)  # Add the rule to our knowledge base.

    rule = sr.Fact(sr.SComplex(words_to_pos,
                               sr.get_empty_list(), sr.get_empty_list()))
    # Alternative (simpler) rule definition:
    #rule, _ = sr.parse_rule("words_to_pos([], [])")

    sr.add_facts_rules(kb, rule)

    # Rules for noun phrases.
    rule, _ = sr.parse_rule("make_np([adjective(\$Adj, \$_), " *
              "noun(\$Noun, \$Plur) | \$T], [\$NP | \$Out]) :- " *
              "!, \$NP = np([\$Adj, \$Noun], \$Plur), make_np(\$T, \$Out)")
    sr.add_facts_rules(kb, rule)
    rule, _ = sr.parse_rule("make_np([\$H | \$T], [\$H | \$T2]) :- make_np(\$T, \$T2)")
    sr.add_facts_rules(kb, rule)
    rule, _ = sr.parse_rule("make_np([], [])")
    sr.add_facts_rules(kb, rule)

    # Read facts and rules from file.
    fn = "demo_grammar.txt"
    err = sr.load_kb_from_file(kb, fn)
    if length(err) > 0
        println(err)
        return
    end

    text = ""
    try
        text = read("sentences.txt", String)
    catch err
        err_msg = string(sprint(showerror, err))
        println(err_msg)
        return
    end

    sentences = split_into_sentences(text)
    for sentence in sentences

        print("$sentence ")

        # Delete previous 'word' facts. Don't want them to accumulate.
        delete!(kb, "word/2")

        in_list = sentence_to_facts(sentence, kb, pos)

        sr.set_max_time(1.2)
        goal = sr.make_goal(parse, in_list, X)

        _, failure = sr.solve(goal, kb, sr.SubstitutionSet())
        if length(failure) != 0
            println(failure)
        end
        print("\n")
    end
end # main

# is_punc - returns true if the character is a punctuation mark,
# possibly marking the end of a sentence.
#
# Params: character to test
# Return: true/false
function is_punc(c::Char)::Bool
    if c == '!' || c == '?' || c == '.'
        return true
    end
    return false
end # is_punc

# end_of_word - returns true if the current character is a space,
# or is at the end of a line.
#
# Params: character to test
# Return: true/false
function end_of_word(c::Char)::Bool
    if c == ' ' || c == '\n' return true end
    return false
end # end_of_word


# split_into_sentences - splits a string of text into sentences, by searching
# for punctuation. The punctuation must be followed by a space.
# (The period in '3.14' doesn't mark the end of a sentence.)
#
# Params: input string
# Return: list of sentences
#
function split_into_sentences(str::String)::Vector{String}

    sentences = Vector{String}()
    sentence = ""

    previous_index = 1
    previous3::Vector{Char} = ['a', 'a', 'a']

    for (i, c) = enumerate(str)

        if end_of_word(c) && is_punc(previous3[3])
            if previous3[3] == '.'
                # Check for H.G. Wells or H. G. Wells
                if previous3[1] != '.' && previous3[1] != ' '
                    sentence = string(strip(str[previous_index: i - 1]))
                    push!(sentences, sentence)
                    previous_index = i
                end
            else
                sentence = string(strip(str[previous_index: i - 1]))
                push!(sentences, sentence)
                previous_index = i
            end
        end
        previous3[1] = previous3[2]
        previous3[2] = previous3[3]
        previous3[3] = c

    end  # for

    len = length(str)
    s = string(strip(str[previous_index: len]))
    if length(s) > 0
        push!(sentences, s)
    end

    return sentences

end # split_into_sentences

# sentence_to_facts - divides a sentence it into words, and creates
# facts which are written to the knowledge base.
#
# Params: sentence
#         knowledge base
#         part of speech map
# Return: word list (linked list)
#
function sentence_to_facts(sentence::String, kb::sr.KnowledgeBase,
                     pos::Dict{String, Vector{String}})::sr.SLinkedList

    words = sentence_to_words(sentence)

    terms = Vector{sr.Unifiable}()
    for word in words
        push!(terms, sr.Atom(word))
    end

    word_list = sr.make_linked_list(false, terms...)

    # Make word facts, such as: word(envy, noun(envy, singular)).
    facts = make_facts(words, pos)
    for fact in facts
        sr.add_facts_rules(kb, fact)
    end

    return word_list

end  # sentence_to_facts

main()
