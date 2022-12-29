# TestBackwardChaining.jl
#
# Test the backward chaining functionality of the inference engine.
#
# Cleve Lendon
# 2022

function test_backward_chaining()

    println("Test Backward Chaining")

    kb = sr.KnowledgeBase()
    ss = sr.SubstitutionSet()

    # Create logic variables.
    X = sr.LogicVar("X")
    Y = sr.LogicVar("Y")
    Z = sr.LogicVar("Z")

    parent   = sr.Atom("parent")
    ancestor = sr.Atom("ancestor")
    charles  = sr.Atom("Charles")
    tony     = sr.Atom("Tony")
    maria    = sr.Atom("Maria")
    bill     = sr.Atom("Bill")
    audrey   = sr.Atom("Audrey")

    # Create a few facts.
    c1 = sr.SComplex(parent, bill, audrey)   # parent(Bill, Audrey)
    c2 = sr.SComplex(parent, maria, bill)    # parent(Maria, Bill)
    c3 = sr.SComplex(parent, tony, maria)
    c4 = sr.SComplex(parent, charles, tony)

    f1 = sr.Fact(c1)
    f2 = sr.Fact(c2)
    f3 = sr.Fact(c3)
    f4 = sr.Fact(c4)

    # Register the above facts in the knowledge base.
    sr.add_facts_rules(kb, f1, f2, f3, f4)

    head = sr.SComplex(ancestor, X, Y)
    c5   = sr.SComplex(parent, X, Y)
    c6   = sr.SComplex(parent, X, Z)
    c7   = sr.SComplex(ancestor, Z, Y)

    # ancestor($X, $Y) = parent($X, $Y) 
    r1 = sr.Rule(head, c5)

    # ancestor($X, $Y) = parent($X, $Z), ancestor($Z, $Y).
    body = sr.SOperator(:AND, c6, c7)
    r2 = sr.Rule(head, body)

    # Register the above rules in the knowledge base.
    sr.add_facts_rules(kb, r1, r2)

    query = sr.make_query(ancestor, charles, Y)

    # Check the solutions of ancestor(Charles, $Y).
    expected::Vector{String} = ["ancestor(Charles, Tony)",
                                "ancestor(Charles, Maria)",
                                "ancestor(Charles, Bill)",
                                "ancestor(Charles, Audrey)"]

    solutions, failure = sr.solve_all(query, kb, ss)
    if length(failure) != 0
        println("Test Backward Chaining - $failure")
    end

    for (i, r) = enumerate(solutions)
        s = sr.to_string(r)
        if s != expected[i]
            println("Test Backward Chaining - expected: $(expected[i])")
            println("                              was: $s")
        end
    end

end # test_backward_chaining
