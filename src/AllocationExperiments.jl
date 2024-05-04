module AllocationExperiments

using Allocations
using AllocationInstances
using BenchmarkTools
using Distributions: DiscreteUniform
using Gurobi
using JuMP
using Logging
using Random: default_rng, Xoshiro

include("consts.jl")
include("tools.jl")
include("bench.jl")


function __init__()
    global GRB_ENV_REF
    GRB_ENV_REF[] = Gurobi.Env()

    debug_logger = Logging.ConsoleLogger(Logging.Info)
    Logging.global_logger(debug_logger)

    return
end


export
    bench_mnw_matroid_lazy_knu74,
    bench_mnw_matroid_lazy_ws98,
    bench_mnw_matroid_bases_knu74,
    bench_mnw_unconstrained,
    rng_with_seed

end # module AllocationExperiments
