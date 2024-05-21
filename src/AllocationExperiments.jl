module AllocationExperiments

using Allocations
using BenchmarkPlots
using BenchmarkTools
using Distributions: DiscreteUniform
using Graphs
using Gurobi
using HiGHS
import JSON
using JuMP
using Logging
using Random: default_rng, Xoshiro
using StatsPlots: mean

include("tools.jl")
include("consts.jl")
include("types.jl")
include("alloc_loop.jl")
include("experiments.jl")

export
    Experiment,
    MultiExperiment,
    mnw_matroid_lazy_knu74,
    mnw_matroid_lazy_knu74_asym,
    mnw_matroid_lazy_knu74_ranks,
    mnw_matroid_lazy_er59,
    mnw_matroid_lazy_er59_asym,
    mnw_matroid_loop_knu74,
    mnw_matroid_loop_knu74_asym,
    mnw_matroid_loop_er59,
    mnw_matroid_loop_er59_asym,
    mnw_matroid_loop_knu74_highs,
    mnw_matroid_loop_knu74_asym_highs,
    mnw_matroid_loop_er59_highs,
    mnw_matroid_loop_er59_asym_highs,
    mnw_unconstrained,
    mms_matroid_lazy_er59,
    mms_matroid_lazy_er59_asym,
    mms_unconstrained,
    rng_with_seed,
    save,
    load,
    mergefiles

end # module AllocationExperiments
