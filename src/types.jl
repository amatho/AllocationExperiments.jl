mutable struct Experiment
    benchmark::BenchmarkTools.Trial
    samples::Int
    timeouts::Int
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

function to_json(data::Experiment)
    dict = Dict()
    bench_json = IOBuffer()
    BenchmarkTools.save(bench_json, data.benchmark)
    dict["benchmark"] = JSON.JSONText(String(take!(bench_json)))
    dict["samples"] = data.samples
    dict["timeouts"] = data.timeouts
    dict["constraint"] = isnothing(data.constraint) ? nothing : Base.typename(data.constraint).name
    dict["stats"] = data.stats

    return JSON.json(dict)
end

function from_dict(::Type{Experiment}, dict::Dict{<:AbstractString,Any})
    bench_json = IOBuffer()
    JSON.print(bench_json, dict["benchmark"])
    bench_json = seekstart(bench_json)
    benchmark = only(BenchmarkTools.load(bench_json))

    samples = dict["samples"]
    timeouts = dict["timeouts"]
    constraint = Base.eval(Allocations, Symbol(dict["constraint"]))
    stats = dict["stats"]

    return Experiment(benchmark, samples, timeouts, constraint, stats)
end

function Base.merge!(data::Experiment, others::Experiment...)
    for d in others
        push!(data.benchmark, d.benchmark)
        data.samples += d.samples
        data.timeouts += d.timeouts
        for (k, v) in d.stats
            if haskey(data.stats, k)
                append!(data.stats[k], v)
            else
                @warn "unknown key when merging experiments"
                data.stats[k] = v
            end
        end
    end

    return data
end

function Base.push!(t::BenchmarkTools.Trial, other::BenchmarkTools.Trial)
    append!(t.times, other.times)
    append!(t.gctimes, other.gctimes)
    other.memory < t.memory && (t.memory = other.memory)
    other.allocs < t.allocs && (t.allocs = other.allocs)
    t.params.samples += other.params.samples
    return t
end

mutable struct MultiExperiment
    experiments::Dict{AbstractString,Experiment}
end

MultiExperiment() = MultiExperiment(Dict{String,Experiment}())

function to_json(data::MultiExperiment)
    dict = Dict{String,JSON.JSONText}()
    for (k, v) in data.experiments
        dict[k] = JSON.JSONText(to_json(v))
    end
    return JSON.json(dict)
end

function from_dict(::Type{MultiExperiment}, dict::Dict{<:AbstractString,Any})
    experiments = Dict{String,Experiment}()
    for (k, v) in dict
        experiments[k] = from_dict(Experiment, v)
    end
    return MultiExperiment(experiments)
end

function Base.merge!(data::MultiExperiment, others::MultiExperiment...)
    for d in others
        for (k, v) in d.experiments
            if haskey(data.experiments, k)
                merge!(data.experiments[k], v)
            else
                @warn "unknown key when merging multi-experiments"
                data.experiments[k] = v
            end
        end
    end

    return data
end

load(t::Type, filename::AbstractString) = open(filename, "r") do f
    return from_dict(t, JSON.parse(f))
end

save(data::Union{Experiment,MultiExperiment}, filename::AbstractString) = open(filename, "w") do f
    print(f, to_json(data))
end

function mergefiles(t::Type, prefix::AbstractString, ext=".json")
    files = String[]
    i = 1
    while isfile(string(prefix, i, ext))
        push!(files, string(prefix, i, ext))
        i += 1
    end
    return isempty(files) ? nothing : merge!((load(t, f) for f in files)...)
end
