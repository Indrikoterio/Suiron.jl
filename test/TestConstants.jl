# TestConstants.jl
#
# Test creation and unification of constants (Atoms, SNumber).
#
# Cleve Lendon  2022

function test_atoms()

    println("Test Atoms")
    a1 = sr.Atom("This is an atom.")
    a2 = sr.Atom("This is an atom.")
    a3 = sr.Atom("Just another.")
    ss = sr.SubstitutionSet()
    new_ss, ok = sr.unify(a1, a2, ss)
    if !ok
        println("test_atoms() - Unification must succeed: a1 = a2")
    end
    new_ss, ok = sr.unify(a1, a3, new_ss)
    if ok
        println("test_atoms() - Unification must fail: a1 != a3")
    end
    if length(new_ss) > 0
        println("test_atoms() - Must not change substitution set.")
    end
end

function test_numbers()

    println("Test Numbers")

    i1 = sr.SNumber(45)
    i2 = sr.SNumber(45)
    i3 = sr.SNumber(46)
    ss = sr.SubstitutionSet()

    new_ss, ok = sr.unify(i1, i2, ss)
    if !ok
        println("test_numbers() - Unification must succeed: i1 = i2")
    end
    new_ss, ok = sr.unify(i1, i3, new_ss)
    if ok
        println("test_numbers() - Unification must fail: i1 != i3")
    end
    if length(new_ss) > 0
        println("test_numbers() - Must not change substitution set.")
    end

    a1 = sr.Atom("atom")
    f1 = sr.SNumber(45.0)
    f2 = sr.SNumber(45.0)
    f3 = sr.SNumber(45.0000000001)

    new_ss, ok = sr.unify(f1, f2, ss)
    if !ok
        println("test_numbers() - Unification must succeed: 45.0 = 45.0")
    end
    new_ss, ok = sr.unify(f1, f3, new_ss)
    if ok
        println("test_numbers() - Unification must fail: 45.0 != 45.0000000001")
    end
    new_ss, ok = sr.unify(f1, a1, new_ss)
    if ok
        println("test_numbers() - Unification must fail: 45.0 != atom")
    end
    new_ss, ok = sr.unify(f1, i1, new_ss)
    if !ok
        println("test_numbers() - Unification must succeed: 45.0 == 45")
    end
    if length(new_ss) > 0
        println("test_numbers() - Must not change substitution set.")
    end

end  # TestConstants
