module AllocationExperiments

using Allocations
using BenchmarkPlots
using BenchmarkTools
using DataFrames
using Distributions: DiscreteUniform
using Graphs
using Gurobi
using HiGHS
using JLD2
using JuMP
using Logging
using Random: default_rng, Xoshiro
using StatsPlots
using Unitful

include("types.jl")
include("tools.jl")
include("consts.jl")
include("alloc_loop.jl")
include("experiments.jl")
include("plot.jl")

export
    Experiment,
    MultiExperiment,
    CONF,
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
    mnw_unconstrained_ranks_comparison,
    mms_matroid_lazy_knu74,
    mms_matroid_lazy_knu74_asym,
    mms_matroid_lazy_er59,
    mms_matroid_lazy_er59_asym,
    mms_unconstrained,
    rnd_matroid_lazy_knu74,
    rnd_matroid_lazy_knu74_asym,
    rnd_matroid_lazy_knu74_ranks,
    rnd_matroid_lazy_er59,
    rnd_matroid_lazy_er59_asym,
    rnd_unconstrained,
    rnd_unconstrained_ranks_comparison,
    set_log_each,
    rng_with_seed,
    save,
    load,
    mergefiles,
    filter_inf,
    times_with_unit,
    mean_by_x,
    experiment_df,
    multi_experiment_df

end # module AllocationExperiments
