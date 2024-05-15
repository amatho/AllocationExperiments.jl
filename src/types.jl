struct Experiment
    name::Symbol
    benchmark::BenchmarkTools.Trial
    samples::Int
    ef1_checks::Vector{Bool}
    efx_checks::Vector{Bool}
    mms_alphas::Vector{Float64}
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
        dict["name"] = data.name
        dict["benchmark"] = JSON.JSONText(String(take!(bench_json)))
        dict["samples"] = data.samples
        dict["ef1_checks"] = data.ef1_checks
        dict["efx_checks"] = data.efx_checks
        dict["mms_alphas"] = data.mms_alphas

        JSON.print(f, dict)
    end
end

function load(filename::AbstractString, ::Type{Experiment})
    dict = JSON.parsefile(filename)

    bench_json = IOBuffer()
    JSON.print(bench_json, dict["benchmark"])
    bench_json = seekstart(bench_json)
    benchmark = only(BenchmarkTools.load(bench_json))

    name = Symbol(dict["name"])
    samples = dict["samples"]
    ef1_checks = dict["ef1_checks"]
    efx_checks = dict["efx_checks"]
    mms_alphas = dict["mms_alphas"]

    return Experiment(name, benchmark, samples, ef1_checks, efx_checks, mms_alphas)
end
load(filename::AbstractString) = load(filename, Experiment)

function Base.merge(data::Experiment, others...)
    name = data.name
    benchmark = copy(data.benchmark)
    samples = data.samples
    ef1_checks = data.ef1_checks
    efx_checks = data.efx_checks
    mms_alphas = data.mms_alphas

    for (i, d) in enumerate(others)
        push!(benchmark, d.benchmark)
        samples += d.samples
        append!(ef1_checks, d.ef1_checks)
        append!(efx_checks, d.efx_checks)
        append!(mms_alphas, d.mms_alphas)
    end

    return Experiment(name, benchmark, samples, ef1_checks, efx_checks, mms_alphas)
end

function Base.push!(t::BenchmarkTools.Trial, other::BenchmarkTools.Trial)
    append!(t.times, other.times)
    append!(t.gctimes, other.gctimes)
    other.memory < t.memory && (t.memory = memory)
    other.allocs < t.allocs && (t.allocs = allocs)
    t.params.samples += other.params.samples
    return t
end

function mergefiles(files...)
    data = [load(f) for f in files]
    return merge(data...)
end
