create_gurobi() = optimizer_with_attributes(() -> Gurobi.Optimizer(GRB_ENV_REF[]), "LogToConsole" => 0, "TimeLimit" => TIME_LIMIT)


function mnw_matroid_lazy_knu74(; gen_rng=DEFAULT_GEN_RNG, samples=SAMPLES)
    rng = gen_rng()
    function gen_matroids(_, m)
        return MatroidConstraint(rand_matroid_knu74_1(m, [0, 15, 6], rng=rng))
    end

    return experiment_mip(Symbol(mnw_matroid_lazy_knu74), alloc_mnw, gen_matroids, rng=gen_rng(), samples=samples)
end


function mnw_matroid_asym_lazy_knu74(; gen_rng=DEFAULT_GEN_RNG, samples=SAMPLES)
    rng = gen_rng()
    function gen_matroids(n, m)
        return MatroidConstraints(rand_matroid_knu74_1(n, m, [0, 15, 6], rng=rng))
    end

    return experiment_mip(Symbol(mnw_matroid_asym_lazy_knu74), alloc_mnw, gen_matroids, rng=gen_rng(), samples=samples)
end


function mnw_matroid_lazy_er59(; gen_rng=DEFAULT_GEN_RNG, samples=SAMPLES)
    rng = gen_rng()
    function gen_matroid(_, m)
        return MatroidConstraint(rand_matroid_er59(m, rng=rng))
    end

    return experiment_mip(Symbol(mnw_matroid_lazy_er59), alloc_mnw, gen_matroid, rng=gen_rng(), samples=samples)
end


function mnw_matroid_asym_lazy_er59(; gen_rng=DEFAULT_GEN_RNG, samples=SAMPLES)
    rng = gen_rng()
    function gen_matroid(n, m)
        return MatroidConstraints(rand_matroid_er59(n, m, rng=rng))
    end

    return experiment_mip(Symbol(mnw_matroid_asym_lazy_er59), alloc_mnw, gen_matroid, rng=gen_rng(), samples=samples)
end


function mnw_unconstrained(; gen_rng=DEFAULT_GEN_RNG, samples=SAMPLES)
    rng = gen_rng()
    return experiment_mip(Symbol(mnw_unconstrained), alloc_mnw, rng=rng, samples=samples)
end


function mms_matroid_lazy_er59(; gen_rng=DEFAULT_GEN_RNG, samples=SAMPLES)
    rng = gen_rng()
    function gen_matroid(_, m)
        return MatroidConstraint(rand_matroid_er59(m, rng=rng))
    end

    return experiment_mip(Symbol(mms_matroid_lazy_er59), alloc_mms, gen_matroid, rng=gen_rng(), samples=samples)
end


function mms_matroid_asym_lazy_er59(; gen_rng=DEFAULT_GEN_RNG, samples=SAMPLES)
    rng = gen_rng()
    function gen_matroid(n, m)
        return MatroidConstraints(rand_matroid_er59(n, m, rng=rng))
    end

    return experiment_mip(Symbol(mms_matroid_asym_lazy_er59), alloc_mms, gen_matroid, rng=gen_rng(), samples=samples)
end


function mms_unconstrained(; gen_rng=DEFAULT_GEN_RNG, samples=SAMPLES)
    rng = gen_rng()
    return experiment_mip(Symbol(mms_unconstrained), alloc_mms, rng=rng, samples=samples)
end


function experiment_mip(
    name::Symbol,
    alloc_func::Function,
    gen_constraint::Union{Nothing,Function}=nothing;
    rng=default_rng(),
    samples=SAMPLES
)
    solver = create_gurobi()

    function gen()
        V = rand_additive(n=2:6, v=VALUATION, rng=rng)
        C = isnothing(gen_constraint) ? nothing : gen_constraint(na(V), ni(V))

        return (V, C)
    end

    function run(V, C)
        res = nothing

        try
            res = alloc_func(V, C, solver=solver, min_owners=0)
        catch e
            if isa(e, AssertionError)
                @warn "MIP probably reached time limit" TIME_LIMIT err = e.msg
            else
                @error "MIP terminated unsuccessfully"
                rethrow(e)
            end
        end

        return res
    end

    count = 0
    ef1_checks = Bool[]
    efx_checks = Bool[]
    mms_alphas = Float64[]
    function collect(res, V, C)
        if count == 0
            count += 1
            return
        end

        if !isnothing(res)
            CONF.LOG && count % CONF.LOG_EACH == 0 && @info "Finished sample number $count"

            A = res.alloc

            @assert check(V, A, C) "Allocation does not satisfy matroid constraint"

            push!(ef1_checks, check_ef1(V, A))
            push!(efx_checks, check_efx(V, A))

            # TODO: Use constraint when calculating MMS
            mmss = [mms(V, i, solver=solver, min_owners=0).mms for i in agents(V)]
            push!(mms_alphas, mms_alpha(V, A, mmss))
        end

        count += 1
    end

    b = @benchmark res = $run(V, C) setup = ((V, C) = $gen(); res = nothing) teardown = ($collect(res, V, C)) samples = samples evals = 1 seconds = TIME_LIMIT * samples

    return Experiment(name, b, samples, ef1_checks, efx_checks, mms_alphas)
end
