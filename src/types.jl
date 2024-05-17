struct Experiment
    benchmark::BenchmarkTools.Trial
    samples::Int
    constraint::Union{Nothing,Type{<:Constraint}}
    stats::Dict{AbstractString,Vector{Real}}
end

function Base.show(io::IO, ::MIME"text/plain", data::Experiment)
    show(io, data)
    print(io, "\n\n")
    show(io, MIME"text/plain"(), data.benchmark)
end

function Base.summary(io::IO, data::Experiment)
    print(io, "Experiment with $(data.samples) samples")
end

function save(filename::AbstractString, data::Experiment)
    open(filename, "w") do f
        dict = Dict()
        bench_json = IOBuffer()
        BenchmarkTools.save(bench_json, data.benchmark)
        dict["benchmark"] = JSON.JSONText(String(take!(bench_json)))
        dict["samples"] = data.samples
        dict["constraint"] = data.constraint
        dict["stats"] = data.stats

        JSON.print(f, dict)
    end
end

function load(filename::AbstractString, ::Type{Experiment})
    dict = JSON.parsefile(filename)

    bench_json = IOBuffer()
    JSON.print(bench_json, dict["benchmark"])
    bench_json = seekstart(bench_json)
    benchmark = only(BenchmarkTools.load(bench_json))

    samples = dict["samples"]
    constraint = getfield(Allocations, Symbol(dict["constraint"]))
    stats = dict["stats"]

    return Experiment(benchmark, samples, constraint, stats)
end
load(filename::AbstractString) = load(filename, Experiment)

function Base.merge(data::Experiment, others...)
    benchmark = copy(data.benchmark)
    samples = data.samples
    constraint = data.constraint
    stats = data.stats

    for d in others
        push!(benchmark, d.benchmark)
        samples += d.samples
        for (k, v) in d.stats
            if haskey(data.stats, k)
                append!(data.stats[k], v)
            else
                @warn "unknown key when merging experiments"
                data.stats[k] = v
            end
        end
    end

    return Experiment(benchmark, samples, constraint, stats)
end

function Base.push!(t::BenchmarkTools.Trial, other::BenchmarkTools.Trial)
    append!(t.times, other.times)
    append!(t.gctimes, other.gctimes)
    other.memory < t.memory && (t.memory = memory)
    other.allocs < t.allocs && (t.allocs = allocs)
    t.params.samples += other.params.samples
    return t
end

function mergefiles(prefix::AbstractString, ext=".json")
    files = String[]
    i = 1
    while isfile(string(prefix, i, ext))
        push!(files, string(prefix, i, ext))
        i += 1
    end
    return merge((load(f) for f in files)...)
end
