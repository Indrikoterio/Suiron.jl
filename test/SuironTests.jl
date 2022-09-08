__precompile__(true)
module SuironTests  # Tests for the Suiron inference engine.  Cleve Lendon 2022

using Suiron
const sr = Suiron  # A short prefix.

include("./TestAndOr.jl")
include("./TestAppend.jl")
include("./TestArithmetic.jl")
include("./TestBackwardChaining.jl")
include("./TestBuiltInPreds.jl")
include("./TestComparison.jl")
include("./TestComplex.jl")
include("./TestConstants.jl")
include("./TestRules.jl")
include("./TestKnowledgeBase.jl")
include("./TestCut.jl")
include("./TestFail.jl")
include("./TestFilter.jl")
include("./TestFunctor.jl")
include("./TestLinkedLists.jl")
include("./TestPrint.jl")
include("./TestPrintList.jl")
include("./TestSFunctions.jl")
include("./TestSolve.jl")
include("./TestUnification.jl")
include("./TestVariables.jl")
include("./TestJoin.jl")
include("./TestNot.jl")
include("./TestTime.jl")
include("./TestReadRules.jl")
include("./TooLong.jl")

function __init__()
    println("SuironTests has loaded.")
end

end  # module
