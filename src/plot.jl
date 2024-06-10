const bench_plot_kwds = (yscale=:log10, ylabel="time", yunit=u"ms", legend=false)

function experiment_df(data::Experiment, name::AbstractString, by)
    vals = isa(by, Symbol) ? data.stats[by] : by(data)
    if isa(vals, Array)
        vals = filter_inf(vals)
    end
    return DataFrame(x=name, y=vals)
end

function multi_experiment_df(data::MultiExperiment, by)
    df = DataFrame(x=String[], y=Float64[])
    for (k, v) in sort(data.experiments)
        append!(df, experiment_df(v, k, by))
    end
    return df
end

filter_inf(a) = filter(!isinf, a)

times_with_unit(benchmark::BenchmarkTools.Trial) = benchmark.times * u"ns"
