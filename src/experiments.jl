create_gurobi() = optimizer_with_attributes(() -> Gurobi.Optimizer(GRB_ENV_REF[]), "LogToConsole" => 0, "TimeLimit" => TIME_LIMIT)

function mnw_matroid_lazy_knu74(; gen_rng=DEFAULT_GEN_RNG, samples=SAMPLES)
    function gen_matroids(rng, _, m)
        return MatroidConstraint(rand_matroid_knu74(m, rng=rng))
    end

    return experiment_mip(alloc_mnw, gen_matroids, gen_rng=gen_rng, samples=samples, m=n->2n:3n)
end

function mnw_matroid_asym_lazy_knu74(; gen_rng=DEFAULT_GEN_RNG, samples=SAMPLES)
    function gen_matroids(rng, n, m)
        return MatroidConstraints(rand_matroid_knu74(n, m, rng=rng))
    end

    return experiment_mip(alloc_mnw, gen_matroids, gen_rng=gen_rng, samples=samples, m=n->2n:3n)
end

function mnw_matroid_lazy_knu74_ranks(; gen_rng=DEFAULT_GEN_RNG, samples=SAMPLES)
    multi_exp = MultiExperiment()
    samples = max(samples ÷ 8, 1)

    for r in 2:9
        function gen_matroids(rng, _, m)
            return MatroidConstraint(rand_matroid_knu74(m, r=r, rng=rng))
        end

        multi_exp.experiments["rank $r"] = experiment_mip(alloc_mnw, gen_matroids, gen_rng=gen_rng, samples=samples, m=n->18:18)
    end

    return multi_exp
end

function mnw_matroid_lazy_er59(; gen_rng=DEFAULT_GEN_RNG, samples=SAMPLES)
    function gen_matroid(rng, _, m)
        return MatroidConstraint(rand_matroid_er59(m, rng=rng))
    end

    return experiment_mip(alloc_mnw, gen_matroid, gen_rng=gen_rng, samples=samples)
end

function mnw_matroid_asym_lazy_er59(; gen_rng=DEFAULT_GEN_RNG, samples=SAMPLES)
    function gen_matroid(rng, n, m)
        return MatroidConstraints(rand_matroid_er59(n, m, rng=rng))
    end

    return experiment_mip(alloc_mnw, gen_matroid, gen_rng=gen_rng, samples=samples)
end

mnw_unconstrained(; gen_rng=DEFAULT_GEN_RNG, samples=SAMPLES) =
    experiment_mip(alloc_mnw, gen_rng=gen_rng, samples=samples)

function mms_matroid_lazy_er59(; gen_rng=DEFAULT_GEN_RNG, samples=SAMPLES)
    function gen_matroid(rng, _, m)
        return MatroidConstraint(rand_matroid_er59(m, rng=rng))
    end

    return experiment_mip(alloc_mms, gen_matroid, gen_rng=gen_rng, samples=samples)
end

function mms_matroid_asym_lazy_er59(; gen_rng=DEFAULT_GEN_RNG, samples=SAMPLES)
    function gen_matroid(rng, n, m)
        return MatroidConstraints(rand_matroid_er59(n, m, rng=rng))
    end

    return experiment_mip(alloc_mms, gen_matroid, gen_rng=gen_rng, samples=samples)
end

mms_unconstrained(; gen_rng=DEFAULT_GEN_RNG, samples=SAMPLES) =
    experiment_mip(alloc_mms, gen_rng=gen_rng, samples=samples)

function experiment_mip(
    alloc_func::Function,
    gen_constraint::Union{Nothing,Function}=nothing;
    gen_rng=DEFAULT_GEN_RNG,
    samples=SAMPLES,
    n=2:6,
    m=n->2n:4n
)
    solver = create_gurobi()
    v_rng = gen_rng()
    c_rng = gen_rng()

    function gen()
        V = rand_additive(n=n, m=m, v=VALUATION, rng=v_rng)
        C = isnothing(gen_constraint) ? nothing : gen_constraint(c_rng, na(V), ni(V))

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
    timeouts = 0
    constraint = nothing
    stats = (agents=Int[], items=Int[], ranks=Float64[], ef1_checks=Bool[],
        efx_checks=Bool[], mms_alphas=Float64[])
    function collect(res, V, C)
        if count == 0
            count += 1
            isnothing(C) || (constraint = typeof(C))
            return
        end

        if isnothing(res)
            timeouts += 1
        else
            CONF.LOG && count % CONF.LOG_EACH == 0 && @info "Finished sample number $count"

            A = res.alloc

            push!(stats.agents, na(A))
            push!(stats.items, ni(A))

            @assert check(V, A, C) "Allocation does not satisfy matroid constraint"

            if isa(C, MatroidConstraint)
                push!(stats.ranks, rank(C.matroid))
            elseif isa(C, MatroidConstraints)
                push!(stats.ranks, mean(rank(M) for M in C.matroids))
            end

            push!(stats.ef1_checks, check_ef1(V, A))
            push!(stats.efx_checks, check_efx(V, A))

            # TODO: Use constraint when calculating MMS
            mmss = [mms(V, i, solver=solver, min_owners=0).mms for i in agents(V)]
            push!(stats.mms_alphas, mms_alpha(V, A, mmss))
        end

        count += 1
    end

    b = @benchmark res = $run(V, C) setup = ((V, C) = $gen(); res = nothing) teardown = ($collect(res, V, C)) samples = samples evals = 1 seconds = Inf

    return Experiment(b, samples, timeouts, constraint, stats)
end
