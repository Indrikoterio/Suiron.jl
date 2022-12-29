# TestPrint.jl - Tests 'print' predicate.
#
# Cleve Lendon 2022

function test_print()

    #----------------------------------------------------
    println("Test Print 1:")
    println("Persian, king, [Cyrus, Cambysis, Darius]")

    persian = sr.Atom("Persian")
    king    = sr.Atom("king")
    K1 = sr.Atom("Cyrus")
    K2 = sr.Atom("Cambysis")
    K3 = sr.Atom("Darius")
    print_test = sr.Atom("print_test")

    list = sr.make_linked_list(false, K1, K2, K3)

    X = sr.LogicVar("X")
    Y = sr.LogicVar("Y")

    ss = sr.SubstitutionSet()

    # print_test :- $X = king, $Y = [Cyrus, Cambysis, Darius], print(persian, $X, $Y), nl.
    head = sr.SComplex(print_test)
    c2   = sr.Unification(X, king)
    c3   = sr.Unification(Y, list)
    c4   = sr.Print(persian, X, Y)
    body = sr.SOperator(:AND, c2, c3, c4, sr.NL())

    # Set up the knowledge base.
    kb = sr.KnowledgeBase()
    r1 = sr.Rule(head, body)

    sr.add_facts_rules(kb, r1)
    sr.set_max_time(1.2)

    query = sr.make_query(print_test)
    _, failure = sr.solve(query, kb, ss)
    if length(failure) != 0
        println("Test Print - $failure")
    end

    #----------------------------------------------------
    println("Test Print 2:")
    println("Hello World, my name is Cleve.")

    world = sr.Atom("World")
    cleve = sr.Atom("Cleve")

    format_string = sr.Atom("Hello %s, my name is %s.\n")
    print_test2 = sr.Atom("print_test2")
    c5 = sr.SComplex(print_test2)
    c6 = sr.Print(format_string, world, cleve)
    r2 = sr.Rule(c5, c6)
    sr.add_facts_rules(kb, r2)

    query = sr.make_query(print_test2)
    _, failure = sr.solve(query, kb, ss)

    if length(failure) != 0
        println("Test Print - $failure")
    end

end  # test_print
