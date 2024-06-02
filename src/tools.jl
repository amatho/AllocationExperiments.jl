function set_log_each(val::Integer)
    CONF.LOG_EACH = val
end

function rng_with_seed(seed)
    return function ()
        Xoshiro(seed)
    end
end

function remove_timeouts!(b::BenchmarkTools.Trial, time_limit::Int, target::Int)
    over_limit = [(i, t) for (i, t) in enumerate(b.times) if t > time_limit * 1e9]
    len = min(length(over_limit), target)
    over_limit = sort!(over_limit, by=x->x[2], rev=true)[1:len]
    sort!(over_limit, by=x->x[1], rev=true)

    for (i, _) in over_limit
        deleteat!(b.times, i)
        deleteat!(b.gctimes, i)
    end
end

function fix_missing_times!(data::Experiment, time_limit=TIME_LIMIT)
    num_missing = data.samples - (data.timeouts + length(data.benchmark))
    if num_missing <= 0
        return data
    end

    times = [time_limit * 1e9 for _ in 1:num_missing]
    gctimes = [0.0 for _ in 1:num_missing]
    append!(data.benchmark.times, times)
    append!(data.benchmark.gctimes, gctimes)

    return data
end

function fix_missing_times!(data::MultiExperiment, time_limit=TIME_LIMIT)
    for (_, d) in data.experiments
        fix_missing_times!(d, time_limit)
    end

    return data
end
