# TestKnowledgeBase.jl
#
# The knowledge base is a dictionary which holds facts and rules.
#
# The dictionary is indexed by a key, which is created from the functor
# and arity. For example, for the fact mother(Carla, Caitlyn), the key
# would be "mother/2".
#
# Each key indexes an array of Rules which have the same key.
#
# Cleve Lendon
# 2022

function test_knowledgebase()

    println("Test KnowledgeBase")

    sr.set_max_time(0.5)

    kb = sr.KnowledgeBase()

    age = sr.Atom("age")
    loves = sr.Atom("loves")
    #vehicle = sr.Atom("vehicle")

    n1 = sr.Atom("Ross")
    n2 = sr.Atom("Rachel")
    n3 = sr.Atom("Chandler")
    n4 = sr.Atom("Monica")
    a1 = sr.SNumber(27)
    a2 = sr.SNumber(28)

    # ages
    c1 = sr.SComplex(age, n1, a1)
    c2 = sr.SComplex(age, n2, a2)
    c3 = sr.SComplex(age, n3, a2)
    c4 = sr.SComplex(age, n4, a1)

    # loves
    c5 = sr.SComplex(loves, n1, n2)
    c6 = sr.SComplex(loves, n2, n1)
    c7 = sr.SComplex(loves, n3, n4)
    c8 = sr.SComplex(loves, n4, n3)

    x  = sr.LogicVar("X")
    y  = sr.LogicVar("Y")
    c9 = sr.SComplex(loves, x, y)

    # Facts are rules.
    sr.add_facts_rules(kb, sr.Fact(c1))
    sr.add_facts_rules(kb, sr.Fact(c2))
    sr.add_facts_rules(kb, sr.Fact(c3))
    sr.add_facts_rules(kb, sr.Fact(c4))
    sr.add_facts_rules(kb, sr.Fact(c5))
    sr.add_facts_rules(kb, sr.Fact(c6))
    sr.add_facts_rules(kb, sr.Fact(c7))
    sr.add_facts_rules(kb, sr.Fact(c8))

    expected = """

------- Contents of Knowledge Base -------
age/2
   age(Ross, 27).
   age(Rachel, 28).
   age(Chandler, 28).
   age(Monica, 27).
loves/2
   loves(Ross, Rachel).
   loves(Rachel, Ross).
   loves(Chandler, Monica).
   loves(Monica, Chandler).
------------------------------------------
"""   #------------------------End of expected

    actual = sr.to_string(kb)
    if actual != expected
        println("KnowledgeBase is different than expected.", actual)
    end

    expected = "loves(Rachel, Ross)."
    rule1 = sr.get_rule(kb, c9, 2)
    actual = sr.to_string(rule1)

    if actual != expected
        println("get_rule(), expected: $expected")
        println("                 was: $actual")
    end

end  # TestKnowledgeBase
