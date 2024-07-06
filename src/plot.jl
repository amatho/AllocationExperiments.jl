const bench_plot_kwds = (yscale=:log10, ylabel="time", yunit=u"ms", legend=false)

function experiment_df(data::Experiment, name::AbstractString; by=nothing)
    if isnothing(by)
        df = DataFrame(filter(((k, v),) -> k != :not_ef1 && !isempty(v), pairs(data.stats)))
        df[!, :x] .= name
        return df
    else
        vals = isa(by, Symbol) ? data.stats[by] : by(data)
        vals = filter_inf(vals)
        return DataFrame(x=name, y=vals)
    end
end

function experiment_df(data::MultiExperiment; by=nothing)
    df = DataFrame()
    for (k, v) in sort(data.experiments)
        append!(df, experiment_df(v, k, by=by))
    end
    return df
end

function benchmark_df(data::Experiment, name::AbstractString; add_timeouts=true)
    vals = data.benchmark.times * u"ns"
    if add_timeouts
        remaining = data.samples - length(vals)
        append!(vals, fill(1e9 * TIME_LIMIT * u"ns", remaining))
    end
    return DataFrame(x=name, y=vals)
end

function benchmark_df(data::MultiExperiment; add_timeouts=true)
    df = DataFrame()
    for (k, v) in sort(data.experiments)
        append!(df, benchmark_df(v, k, add_timeouts=add_timeouts))
    end
    return df
end

function mean_by_x(df::DataFrame)
    df_grouped = groupby(df, :x)
    return combine(df_grouped, Not(:x) .=> mean ∘ filter_inf .=> identity)
end

function parse_rank_xs!(df::DataFrame)
    rs = [parse(Int, x[3:end]) for x in df[!, :x]]
    df[!, :r] = rs
    return df
end

filter_inf(x::Number) = x
filter_inf(a) = filter(!isinf, a)

times_with_unit(benchmark::BenchmarkTools.Trial) = benchmark.times * u"ns"
