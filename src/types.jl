mutable struct Experiment
    benchmark::BenchmarkTools.Trial
    samples::Int
    timeouts::Int
    constraint::Union{Nothing,Type{<:Constraint}}
    solver::AbstractString
    stats::NamedTuple
end

Base.show(io::IO, data::Experiment) =
    print(io, "Experiment($(data.samples), $(data.timeouts), $(data.constraint), $(data.solver), …)")

function Base.show(io::IO, m::MIME"text/plain", data::Experiment)
    println(io, "Experiment with $(data.samples) samples:")
    println(io, " Timeouts: $(data.timeouts)")
    println(io, " Constraint: $(data.constraint)")
    println(io, " Solver: $(data.solver)")
    println(io, " Stats: ")

    for (k, v) in pairs(data.stats)
        print(io, "  $k: ")
        if k == :not_ef1
            print(io, "$(length(v)) instances")
        else
            show(IOContext(io, :compact => true), v)
        end
        print(io, "\n")
    end

    print(io, "\n")
    show(io, m, data.benchmark)
end

function Base.summary(io::IO, data::Experiment)
    print(io, "Experiment with $(data.samples) samples")
end

function Base.merge!(data::Experiment, others::Experiment...)
    for d in others
        push!(data.benchmark, d.benchmark)
        data.samples += d.samples
        data.timeouts += d.timeouts
        data.constraint != d.constraint && @warn "different constraints when merging" a=data.constraint b=d.constraint
        data.solver != d.solver && @warn "different solvers when merging" a=data.solver b=d.solver
        for (k, v) in pairs(d.stats)
            if haskey(data.stats, k)
                append!(data.stats[k], v)
            else
                @warn "unknown key when merging experiments" k
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

load(filename::AbstractString) = load_object(filename)

save(filename::AbstractString, data) = save_object(filename, data)

function mergefiles(prefix::AbstractString, ext=".jld2")
    files = String[]
    i = 1
    while isfile(string(prefix, i, ext))
        push!(files, string(prefix, i, ext))
        i += 1
    end
    return isempty(files) ? nothing : merge!((load(f) for f in files)...)
end
