# AllSuironTests.jl
# Tests Suiron functionality.
# Cleve 2022

push!(LOAD_PATH, "..")
push!(LOAD_PATH, ".")

using SuironTests
const st = SuironTests  # abbrev.

st.test_atoms()
st.test_numbers()
st.test_variables()
st.test_complex()
st.test_rules()
st.test_knowledgebase()
st.test_parse_complex()
st.test_linked_lists()
st.test_unification()
st.test_solve()
st.test_backward_chaining()
st.test_and_or()
st.test_built_in_predicates()
st.test_sfunctions()
st.test_arithmetic()
st.test_comparison()
st.test_filter()
st.test_print()
st.test_print_list()
st.test_cut()
st.test_fail()
st.test_append()
st.test_functor()
st.test_join()
st.test_not()
st.test_read_rules()
st.test_time()
