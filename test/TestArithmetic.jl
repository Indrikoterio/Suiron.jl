# TestArithmetic.jl
#
# Test built-in arithmetic functions: Add, Subtract, Multiply, Divide.
#
# f(x, y) = ((x + y) - 6) * 3.4 / 3.4
#
# f(3, 7)  = 4
# f(3, -7) = -10
#
# The rule is:
#
# calculate($X, $Y, $Out) :- $A = add($X, $Y),
#                            $B = subtract($A, 6),
#                            $C = multiply($B, 3.4),
#                            $Out = divide($C, 3.4).
# Cleve Lendon
# 2022

function test_arithmetic()

    println("Test Arithmetic")

    sr.set_max_time(0.3)

    i2 = sr.SNumber(2)
    i3 = sr.SNumber(3)
    i5 = sr.SNumber(5)
    pi = sr.SNumber(3.14159)

    kb = sr.KnowledgeBase()

    #------------------------------------
    # First test. Make a rule.
    # test1($X) :- $X = add(2, 3, 5).
    test1 = sr.Atom("test1")
    X     = sr.LogicVar("X")
    head  = sr.SComplex(test1, X)
    body  = sr.Unification(X, sr.Add(i2, i3, i5))
    r     = sr.Rule(head, body)
    sr.add_facts_rules(kb, r)
    
    query = sr.make_query(test1, X)

    solution, failure = sr.solve(query, kb, sr.SubstitutionSet())
    if length(failure) != 0
        println("Test Arithmetic 1 - $failure")
        return
    end

    expected = sr.SNumber(10)
    actual   = sr.get_term(solution, 2)
    if actual == expected
        println("Test Arithmetic 1 - expected: $expected")
        println("                         was: $actual")
    end

    #------------------------------------
    # Second test.
    # test2($X) :- $X = add(2, 3.14159).

    test2 = sr.Atom("test2")
    head  = sr.SComplex(test2, X)
    body  = sr.Unification(X, sr.Add(i2, pi))
    r     = sr.Rule(head, body)
    sr.add_facts_rules(kb, r)

    query = sr.make_query(test2, X)

    solution, failure = sr.solve(query, kb, sr.SubstitutionSet())
    if length(failure) != 0
        println("Test Arithmetic 2 - $failure")
        return
    end

    expected2 = sr.SNumber(5.14159)
    actual2   = sr.get_term(solution, 2)

    if actual2 != expected2
        println("Test Arithmetic 2 - expected: $expected2")
        println("                         was: $actual2")
    end

    #------------------------------------
    # Third test. - test parsing.
    # test3($X) :- $X = add(7.922, 3).

    r, _ = sr.parse_rule("test3(\$X) :- \$X = add(7.922, 3).")
    sr.add_facts_rules(kb, r)
    query, _ = sr.parse_query("test3(\$X)")

    solution, failure = sr.solve(query, kb, sr.SubstitutionSet())
    if length(failure) != 0
        println("Test Arithmetic 3 - $failure")
        return
    end

    expected3 = sr.SNumber(10.922)
    actual3 = sr.get_term(solution, 2)
    if actual3 != expected3
        println("Test Arithmetic 3 - expected: $expected3")
        println("                         was: $actual3")
    end

    #------------------------------------
    # Fourth test. - subtraction.
    # test4($X) :- $X = subtract(5, 3, 2).

    test4 = sr.Atom("test4")
    head  = sr.SComplex(test4, X)

    # Make a subtraction predicate.
    sbtr  = sr.Subtract(sr.SNumber(5), sr.SNumber(3), sr.SNumber(2))

    body  = sr.Unification(X, sbtr)
    r     = sr.Rule(head, body)
    sr.add_facts_rules(kb, r)
    
    query = sr.make_query(test4, X)

    solution, failure = sr.solve(query, kb, sr.SubstitutionSet())
    if length(failure) != 0
        println("Test Arithmetic 4 - $failure")
        return
    end

    expected = sr.SNumber(0)
    actual = sr.get_term(solution, 2)
    if actual != expected
        println("Test Arithmetic 4 - expected: $expected")
        println("                         was: $actual")
    end

    #------------------------------------
    # Fifth test. - subtraction.
    # test5($X) :- $X = subtract(7.5, 2).

    r, _ = sr.parse_rule("test5(\$X) :- \$X = subtract(5.68, 3).")
    sr.add_facts_rules(kb, r)
    query, _ = sr.parse_query("test5(\$X)")

    solution, failure = sr.solve(query, kb, sr.SubstitutionSet())
    if length(failure) != 0
        println("Test Arithmetic 5 - $failure")
        return
    end

    expected5 = 2.68
    actual5 = sr.get_term(solution, 2)
    diff = expected5 - actual5.n

    if abs(diff) > 0.0000000000000005
       println("Test Arithmetic 5 - expected: $expected5")
       println("                         was: $actual5")
    end

    #------------------------------------
    # Sixth test. - multiplication.
    # test6($X) :- $X = multiply(4, 2).

    r, _ = sr.parse_rule("test6(\$X) :- \$X = multiply(4, 2).")
    sr.add_facts_rules(kb, r)
    query, _ = sr.parse_query("test6(\$X)")

    solution, failure = sr.solve(query, kb, sr.SubstitutionSet())
    if length(failure) != 0
        println("Test Arithmetic 6 - $failure")
        return
    end

    expected6 = sr.SNumber(8)
    actual6 = sr.get_term(solution, 2)

    if actual6.n != expected6.n
       println("Test Arithmetic 6 - expected: $expected6")
       println("                         was: $actual6")
    end

    #------------------------------------
    # Seventh test. - multiplication.
    # test7($X) :- $X = multiply(3.14159, 2).

    r, _ = sr.parse_rule("test7(\$X) :- \$X = multiply(3.14159, 2).")
    sr.add_facts_rules(kb, r)
    query, _ = sr.parse_query("test7(\$X)")

    solution, failure = sr.solve(query, kb, sr.SubstitutionSet())
    if length(failure) != 0
        println("Test Arithmetic 7 - $failure")
        return
    end

    expected7 = sr.SNumber(3.14159 * 2)
    actual7 = sr.get_term(solution, 2)

    diff = expected7.n - actual7.n

    if abs(diff) > 0.0000000000000005
       println("Test Arithmetic 7 - expected: $expected7")
       println("                         was: $actual7")
    end

    #------------------------------------
    # Eighth test. - divide.
    # test8($X) :- $X = divide(4, 2).

    r, _ = sr.parse_rule("test8(\$X) :- \$X = divide(4, 2).")
    sr.add_facts_rules(kb, r)
    query, _ = sr.parse_query("test8(\$X)")

    solution, failure = sr.solve(query, kb, sr.SubstitutionSet())
    if length(failure) != 0
        println("Test Arithmetic 8 - $failure")
        return
    end

    expected8 = 2
    actual8 = sr.get_term(solution, 2)

    diff = expected8 - actual8.n

    if abs(diff) > 0.0000000000000005
       println("Test Arithmetic 8 - expected: $expected8")
       println("                         was: $actual8")
    end

    #------------------------------------
    # Ninth test. - a formula.
    # test9($X) :- $X = divide(4, 2).
    #
    # f(x, y) = ((x + y) - 6) * 3.4 / 3.4
    #
    # f(3, 7)  = 4
    # f(3, -7) = -10
    #
    # The rule is:
    #
    # calculate($X, $Y, $Out) :- $A = add($X, $Y),
    #                            $B = subtract($A, 6),
    #                            $C = multiply($B, 3.4),
    #                            $Out = divide($C, 3.4).

    Y   = sr.LogicVar("Y")
    A   = sr.LogicVar("A")
    B   = sr.LogicVar("B")
    C   = sr.LogicVar("C")
    Out = sr.LogicVar("Out")

    head, _ = sr.parse_complex("calculate(\$X, \$Y, \$Out)")
    u1 = sr.Unification(A, sr.Add(X, Y))
    u2 = sr.Unification(B, sr.Subtract(A, sr.SNumber(6)))
    u3 = sr.Unification(C, sr.Multiply(B, sr.SNumber(3.4)))
    u4 = sr.Unification(Out, sr.Divide(C, sr.SNumber(3.4)))

    r = sr.Rule(head, sr.SOperator(:AND, u1, u2, u3, u4))
    sr.add_facts_rules(kb, r)

    calc, _ = sr.parse_query("calculate(3.0, 7.0, \$Out)")

    solution, failure = sr.solve(calc, kb, sr.SubstitutionSet())
    if length(failure) != 0
        println("Test Arithmetic 9 - $failure")
        return
    end

    expected9 = sr.SNumber(4)
    actual9   = sr.get_term(solution, 4)

    diff = expected9.n - actual9.n

    if abs(diff) > 0.0000000000000005
       println("Test Arithmetic 9 - expected: $expected9")
       println("                         was: $actual9")
    end

end # test_arithmetic
