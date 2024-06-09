const bench_plot_kwds = (yscale=:log10, ylabel="time", yunit=u"ms", legend=false)

function plot_boxplot(name::AbstractString, values; p=plot(), kwds...)
    boxplot!(p, [name], filter(!isinf, values); legend=false, kwds...)
end

function plot_boxplots(itr; p=plot(), kwds...)
    for (k, v) in itr
        plot_boxplot(k, v; p=p, kwds...)
    end
    return p
end

bench_times_with_unit(benchmark::BenchmarkTools.Trial) = benchmark.times * u"ns"
