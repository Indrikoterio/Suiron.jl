# PartOfSpeech.jl - has functions which read in a list of words
# with part-of-speech tags, and creates a dictionary keyed by word.
#
# In addition, there are methods to create Facts which can be
# analyzed by Suiron.
#
# The part-of-speech tags in part_of_speech.txt are from Penn
# State's Treebank tagset. There is a reference here:
#
#   https://sites.google.com/site/partofspeechhelp/home
#
# ABN pre-quantifier (half, all)
# AP post-determiner (many, several, next)
# AT article (a, the, no)
# BE be
# BED were
# BEDZ was
# BEG being
# BEM am
# BEN been
# BER are, art
# BBB is
# CC coordinating conjunction
# CD cardinal digit
# DT determiner
# EX existential there (like: “there is” … think of it like “there exists”)
# FW foreign word
# IN preposition/subordinating conjunction
# JJ adjective 'big'
# JJR adjective, comparative 'bigger'
# JJS adjective, superlative 'biggest'
# LS list marker 1)
# MD modal could, will
# NN noun, singular 'desk'
# NNS noun plural 'desks'
# NNP proper noun, singular 'Harrison'
# NNPS proper noun, plural 'Americans'
# OD ordinal numeral (first, 2nd)
# NPS proper noun, plural Vikings
# PDT predeterminer 'all the kids'
# PN nominal pronoun (everybody, nothing)
# PP$ possessive personal pronoun (my, our)
# PP$$ second (nominal) personal pronoun (mine, ours)
# PPO objective personal pronoun (me, him, it, them)
# PPS 3rd. singular nominative pronoun (he, she, it, one)
# PPSS other nominative personal pronoun (I, we, they, you)
# POS possessive ending parent's
# PRP personal pronoun I, he, she
# PRP$ possessive pronoun my, his, hers
# QL qualifier (very, fairly)
# QLP post-qualifier (enough, indeed)
# RB adverb very, silently,
# RBR adverb, comparative better
# RBS adverb, superlative best
# RP particle give up
# SYM symbol
# TO to go 'to' the store.
# UH interjection errrrrm
# VB verb, base form take
# VBD verb, past tense took
# VBG verb, gerund/present participle taking
# VBN verb, past participle taken
# VBP verb, sing. present, non-3d take
# VBZ verb, 3rd person sing. present takes
# WDT wh-determiner which
# WP wh-pronoun who, what
# WP$ possessive wh-pronoun whose
# WRB wh-abverb where, when
#
# Cleve (Klivo) Lendon   2022

const FILENAME = "part_of_speech.txt"

# Word functor. Use capitals to distinguish from the variable 'word'.
const WORD = sr.Atom("word")

const noun = sr.Atom("noun")
const verb = sr.Atom("verb")
const pronoun = sr.Atom("pronoun")
const adjective = sr.Atom("adjective")
const participle = sr.Atom("participle")
const preposition = sr.Atom("preposition")
const unknown = sr.Atom("unknown")

# tenses
const past    = sr.Atom("past")
const present = sr.Atom("present")

# voice
const active  = sr.Atom("active")
const passive = sr.Atom("passive")

# Person, for verbs.
const first_sing  = sr.Atom("first_sing")  # I am
const second_sing = sr.Atom("second_sing") # Thou art
const third_sing  = sr.Atom("third_sing")  # it is
const base        = sr.Atom("base")        # you see

# Person, for pronouns
const first  = sr.Atom("first")  # I, me, we, us
const second = sr.Atom("second") # you
const third  = sr.Atom("third")  # he, him, she, her, it, they, them

# Plurality for nouns and pronouns
const singular = sr.Atom("singular") # table, mouse
const plural   = sr.Atom("plural")   # tables, mice
const both     = sr.Atom("both")     # you

# For adjectives.
const positive    = sr.Atom("positive")    # good
const comparative = sr.Atom("comparative") # better
const superlative = sr.Atom("superlative") # best

# For adverbs.
const adverb = sr.Atom("adverb")  # happily

# For articles.
const article    = sr.Atom("article")    # the, a, an
const definite   = sr.Atom("definite")   # the
const indefinite = sr.Atom("indefinite") # a, an

# For pronouns. (case)
const subject = sr.Atom("subject")  # subject
const object  = sr.Atom("object")   # object

# Punctuation.
const punctuation = sr.Atom("punctuation")

# Some types
const CMPLX_NIL = Union{sr.SComplex, Nothing}
const POS_DICT  = Dict{String, Vector{String}}

# create_pos_dict - reads in part-of-speech data from a file,
# and creates a dictionary of PoS tags, indexed by a word string.
# Params: file name
# Return: PoS dict
#         error message
function create_pos_dict(file_name::String)::Tuple{POS_DICT, String}

    # Dict: word / Part of Speech.
    word_pos = POS_DICT()
    try
        for line in eachline(file_name)

            line2 = string(strip(line))

            arr = split(line2, " ")
            if length(arr) == 1
                word_pos[line2] = [""]
            else
                word = string(arr[1])
                pos = []
                first = true
                for p in arr
                    if first
                        first = false
                        continue
                    end
                    push!(pos, p)
                end
                word_pos[word] = pos
            end

        end
    catch err
        err_msg = string(sprint(showerror, err))
        return word_pos, err_msg
    end

    return word_pos, ""

end  # create_pos_dict

# display_pos - displays the entire contents of the word_pos
# dictionary, for debugging purposes.
# Params: dictionary of Parts of Speech, keyed by word
function display_pos(word_pos::POS_DICT)
    for (k, v) in word_pos
        print("$k ")
        for pos in v
            print("$pos  ")
        end
    end
end  # display_pos

# lower_case_except_I - makes a word lower case,
# except if it's the pronoun I.
# Params: word
# Return: lower case word
function lower_case_except_I(word::String)::String
    if word == "I"
        return word
    end
    if startswith(word, "I'")
        return word
    end
    return lowercase(word)
end

# make_pronoun_term - creates a pronoun term based on the given
# word and its tag. Eg. pronoun(they, subject, third, plural).
# Note: This function does not handle the pronoun 'you'.
# 'You' is dealt with separately, by make_you_facts().
#
# Params: word
#         lower case word
#         part of speech tag
# Return: complex term or nothing
#
function make_pronoun_term(word::String,
                           lower::String, tag::String)::CMPLX_NIL

    term::CMPLX_NIL = nothing

    if startswith(tag, "PPS")  # PPS or PPSS
        if lower == "we"
            term = sr.SComplex(pronoun, sr.Atom(word), subject, first, plural)
        elseif lower == "they"
            term = sr.SComplex(pronoun, sr.Atom(word), subject, third, plural)
        elseif lower == "I"
            term = sr.SComplex(pronoun, sr.Atom(word), subject, first, singular)
        else  # he she it
            term = sr.SComplex(pronoun, sr.Atom(word), subject, third, singular)
        end
    elseif startswith(tag, "PPO")
        if lower == "us"
            term = sr.SComplex(pronoun, sr.Atom(word), object, first, plural)
        elseif lower == "them"
            term = sr.SComplex(pronoun, sr.Atom(word), object, third, plural)
        elseif lower == "me"
            term = sr.SComplex(pronoun, sr.Atom(word), object, first, singular)
        else
            term = sr.SComplex(pronoun, sr.Atom(word), object, third, singular)
        end
    end

    return term

end  # make_pronoun_term


# make_you_facts - creates facts for the pronoun 'you', for example:
#
#     word(you, pronoun(you, subject, second, singular)).
#
# Params: word
# Return: facts
function make_you_facts(word::String)::Vector{sr.Rule}

    facts = Vector{sr.Rule}()
    you = sr.Atom(word)

    pronouns::Vector{sr.SComplex} = [
        sr.SComplex(pronoun, you, subject, second, singular),
        sr.SComplex(pronoun, you, object, second, singular),
        sr.SComplex(pronoun, you, subject, second, plural),
        sr.SComplex(pronoun, you, object, second, plural),
    ]

    for term in pronouns
        new_term = sr.SComplex(WORD, you, term)
        fact = sr.Fact(new_term)
        push!(facts, fact)
    end

    return facts

end  # make_you_facts

# make_verb_term - creates a verb term, eg. verb(listen, present, base).
#
# Params: word
#         part of speech tag
# Return: complex term or nothing
function make_verb_term(word::String, tag::String)::CMPLX_NIL

    term::CMPLX_NIL = nothing

    if tag == "VB"
        term = sr.SComplex(verb, sr.Atom(word), present, base)
    elseif tag == "VBZ"
        term = sr.SComplex(verb, sr.Atom(word), present, third_sing)
    elseif tag == "VBD"
        term = sr.SComplex(verb, sr.Atom(word), past, past)
    elseif tag == "VBG"
        term = sr.SComplex(participle, sr.Atom(word), active)
    elseif tag == "VBN"
        term = sr.SComplex(participle, sr.Atom(word), passive)
    end
    return term

end  # make_verb_term


# make_noun_term - creates a noun term, eg. noun(speaker, singular).
#
# Params: word
#         part of speech tag
# Return: complex term or nothing
function make_noun_term(word::String, tag::String)::CMPLX_NIL

    term::CMPLX_NIL = nothing

    if tag == "NN"
        term = sr.SComplex(noun, sr.Atom(word), singular)
    elseif tag == "NNS"
        term = sr.SComplex(noun, sr.Atom(word), plural)
    elseif tag == "NNP"
        term = sr.SComplex(noun, sr.Atom(word), singular)
    end

    return term

end  # make_noun_term


# make_adjective_term - creates an adjective term, eg. adjective(happy).
#
# Params: word
#         part of speech tag
# Return: complex term or nothing
function make_adjective_term(word::String, tag::String)::CMPLX_NIL

    term::CMPLX_NIL = nothing
    if tag == "JJ"
        term = sr.SComplex(adjective, sr.Atom(word), positive)
    elseif tag == "JJR"
        term = sr.SComplex(adjective, sr.Atom(word), comparative)
    elseif tag == "JJS"
        term = sr.SComplex(adjective, sr.Atom(word), superlative)
    end
    return term

end # make_adjective_term

# make_article_term - creates terms for articles, eg. article(the, definite).
#
# Params: word
# Return: complex term or nothing
function make_article_term(word::String)::CMPLX_NIL

    term::CMPLX_NIL = nothing

    word_lc = lowercase(word)
    if word_lc == "the"
        term = sr.SComplex(article, sr.Atom(word), definite)
    else
        term = sr.SComplex(article, sr.Atom(word), indefinite)
    end

    return term

end  # make_article_term

# make_adverb_term - creates adverb terms, eg. adverb(happily).
#
# Params: word
# Return: complex term or nothing
function make_adverb_term(word::String)::CMPLX_NIL
    term = sr.SComplex(adverb, sr.Atom(word))
    return term
end  # make_adverb_term

# make_preposition_term - creates preposition terms, eg. preposition(from).
#
# Params: word
# Return: complex term or nothing
function make_preposition_term(word::String)::CMPLX_NIL
    term = sr.SComplex(preposition, sr.Atom(word))
    return term, true
end  # make_preposition_term

# make_unknown_term - creates terms for words with unknown part of speech.
#
# Params: word
# Return: complex term or nothing
function make_unknown_term(word::String)::CMPLX_NIL
    term = sr.SComplex(unknown, sr.Atom(word))
    return term, true
end  # make_unknown_term


# make_term - creates a complex term object for an English word.
# The second parameter is a part of speech tag, such as NNS or VBD.
# Tags are listed at the top of this file.
#
# Params: word
#         lower case word
#         part of speech tag
# Return: complex term or nothing
function make_term(word::String, lower::String, tag::String)::CMPLX_NIL

    if startswith(tag, "VB")
        return make_verb_term(word, tag)
    elseif startswith(tag, "NN")
        return make_noun_term(word, tag)
    elseif startswith(tag, "PP")
        return make_pronoun_term(word, lower, tag)
    elseif startswith(tag, "JJ")
        return make_adjective_term(word, tag)
    elseif startswith(tag, "AT")
        return make_article_term(word)
    elseif startswith(tag, "IN")
        return make_preposition_term(word)
    elseif startswith(tag, "RB")
        return make_adverb_term(word)
    end
    return nothing

end # make_term


# word_to_facts - takes a word string and produces facts for the
# knowledge base.
#
# For some words, the part of speech is unambiguous. For example,
# 'the' can only be a definite article:
#
#      article(the, definite)
#
# Other words can have more than one part of speech. The word
# 'envy', for example, might be a noun or a verb.
#
#      noun(envy, singular)
#      verb(envy, present, base)
#
# For 'envy', a parsing algorithm must be able to test both
# possibilities. Therefore, the inference engine will need two
# facts for the knowledge base:
#
#      word(envy, noun(envy, singular)).
#      word(envy, verb(envy, present, base)).
#
# Params: word (string)
#         part of speech data (map)
# Return: facts
function word_to_facts(word::String, pos::POS_DICT)::Vector{sr.Rule}

    lower = lower_case_except_I(word)

    # Handle pronoun 'you', which is very ambiguous.
    if lower == "you"
        return make_you_facts(word)
    end

    len = length(word)
    if len == 1   # Maybe this is punctuation.
        term = make_punctuation_term(word)
        if !isnothing(term)
            word_term = sr.SComplex(WORD, sr.Atom(word), term)
            rules::Vector{sr.Rule} = [sr.Fact(word_term)]
            return rules
        end
    end

    facts = Vector{sr.Rule}()

    if haskey(pos, word)
        pos_data = pos[word]
    elseif haskey(pos, lower)
        pos_data = pos[lower]
    end

    if length(pos_data) > 0
        for pos in pos_data
            term = make_term(word, lower, pos)
            if !isnothing(term)
                word_term = sr.SComplex(WORD, sr.Atom(word), term)
                fact = sr.Fact(word_term)
                push!(facts, fact)
            end
        end
    end

    if length(facts) < 1
        term = sr.SComplex(unknown, sr.Atom(word))
        word_term = sr.SComplex(WORD, sr.Atom(word), term)
        fact = sr.Fact(word_term)
        push!(facts, fact)
    end

    return facts

end  # word_to_facts

# make_facts - takes a list of words, and creates a list
# of facts which can be analyzed by the inference engine.
# The word 'envy', for example, should produce two facts.
#
#     word(envy, noun(envy, singular)).
#     word(envy, verb(envy, present, base)).
#
# Note: A Fact is the same as a Rule without a body.
#
# Params: list of words
#         dictionary of part of speech data
# Return: list of facts
#
function make_facts(words::Vector{String}, pos::POS_DICT)::Vector{sr.Rule}
    facts = Vector{sr.Rule}()
    for word in words
        word_facts = word_to_facts(word, pos)
        for word_fact in word_facts
            push!(facts, word_fact)
        end
    end
    return facts
end  # make_facts
