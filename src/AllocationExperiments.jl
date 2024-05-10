module AllocationExperiments

using Allocations
using BenchmarkPlots
using BenchmarkTools
using Distributions: DiscreteUniform
using Graphs
using Gurobi
using JuMP
using Logging
using Random: default_rng, Xoshiro
using StatsPlots: mean

include("tools.jl")
include("consts.jl")
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
    bench_mnw_matroid_asym_lazy_knu74,
    bench_mnw_matroid_lazy_er59,
    bench_mnw_matroid_asym_lazy_er59,
    bench_mnw_unconstrained,
    bench_mms_matroid_lazy_er59,
    bench_mms_matroid_asym_lazy_er59,
    bench_mms_unconstrained,
    rng_with_seed

end # module AllocationExperiments
