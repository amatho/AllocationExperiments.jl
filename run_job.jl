import Pkg
Pkg.activate(@__DIR__)

using AllocationExperiments
import InteractiveUtils
import JSON

if length(ARGS) != 3
    println("\nIncorrect number of arguments!\n")
    println("usage: julia run_job.jl <job_number> <samples> <experiment>")

    exit(1)
end

InteractiveUtils.versioninfo()

job_number = parse(Int, ARGS[1])
samples = parse(Int, ARGS[2])
experiment_func = getfield(AllocationExperiments, Symbol(ARGS[3]))

seeds = JSON.parsefile(string(@__DIR__, "/", "seeds.json"))
rng = rng_with_seed(seeds[job_number])

data = experiment_func(gen_rng=rng, samples=samples)
mkpath("data")
save("data/$(experiment_func)_job_$(job_number).json", data)
