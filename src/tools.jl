function rng_with_seed(seed)
    return function ()
        Xoshiro(seed)
    end
end
