# TestReadRules.jl
#
# Read in facts and rules from a text file (kings.txt)
# and executes a query. Who is Skule's grandfather?
#
# Cleve Lendon  2022

function test_read_rules()

    println("Test Read Rules")
    file_name = "kings.txt"
    bad_file_name = "kings!.txt"

    kb = sr.KnowledgeBase()

    err = sr.load_kb_from_file(kb, bad_file_name)
    expected = "SystemError: opening file \"kings!.txt\": " *
               "No such file or directory"
    if err != expected
        println("Test Read Rules - Should produce error:\n", expected)
        return
    end

    err = sr.load_kb_from_file(kb, "badrule1.txt")
    expected = "Error - unmatched bracket: (\nCheck start of file."
    if err != expected
        println("Test Read Rules - Should produce error:\n", expected)
        return
    end

    err = sr.load_kb_from_file(kb, "badrule2.txt")
    expected = "Error - unmatched bracket: )\n" *
               "Error occurs after: parent(Godwin, Tostig)."
    if err != expected
        println("TestReadRules - Should produce error:\n" + expected)
        return
    end

    err = sr.load_kb_from_file(kb, "badrule3.txt")
    expected = "Check line 3: par"
    if err != expected
        println("TestReadRules - Should produce error:\n", expected)
        return
    end

    err = sr.load_kb_from_file(kb, file_name)
    if length(err) > 0
        println("TestReadRules:\n", err)
        return
    end

    goal, _ = sr.parse_goal("grandfather(\$X, Skule)")
    solution, failure = sr.solve(goal, kb, sr.SubstitutionSet())

    if length(failure) > 0
        println("TestReadRules: No solution.\n", failure)
        return
    end

    grandfather = sr.get_term(solution, 2)
    expected = "Godwin"
    # grandfather is an Atom.
    if grandfather.str != expected
        println("TestReadRules - Solution should be Godwin." *
                "\n                was: ", grandfather)
        return
    end

end  # ReadRules
