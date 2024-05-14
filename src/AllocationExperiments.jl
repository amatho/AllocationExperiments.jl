module AllocationExperiments

using Allocations
using BenchmarkPlots
using BenchmarkTools
using Distributions: DiscreteUniform
using Graphs
using Gurobi
import JSON
using JuMP
using Logging
using Random: default_rng, Xoshiro
using StatsPlots: mean

include("tools.jl")
include("consts.jl")
include("types.jl")
include("experiments.jl")


function __init__()
    global GRB_ENV_REF
    GRB_ENV_REF[] = Gurobi.Env()

    debug_logger = Logging.ConsoleLogger(Logging.Info)
    Logging.global_logger(debug_logger)

    return
end


export
    Experiment,
    mnw_matroid_lazy_knu74,
    mnw_matroid_asym_lazy_knu74,
    mnw_matroid_lazy_er59,
    mnw_matroid_asym_lazy_er59,
    mnw_unconstrained,
    mms_matroid_lazy_er59,
    mms_matroid_asym_lazy_er59,
    mms_unconstrained,
    rng_with_seed,
    save,
    load

end # module AllocationExperiments
