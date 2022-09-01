# Timeout.jl - functions for measuring elapsed execution time.
#
# Cleve Lendon
# 2022

suiron_max_time = 0.3    # Maximum time in seconds
suiron_start_time = 0
suiron_stop_query = false

# set_max_time - sets the maximum duration for query search.
# Params: maximum time in seconds (Float)
function set_max_time(max::Number)
    global suiron_max_time = max
    global suiron_stop_query = false
end

# set_start_time - sets the start time before starting the query.
function set_start_time()
    global suiron_start_time = round(Int64, time() * 1_000_000) # microseconds
    global suiron_stop_query = false
end

# elapsed_time
# Calculates time since the start of the query and
# displays the result.
function elapsed_time()
    now = round(Int64, time() * 1_000_000) # microseconds
    delta::Int64 = now - suiron_start_time
    d = round(Int64, delta / 1000)
    println("Elapsed time: $d")
end
