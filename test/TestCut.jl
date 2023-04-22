# TestComparison.jl - Test the cut operator.
#
# Cleve Lendon  2022

function test_cut()

    println("Test Cut")

    kb = sr.KnowledgeBase()
    ss = sr.SubstitutionSet()

    #= Test this rule:
        cut_rule :- !, a = b.  % This fails.
        cut_rule :- print(*** This should NOT print. ***).
        cut_rule(OK).
        test($X) :- cut_rule, $X = Bad.
        test($X) :- cut_rule($X).
       Note: cut_rule/0 and cut_rule/1 are two different rules.
    =#

    # Set up facts and rules.

    cut  = sr.SOperator(:CUT)

    c1 = sr.SComplex(sr.Atom("cut_rule"))
    a1 = sr.SOperator(:AND, cut, sr.Unification(sr.Atom("a"), sr.Atom("b")))
    a2 = sr.Print(sr.Atom("*** This should NOT print. ***"))
    r1 = sr.Rule(c1, a1)  # cut_rule :- !, a = b.
    r2 = sr.Rule(c1, a2)  # cut_rule :- print(*** This should NOT print. ***).
    c2 = sr.SComplex(sr.Atom("cut_rule"), sr.Atom("OK"))
    f1 = sr.Fact(c2)  # cut_rule(OK).

    X  = sr.LogicVar("X")
    c3 = sr.SComplex(sr.Atom("test"), X)
    c4 = sr.SComplex(sr.Atom("cut_rule"))
    a3 = sr.SOperator(:AND, c4, sr.Unification(X, sr.Atom("Bad")))
    r3 = sr.Rule(c3, a3)   # test($X) :- cut_rule, $X = Bad.
    c5 = sr.SComplex(sr.Atom("cut_rule"), X)
    r4 = sr.Rule(c3, c5)   # test($X) :- cut_rule($X).
    sr.add_facts_rules(kb, r1, r2, f1, r3, r4)

    #DBKB(kb)
    query = sr.make_query(sr.Atom("test"), X)
    sr.set_max_time(3.0)

    solutions, failure = sr.solve_all(query, kb, ss)

    if failure != ""
        println("Test Cut - $failure")
        return
    end

    len = length(solutions)
    if len != 1
        println("Test Cut - expected 1 result. There were ", len, ".")
        return
    end

    solution1 = solutions[1]
    result = sr.to_string(sr.get_term(solution1, 2))
    expected = "OK"
    if result != expected
        println("Test Cut - expected: $expected")
        println("                was: $result")
    end

    #=
       handicapped(John).
       handicapped(Mary).
       has_small_children(Mary).
       is_elderly(Diane)
       is_elderly(John)
       priority_seating($Name, $YN) :- handicapped($Name), $YN = Yes, !.
       priority_seating($Name, $YN) :- has_small_children($Name), $YN = Yes, !.
       priority_seating($Name, $YN) :- is_elderly($Name), $YN = Yes, !.
       priority_seating($Name, No).
    =#

    handicapped        = sr.Atom("handicapped")
    has_small_children = sr.Atom("has_small_children")
    is_elderly         = sr.Atom("is_elderly")
    priority_seating   = sr.Atom("priority_seating")
    yes                = sr.Atom("Yes")
    no                 = sr.Atom("No")

    John  = sr.Atom("John")
    Mary  = sr.Atom("Mary")
    Diane = sr.Atom("Diane")

    Name = sr.LogicVar("Name")
    YN   = sr.LogicVar("YN")

    d1 = sr.SComplex(handicapped, John)
    d2 = sr.SComplex(handicapped, Mary)
    d3 = sr.SComplex(has_small_children, Mary)
    d4 = sr.SComplex(is_elderly, Diane)
    d5 = sr.SComplex(is_elderly, John)

    fact1 = sr.Fact(d1)
    fact2 = sr.Fact(d2)
    fact3 = sr.Fact(d3)
    fact4 = sr.Fact(d4)
    fact5 = sr.Fact(d5)

    sr.add_facts_rules(kb, fact1, fact2, fact3, fact4, fact5)

    h1 = sr.SComplex(priority_seating, Name, YN)
    b1 = sr.SOperator(:AND, sr.SComplex(handicapped, Name), sr.Unification(YN, yes), cut)
    rule1 = sr.Rule(h1, b1)

    h2 = sr.SComplex(priority_seating, Name, YN)
    b2 = sr.SOperator(:AND, sr.SComplex(has_small_children, Name), sr.Unification(YN, yes), cut)
    rule2 = sr.Rule(h2, b2)

    h3 = sr.SComplex(priority_seating, Name, YN)
    b3 = sr.SOperator(:AND, sr.SComplex(is_elderly, Name), sr.Unification(YN, yes), cut)
    rule3 = sr.Rule(h3, b3)

    h4 = sr.SComplex(priority_seating, Name, no)
    fact6 = sr.Fact(h4)

    sr.add_facts_rules(kb, rule1, rule2, rule3, fact6)
    query = sr.make_query(priority_seating, John, X)

    solutions, failure = sr.solve_all(query, kb, ss)

    if failure != ""
        println("Test Cut - $failure")
        return
    end

    solution1 = solutions[1]
    result2 = sr.to_string(sr.get_term(solution1, 3))

    expected2 = "Yes"
    if result2 != expected2
        println("Test Cut - expected: $expected2")
        println("                was: $result2")
    end

    #= Another test:

          get_value($X) :- $X = 1.
          get_value($X) :- $X = 2.
          another_test($X) :- get_value($X), !, $X == 2.

       When the inference engine is queried with 'another_test($X)',
       it should returns no solutions.
    =#

    get_value    = sr.Atom("get_value")
    another_test = sr.Atom("another_test")
    X  = sr.LogicVar("X")

    # get_value($X) :- $X = 1.
    head1 = sr.SComplex(get_value, X)
    n1 = sr.SNumber(1)
    body1 = sr.Unification(X, n1)
    rule1 = sr.Rule(head1, body1)

    # get_value($X) :- $X = 2.
    head2 = sr.SComplex(get_value, X)
    n2 = sr.SNumber(2)
    body2 = sr.Unification(X, n2)
    rule2 = sr.Rule(head2, body2)

    # another_test($X) :- get_value($X), !, $X = 2.
    head3 = sr.SComplex(another_test, X)
    c = sr.SComplex(get_value, X)
    uni = sr.Unification(X, n2)
    body = sr.SOperator(:AND, c, cut, uni)
    rule3 = sr.Rule(head3, body)

    sr.add_facts_rules(kb, rule1, rule2, rule3)
    query = sr.make_query(another_test, X)

    solutions, failure = sr.solve_all(query, kb, ss)

    if failure != "No"
        println("Test Cut - Error: Query should produce no solutions. - $solutions")
        return
    end

end  # test_cut
