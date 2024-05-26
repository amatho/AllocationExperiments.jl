# AllocationExperiments.jl

A collection of experiments for benchmarking and evaluating the different [fair allocation](https://en.wikipedia.org/wiki/Fair_item_allocation)
algorithms in [Allocations.jl](https://github.com/mlhetland/Allocations.jl), focusing on the use of matroid constraints.

## Running the experiments

In order to run most of the experiments you will need a license for Gurobi (which is free for academics). Follow the instructions of
[Gurobi.jl](https://github.com/jump-dev/Gurobi.jl) if you have trouble with getting Gurobi to work in Julia.

First off, you will need to activate the environment by running `activate` in the Julia Pkg REPL:
```julia
pkg> activate .
```

Then you can download and install all dependencies by running `instantiate`:
```julia
pkg> instantiate
```

To run an experiment simply load the package and run the desired experiment:
```julia
julia> using AllocationExperiments

julia> data = mnw_matroid_lazy_knu74(samples=10)
```

## Saving and loading experiment data

If you want to save the data after running an experiment, use the library's `save` function:
```julia
julia> save("data.jld2", data)
```

This will save the experiment data using [JLD2.jl](https://github.com/JuliaIO/JLD2.jl).

To load experiment data from a file, use the `load` function:
```julia
julia> data = load("data.jld2")
```
