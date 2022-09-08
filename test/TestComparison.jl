# TestComparison.jl
#
# Test the built-in comparison predicates: > >= == <= <
# Eg.:
#    .., $X <= 23,...
#
# Cleve Lendon 2022

function test_comparison()

    println("Test Comparison")

    sr.set_max_time(2.0)

    X = sr.LogicVar("X")
    Y = sr.LogicVar("Y")
    Z = sr.LogicVar("Z")

    anon = sr.Anonymous()
    cut  = sr.SOperator(:CUT)

    passed   = sr.Atom("passed")
    failed   = sr.Atom("failed")
    Beth     = sr.Atom("Beth")
    Albert   = sr.Atom("Albert")
    Samantha = sr.Atom("Samantha")
    Trevor   = sr.Atom("Trevor")
    Joseph   = sr.Atom("Joseph")

    test = sr.Atom("test")
    test_greater_than          = sr.Atom("test_greater_than")
    test_greater_than_or_equal = sr.Atom("test_greater_than_or_equal")
    test_less_than             = sr.Atom("test_less_than")
    test_less_than_or_equal    = sr.Atom("test_less_than_or_equal")
    test_equal                 = sr.Atom("test_equal")

    kb = sr.KnowledgeBase()
    ss = sr.SubstitutionSet()

    head = sr.SComplex(test_greater_than, X, Y, Z)
    body = sr.SOperator(:AND, sr.GreaterThan(X, Y), cut, sr.Unification(Z, passed))
    r1 = sr.Rule(head, body)

    head = sr.SComplex(test_greater_than, anon, anon, Z)
    body2 = sr.Unification(Z, failed)
    r2 = sr.Rule(head, body2)

    head = sr.SComplex(test_less_than, X, Y, Z)
    body3 = sr.SOperator(:AND, sr.LessThan(X, Y), cut, sr.Unification(Z, passed))
    r3 = sr.Rule(head, body3)

    head = sr.SComplex(test_less_than, anon, anon, Z)
    body4 = sr.Unification(Z, failed)
    r4 = sr.Rule(head, body4)

    head = sr.SComplex(test_greater_than_or_equal, X, Y, Z)
    body5 = sr.SOperator(:AND, sr.GreaterThanOrEqual(X, Y), cut, sr.Unification(Z, passed))
    r5 = sr.Rule(head, body5)

    head = sr.SComplex(test_greater_than_or_equal, anon, anon, Z)
    body6 = sr.Unification(Z, failed)
    r6 = sr.Rule(head, body6)

    head = sr.SComplex(test_less_than_or_equal, X, Y, Z)
    body7 = sr.SOperator(:AND, sr.LessThanOrEqual(X, Y), cut, sr.Unification(Z, passed))
    r7 = sr.Rule(head, body7)

    head = sr.SComplex(test_less_than_or_equal, anon, anon, Z)
    body8 = sr.Unification(Z, failed)
    r8 = sr.Rule(head, body8)

    head = sr.SComplex(test_equal, X, Y, Z)
    body9 = sr.SOperator(:AND, sr.Equal(X, Y), cut, sr.Unification(Z, passed))
    r9 = sr.Rule(head, body9)

    head = sr.SComplex(test_equal, anon, anon, Z)
    body10 = sr.Unification(Z, failed)
    r10 = sr.Rule(head, body10)

    head = sr.SComplex(test, Z)

    body11 = sr.SComplex(test_greater_than, sr.SNumber(4), sr.SNumber(3), Z)
    r11 = sr.Rule(head, body11)
    body12 = sr.SComplex(test_greater_than, Beth, Albert, Z)
    r12 = sr.Rule(head, body12)
    body13 = sr.SComplex(test_greater_than, sr.SNumber(2), sr.SNumber(3), Z)
    r13 = sr.Rule(head, body13)

    body14 = sr.SComplex(test_less_than, sr.SNumber(1.6), sr.SNumber(7.2), Z)
    r14 = sr.Rule(head, body14)
    body15 = sr.SComplex(test_less_than, Samantha, Trevor, Z)
    r15 = sr.Rule(head, body15)
    body16 = sr.SComplex(test_less_than, sr.SNumber(4.222), sr.SNumber(4.), Z)
    r16 = sr.Rule(head, body16)

    body17 = sr.SComplex(test_greater_than_or_equal, sr.SNumber(4), sr.SNumber(4.0), Z)
    r17 = sr.Rule(head, body17)
    body18 = sr.SComplex(test_greater_than_or_equal, Joseph, Joseph, Z)
    r18 = sr.Rule(head, body18)
    body19 = sr.SComplex(test_greater_than_or_equal, sr.SNumber(3.9), sr.SNumber(4.0), Z)
    r19 = sr.Rule(head, body19)

    body20 = sr.SComplex(test_less_than_or_equal, sr.SNumber(7.000), sr.SNumber(7), Z)
    r20 = sr.Rule(head, body20)
    body21 = sr.SComplex(test_less_than_or_equal, sr.SNumber(7.000), sr.SNumber(7.1), Z)
    r21 = sr.Rule(head, body21)
    body22 = sr.SComplex(test_less_than_or_equal, sr.SNumber(0.0), sr.SNumber(-20), Z)
    r22 = sr.Rule(head, body22)

    body23 = sr.SComplex(test_equal, Joseph, Joseph, Z)
    r23 = sr.Rule(head, body23)
    body24 = sr.SComplex(test_equal, Joseph, Trevor, Z)
    r24 = sr.Rule(head, body24)

    sr.add_facts_rules(kb, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12)
    sr.add_facts_rules(kb, r13, r14, r15, r16, r17, r18, r19, r20, r21, r22, r23, r24)

    goal, _ = sr.parse_goal("test(\$Z)")

    solutions, failure = sr.solve_all(goal, kb, ss)

    if length(failure) != 0
        println("Test Comparison - $failure")
    end

    expected::Vector{String} = [
                         "passed", "passed", "failed",
                         "passed", "passed", "failed",
                         "passed", "passed", "failed",
                         "passed", "passed", "failed",
                         "passed", "failed"
                       ]

    len1 = length(expected)
    len2 = length(solutions)
    if len1 != len2
        println("Test Comparison - not enough solutions, expected: $len1")
        println("                                             was: $len2")
    end

    for (i, r) = enumerate(solutions)
        s = sr.to_string(sr.get_term(r, 2))
        if s != expected[i]
            println("Test Comparison - expected: $(expected[i])")
            println("                       was: $s")
        end
    end

end  # test_comparison
