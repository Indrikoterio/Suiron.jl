# TestComplex.jl - Test creation and unification of complex terms.
# Cleve Lendon 2022

function test_complex()

    println("Test Complex")
    owns  = sr.Atom("owns")
    john  = sr.Atom("John")
    house = sr.Atom("house")
    car   = sr.Atom("car")

    X  = sr.LogicVar("X")

    # Use make_goal(), instead of make_complex(), to ensure
    # that logic variables have unique IDs.
    c1 = sr.make_goal(owns, john, house)  # owns(John, house)
    c2 = sr.make_goal(owns, john, house)  # owns(John, house)
    c3 = sr.make_goal(owns, john, car)    # owns(John, car)

    c4 = sr.make_goal(owns, john, X)
    ss = sr.SubstitutionSet()

    new_ss, success = sr.unify(c1, c2, ss)
    if !success
        println("------------ c1 should unify with c2")
    end

    new_ss, success = sr.unify(c1, c3, new_ss)
    if success
        println("------------ c1 should NOT unify with c3")
    end

    if length(new_ss) > 0
        println("------------ Should not change substitution set.")
    end

    new_ss, success = sr.unify(c1, c4, ss)
    if !success
        println("------------ c1 should unify with c4")
    end

    # X should be bound to house.
    new_X = sr.get_term(c4, 3)
    unifiable, _ = sr.get_binding(new_ss, new_X)
    binding = sr.to_string(unifiable)
    if binding != "house"
        println("------------ X should be bound to 'house'.")
        println("------------ Was: $binding")
    end

    str = sr.to_string(c3)
    if str != "owns(John, car)"
        println("------------ String should be: owns(John, car).")
        println("------------ Was: $str")
    end

    key = sr.get_key(c3)
    if key != "owns/2"
        println("------------ Key must be owns/2. $key")
    end

end  # test_complex

# test_parse_complex - tests to confirm that the function parse_complex()
# parses a complex term, and particularly its argument string, correctly.
# The creation of Atoms, SNumbers, and LogicVars is confirmed.
# Backslashes are used to escape commas.
function test_parse_complex()

    test_name = "Test parse_complex() 1"
    println(test_name)

    # Make complex terms from strings. Test parsing of arguments.
    # Must use a backslash to escape a comma (term 5).
    c, _ = sr.parse_complex("dingo(Arthur, 414, 7.59, \"7.59\", This term\\, has a comma.)")

    fun = sr.get_functor(c)
    if fun.str != "dingo"    # Functor contains a string!
        println("get_functor() - expected: dingo")
        println("                     was: $fun")
    end

    if typeof(fun) != sr.Atom
        println("get_functor() - Invalid functor type.")
        println("                expected: Atom")
        println("                     was: ", typeof(fun))
    end

    term1 = sr.get_term(c, 2)
    if term1.str != "Arthur"
        println("get_term() - Invalid term.")
        println("              expected: Arthur")
        println("                   was: $term1")
    end

    if typeof(term1) != sr.Atom
        println("get_term() - Invalid term type.")
        println("                expected: Atom")
        println("                     was: ", typeof(term1))
    end

    term2 = sr.get_term(c, 3)
    if term2.n != 414   # SNumber - value is in n.
        println("get_term() - Invalid term.")
        println("              expected: 414")
        println("                   was: $term2")
    end

    if typeof(term2) != sr.SNumber
        println("get_term() - Invalid term type (414).")
        println("              expected: SNumber")
        println("                   was: ", typeof(term2))
    end

    term3 = sr.get_term(c, 4)
    if term3.n != 7.59   # SNumber - value is in n.
        println("get_term() - Invalid term.")
        println("              expected: 7.59")
        println("                   was: $term3")
    end

    if typeof(term3) != sr.SNumber
        println("get_term() - Invalid term type (7.59).")
        println("              expected: SNumber")
        println("                   was: ", typeof(term3))
    end

    # Any term enclosed by quotes is an Atom.
    term4 = sr.get_term(c, 5)
    if term4.str != "7.59"
        println("Invalid term. \"7.59\"")
    end

    if typeof(term4) != sr.Atom
        println("Invalid term type. \"7.59\"")
    end

    # Use a backslash to escape characters. In this case, a comma: \,
    term5 = sr.get_term(c, 6)
    if term5.str != "This term, has a comma."
       println("Invalid term. $term5")
    end

    if typeof(term5) != sr.Atom
        println("Invalid term type. $term5")
    end

    c2, _ = sr.parse_complex("double_quote(\\\")")
    quote_term = sr.get_term(c2, 2)

    if quote_term.str != "\""  # Remember!! quote_term is an Atom.
        println("---------- Invalid quote-escape.")
        println("           expected: >\"<")
        println("                was: >$quote_term<")
    end

    test_name = "Test parse_complex() 2"
    println(test_name) #----------------------------------------

    c3, _ = sr.parse_complex("test(\$X, 3.14159, [\"a,b,c\", 3.14159, e | \$Y])")
    functor = sr.get_functor(c3)

    # Check functor.
    expected = "test"
    actual   = functor.str
    if expected != actual
        println("$test_name -")
        println("          expected: $expected")
        println("               was: $actual")
    end


    # Check first term.
    term1  = sr.get_term(c3, 2)
    actual = sr.to_string(term1)
    expected = "\$X"

    tt = typeof(term1)
    if tt != sr.LogicVar
        println("$test_name $actual ---- invalid type.")
        return
    end

    if expected != actual
        println("$test_name -")
        println("            expected: $expected")
        println("                 was: $actual")
    end

    # Check second term.
    term2 = sr.get_term(c3, 3)
    tt = typeof(term2)
    if tt != sr.SNumber
        println("$test_name: $term2")
        println("              expected: SNumber")
        println("                   was: $tt")
        return
    end

    pi::Float64 = 3.14159
    if pi != term2.n
        println("$test_name -")
        println("       expected: %.5f", pi)
        println("            was: %.5f", term2.n)
    end

    # Check third term.
    term3 = sr.get_term(c3, 4)
    tt = typeof(term3)
    if tt != sr.SLinkedList
        println("$test_name: $term3")
        println("            expected: SLinkedList.")
        println("                 was: $tt")
        return
    end

    expected2 = 4
    actual2   = sr.get_count(term3)
    if expected2 != actual2
        msg  = "Expected list length: $expected2"
        msg2 = "                was: $actual2"
        println("Test parse_complex() 2\n $msg $msg2")
    end

    # Analyze the terms of the parsed linked list.
    ll = term3
    expected_terms::Vector{String} = ["a,b,c", "3.14159", "e", "\$Y"]
    expected_types::Vector{Type} = [sr.Atom, sr.SNumber, sr.Atom, sr.LogicVar]

    i = 1
    while !isnothing(ll)
        actual_term = sr.get_term(ll)
        if isnothing(actual_term)
            break
        end
        if expected_terms[i] != sr.to_string(actual_term)
            msg  = "List term, expected: $(expected_terms[i])\n"
            msg2 = "                was: $actual_term"
            println(msg * msg2)
        end

        if expected_types[i] != typeof(actual_term)
            msg  = "Term type, expected: $(expected_types[i])\n"
            msg2 = "                was: $(typeof(actual_term))"
            println(msg * msg2)
        end

        ll = sr.get_next(ll)
        i += 1
    end

    # Check quotation mark errors. ---------------------------
    test_name = "Test parse_complex() 3"
    println(test_name)

    c4, e = sr.parse_complex("func(\"a, b, c\", d, e)")
    if length(e) > 0
        println("func(\"a, b, c\", d, e) should not generate an error.")
    else
        expected = "a, b, c"
        actual = sr.get_term(c4, 2)
        if sr.to_string(actual) != expected
            println("First term should be: $expected")
            println("                 was: $actual")
        end
    end

    _, e = sr.parse_complex("func(\"a, b, c, d, e)")
    check_parse_complex_errors("Unmatched quotes: \"a, b, c, d, e", e)

    _, e = sr.parse_complex("func(a, b\"\", c, d, e)")
    check_parse_complex_errors("Text before opening quote: b\"\"", e)

end   # test_parse_complex()

# check_parse_complex_errors
# Check error messages generated by parse_complex(). If the error message
# does not equal the expected error message, report it.
# Params:
#     expected error message
#     error message
function check_parse_complex_errors(expected::String, actual::String)
    if isnothing(actual)
        println("Should show error message: $expected")
        return
    end
    if actual != expected
        println("Error message should be: $expected")
        println("                    was: $actual")
    end
end  # check_parse_complex_errors
