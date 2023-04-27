# Sentence.jl - functions which divide an English sentence into
# a list of words and punctuation.
#
# Cleve (Klivo) Lendon  2022

const MAX_WORD_LENGTH       = 30
const MAX_WORDS_IN_SENTENCE = 120

# is_apostrophe - tests whether a character is an apostrophe.
#
# Params: character
# Return: true/false
function is_apostrophe(ch::Char)::Bool
    if ch == '\'' || ch == '\u02bc'
        return true
    end
    return false
end

# is_punctuation - determines whether a character is punctuation.
# EXCEPT if the character is a period (.).
# A period could be part of an abbreviation or number (eg. 37.49).
#
# Params: character
# Return: true/false
function is_punctuation(ch::Char)::Bool
    if ch == '.' return false end
    if ch >= '!' && ch <= '/' return true end
    if ch >= ':' && ch <= '@' return true end
    if ch == '\u2013'         return true end  # en-dash
    if is_quote_mark(ch) >= 0 return true end
    return false
end

# is_quote_mark - checks whether the character is a quote mark ("'«).
#
# If yes, return the index of the quote mark.
# If no, return -1.
#
# Params:  character
# Return:  index of quote (or -1)
function is_quote_mark(ch::Char)::Integer
    i = 1
    len = length(left_quotes)
    while i < len
        if ch == left_quotes[i] return i end
        if ch == right_quotes[i] return i end
        i += 1
    end
    return -1
end  # is_quote_mark

left_quotes  = ['\'', '"', '\u00ab', '\u2018', '\u201c']
right_quotes = ['\'', '"', '\u00bb', '\u2019', '\u201d']

# end_of_sentence - determines whether a period is at the end of a sentence.
# (If it is at the end, it must be punctuation.)
#
# Params: sentence
#         index
# Return: true/false
#
function end_of_sentence(sentence::String, index::Integer)::Bool
    len = length(sentence)
    if index >= len return true end
    while index < len
        ch = sentence[index]
        index += 1
        if sr.letter_number_hyphen(ch) return false end
    end
    return true
end # end_of_sentence


# get_words - divides a sentence into a list of words and punctuation.
#
# Params: sentence string
# Return: list of words and punctuation
function get_words(sentence::String)::Vector{String}

    words = Vector{String}()
    number_of_words = 0

    len = length(sentence)

    start_index = 1
    last_index  = 0

    while start_index <= len && number_of_words < MAX_WORDS_IN_SENTENCE

        character = ' '

        # Skip spaces, etc.
        while start_index <= len
            character = sentence[start_index]
            if character > ' ' break end
            start_index += 1
        end
        if start_index > len break end

        # A period at the end of a sentence is punctuation.
        # A period in the middle is probably part of an abbreviation
        # or number, eg.: 7.3
        if character == '.' && end_of_sentence(sentence, start_index)
            push!(words, ".")
            start_index += 1
        elseif (is_punctuation(character))
            push!(words, character)
            start_index += 1
        elseif (sr.letter_number_hyphen(character))

            last_index = start_index + 1
            while last_index <= len
                character = sentence[last_index]
                if character == '.'
                    if end_of_sentence(sentence, last_index) break end
                    # There might be an apostrophe within the word: don't, we've
                elseif is_apostrophe(character)
                    if last_index < length - 1
                        ch2 = sentence[last_index + 1]
                        if !sr.letter_number_hyphen(ch2) break end
                    end
                else
                    if !sr.letter_number_hyphen(character) break end
                end
                last_index += 1
            end  # while

            word = sentence[start_index: last_index - 1]
            push!(words, string(word))

            number_of_words += 1

            start_index = last_index

        else  # unknown character.
            start_index += 1
        end
    end  # while

    return words

end # get_words

# sentence_to_words - divides a sentence into words.
#
# Params: original sentence
# Return: list of words
function sentence_to_words(sentence::String)::Vector{String}
    # Clean up the string. New line becomes a space.
    replace(sentence, "\n" => " ")
    # Divide string into words and punctuation.
    return get_words(sentence)
end
