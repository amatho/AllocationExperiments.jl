import Pkg
Pkg.activate(".")

using AllocationExperiments
import JSON

if length(ARGS) != 2
    println("\nIncorrect number of arguments!\n")
    println("usage: julia run_job.jl <job_number> <samples>")

    exit(1)
end

job_number = parse(Int, ARGS[1])
samples = parse(Int, ARGS[2])

seeds = JSON.parsefile("data/seeds.json")
rng = rng_with_seed(seeds[job_number])

b = bench_mnw_matroid_asym_lazy_knu74(gen_rng=rng, samples=samples)
display(b)