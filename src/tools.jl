function rng_with_seed(seed)
    return function ()
        Xoshiro(seed)
    end
end

function remove_timeouts!(b::BenchmarkTools.Trial, time_limit::Int)
    indices = [i for (i, t) in enumerate(b.times) if t > time_limit * 1e9]
    for i in reverse(indices)
        deleteat!(b.times, i)
        deleteat!(b.gctimes, i)
    end
end
