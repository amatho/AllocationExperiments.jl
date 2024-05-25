import Pkg
Pkg.activate(@__DIR__)

using AllocationExperiments
import Gurobi
import InteractiveUtils
import JLD2
using JuMP

if length(ARGS) != 3
    println("\nIncorrect number of arguments!\n")
    println("usage: julia run_job.jl <job_number> <samples> <experiment>")

    exit(1)
end

InteractiveUtils.versioninfo()

job_number = parse(Int, ARGS[1])
samples = parse(Int, ARGS[2])
experiment_func = getfield(AllocationExperiments, Symbol(ARGS[3]))

seeds = JLD2.load_object(string(@__DIR__, "/", "seeds.jld2"))
rng = rng_with_seed(seeds[job_number])

AllocationExperiments.CONF.GUROBI = optimizer_with_attributes(
    () -> Gurobi.Optimizer(AllocationExperiments.GRB_ENV_REF[]),
    "Threads" => 8,
    "SoftMemLimit" => 16,
    AllocationExperiments.CONF.GUROBI.params...
)

AllocationExperiments.CONF.GUROBI_MMS = optimizer_with_attributes(
    () -> Gurobi.Optimizer(AllocationExperiments.GRB_ENV_REF[]),
    "Threads" => 8,
    "SoftMemLimit" => 16,
    AllocationExperiments.CONF.GUROBI_MMS.params...
)

data = experiment_func(gen_rng=rng, samples=samples)
mkpath("data")
save("data/$(experiment_func)_job_$(job_number).jld2", data)
