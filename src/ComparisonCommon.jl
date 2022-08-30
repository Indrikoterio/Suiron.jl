# ComparisonCommon.jl - This file contains functions which are common
# to all mathematical comparison functions (<= >= < > == etc.).
#
#     parseComparison()
#     getTermsToCompare()
#     twoFloats()
#     comparison_string()
#
# Cleve Lendon

const NOT_GROUND     = "Cannot compare. Variable is not grounded: "
const NOT_NUMBER     = "Cannot compare. Not a number: "
const CANNOT_COMPARE = "Cannot compare. Invalid term type: "


# compareAtoms - does a string compare on Atoms. Returns -1 for less
# than, 0 for equal, and 1 for greater than. If one of the terms is an
# Integer or a Float, it must be converted to an Atom for the comparison.
# If one of the terms is not an Atom, Integer or Float, the function
# will cause a panic.
# Params: term1
#         type of term 1
#         term2
#         type of term 2
# Return: result (-1, 0, 1)
func compareAtoms(term1 Unifiable, type1 int,
                  term2 Unifiable, type2 int) int {

    var a1, a2 Atom

    if type1 == ATOM {
        a1 = term1.(Atom)
    } else {
        if type1 == INTEGER {
            a1 = Atom(fmt.Sprintf("%d", term1.(Integer)))
        } else if type1 == FLOAT {
            a1 = Atom(fmt.Sprintf("%f", term1.(Float)))
        } else {
            msg = fmt.Sprintf(errCannotCompare, term1, term1)
            panic(msg)
        }
    }

    if type2 == ATOM {
        a2 = term2.(Atom)
    } else {
        if type2 == INTEGER {
            a2 = Atom(fmt.Sprintf("%d", term2.(Integer)))
        } else if type2 == FLOAT {
            a2 = Atom(fmt.Sprintf("%f", term2.(Float)))
        } else {
            msg = fmt.Sprintf(errCannotCompare, term2, term2)
            panic(msg)
        }
    }

    return strings.Compare(string(a1), string(a2))

end  # compareAtoms
