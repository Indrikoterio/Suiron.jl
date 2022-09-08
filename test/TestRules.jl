# TestRules.jl
#
# Test creation of logic rules.
#
# Cleve Lendon 2022

function test_rules()

    println("Test Rules")

    # grandparent($X, $Y) :- parent($X, $Z), parent($Z, $Y).

    grandparent = sr.Atom("grandparent")
    parent      = sr.Atom("parent")
    X = sr.LogicVar("X")
    Y = sr.LogicVar("Y")
    Z = sr.LogicVar("Z")

    c1 = sr.SComplex(grandparent, X, Y)
    c2 = sr.SComplex(parent, X, Z)
    c3 = sr.SComplex(parent, Z, Y)

    andOp = sr.SOperator(:AND, c2, c3)
    r1 = sr.Rule(c1, andOp)

    expected = "grandparent($X, $Y) :- and(parent($X, $Z), parent($Z, $Y))."
    actual = sr.to_string(r1)
    if actual != expected
        println("Rule should be: $expected\n           was: $actual")
    end

end  # test_rules()
