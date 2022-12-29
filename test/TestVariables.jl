# TestVariables.jl
#
# Tests creation and unification of Logic Variables.
#
# Note: In a Suiron source file, variables are prefixed with
# a dollar sign, eg. $X, $Y. This works well in the Go version
# of Suiron. Unfortunately, Julia uses the dollar sign for string
# interpolation, eg. "The number is $num" .
#
# Therefore, when creating a logic variable in Julia code,
# the following function,
#    X = LogicVar("$X")
# will cause the compiler to throw an error:
#    LoadError: UndefVarError: X not defined
#
# To circumvent this issue, the dollar sign can dropped.
#    X = LogicVar("X")
#
# This doesn't work for other parsing functions. The following
# function,
#    parse_complex("father($X, Luke)")
# will also throw an UndefVarError error.
#
# The dollar sign can be escaped with a backslash.
#    parse_complex("father(\$X, Luke)")
# Alternatively, the dollar sign can be replaced by a percent sign.
#    parse_complex("father(%X, Luke)")
#
# Cleve Lendon
# 2022

function test_variables()

    # vars - Keeps track of previously recreated variables.
    vars = sr.DictLogicVars()

    println("Test Variables")

    sr.set_max_time(0.26)

    # In a text file, logic variables are defined with a dollar
    # sign, eg., $X. when declaring a LogicVar in Julia source
    # code, the dollar sign must be escaped (\$) or omitted. The
    # dollar sign will be displayed if the variable is printed.
    W = sr.LogicVar("\$W")
    W = sr.recreate_variables(W, vars)
    X = sr.LogicVar("%X")     # try percent sign
    X = sr.recreate_variables(X, vars)
    Y = sr.LogicVar("Y")      # omit $
    Y = sr.recreate_variables(Y, vars)
    Z = sr.LogicVar("Z")
    Z = sr.recreate_variables(Z, vars)

    age = sr.SNumber(43)
    pi  = sr.SNumber(3.14159)

    pronoun = sr.Atom("pronoun")
    me      = sr.Atom("me")
    first   = sr.Atom("first")
    sing    = sr.Atom("singular")
    acc     = sr.Atom("accusative")

    person    = sr.LogicVar("Person")
    plurality = sr.LogicVar("Plurality")
    case_     = sr.LogicVar("Case")

    new_ss, ok = sr.unify(X, X, Vector{sr.Unifiable}())
    if !ok
        println("Test Variables - unification should succeed: \$X = \$X")
    end

    new_ss, ok = sr.unify(X, Y, new_ss)
    if !ok
        println("Test Variables - unification should succeed: \$X = \$Y")
    end

    new_ss, ok = sr.unify(Y, pronoun, new_ss)
    if !ok
        println("Test Variables - unification should succeed: \$Y = pronoun")
    end

    new_ss, ok = sr.unify(Z, age, new_ss)
    if !ok
        println("Test Variables - unification should succeed: \$Z = 43")
    end

    new_ss, ok = sr.unify(W, pi, new_ss)
    if !ok
        println("Test Variables - unification should succeed: \$W = 3.14159")
    end

    new_ss, ok = sr.unify(Z, W, new_ss)
    if ok
        println("Test Variables - unification should not succeed: \$Z = \$W")
    end

    c1 = sr.make_query(pronoun, me, first, sing, acc)
    c2 = sr.make_query(pronoun, me, person, plurality, case_)

    # Unify complex terms.
    new_ss, ok = sr.unify(c1, c2, sr.SubstitutionSet())
    if !ok
        println("Test Variables - unification should succeed: c1 = c2")
    end

    expected = "pronoun(me, first, singular, accusative)"
    actual = sr.to_string(sr.replace_variables(c2, new_ss))

    if cmp(actual, expected) != 0
        println("Test Variables - failed to unify complex terms.\n",
                "actual:    ", actual,
                "\nexpected:  ", expected)
    end
end