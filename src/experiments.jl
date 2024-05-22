function knu74_sym(rng, _, m)
    return MatroidConstraint(rand_matroid_knu74(m, rng=rng, r=2:4))
end

function knu74_asym(rng, n, m)
    return MatroidConstraints(rand_matroid_knu74(n, m, rng=rng, r=2:4))
end

function er59_sym(rng, _, m)
    return MatroidConstraint(rand_matroid_er59(m, rng=rng, r=2:4))
end

function er59_asym(rng, n, m)
    return MatroidConstraints(rand_matroid_er59(n, m, rng=rng, r=2:4))
end

mnw_matroid_lazy_knu74(; kwds...) =
    experiment_mip(alloc_mnw, knu74_sym; kwds...)

mnw_matroid_lazy_knu74_asym(; kwds...) =
    experiment_mip(alloc_mnw, knu74_asym; kwds...)

function mnw_matroid_lazy_knu74_ranks(; samples=SAMPLES, kwds...)
    multi_exp = MultiExperiment()
    samples = max(samples ÷ 8, 1)

    for r in 1:8
        function gen_matroids(rng, _, m)
            return MatroidConstraint(rand_matroid_knu74(m, r=r:r, rng=rng))
        end

        multi_exp.experiments["rank $r"] = experiment_mip(alloc_mnw, gen_matroids; samples=samples, n=2:4, m=n->2n:4n, kwds...)
    end

    return multi_exp
end

mnw_matroid_lazy_er59(; kwds...) =
    experiment_mip(alloc_mnw, er59_sym; kwds...)

mnw_matroid_lazy_er59_asym(; kwds...) =
    experiment_mip(alloc_mnw, er59_asym; kwds...)

mnw_matroid_loop_knu74(; kwds...) =
    experiment_mip(alloc_mnw_loop, knu74_sym; kwds...)

mnw_matroid_loop_knu74_asym(; kwds...) =
    experiment_mip(alloc_mnw_loop, knu74_asym; kwds...)

mnw_matroid_loop_er59(; kwds...) =
    experiment_mip(alloc_mnw_loop, er59_sym; kwds...)

mnw_matroid_loop_er59_asym(; kwds...) =
    experiment_mip(alloc_mnw_loop, er59_asym; kwds...)

mnw_matroid_loop_knu74_highs(; kwds...) =
    experiment_mip(alloc_mnw_loop, knu74_sym; solver=CONF.HIGHS, kwds...)

mnw_matroid_loop_knu74_asym_highs(; kwds...) =
    experiment_mip(alloc_mnw_loop, knu74_asym; solver=CONF.HIGHS, kwds...)

mnw_matroid_loop_er59_highs(; kwds...) =
    experiment_mip(alloc_mnw_loop, er59_sym; solver=CONF.HIGHS, kwds...)

mnw_matroid_loop_er59_asym_highs(; kwds...) =
    experiment_mip(alloc_mnw_loop, er59_asym; solver=CONF.HIGHS, kwds...)

mnw_unconstrained(; kwds...) =
    experiment_mip(alloc_mnw; kwds...)

mms_matroid_lazy_er59(; kwds...) =
    experiment_mip(alloc_mms, er59_sym; kwds...)

mms_matroid_lazy_er59_asym(; kwds...) =
    experiment_mip(alloc_mms, er59_asym; kwds...)

mms_unconstrained(; kwds...) =
    experiment_mip(alloc_mms; kwds...)

function experiment_mip(
    alloc_func::Function,
    gen_constraint::Union{Nothing,Function}=nothing;
    gen_rng=DEFAULT_GEN_RNG,
    samples=SAMPLES,
    solver=CONF.GUROBI,
    n=2:7,
    m=n->2n:4n,
    v=(n, m)->DiscreteUniform(1, 50)
)
    v_rng = gen_rng()
    c_rng = gen_rng()

    function gen()
        V = rand_additive(n=n, m=m, v=v, rng=v_rng)
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
        efx_checks=Bool[], mms_alphas=Float64[], complete_checks=Bool[],
        added_constraints=Int[])
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
            push!(stats.complete_checks, check_complete(A))
            push!(stats.added_constraints, res.added_constraints)

            # TODO: Use constraint when calculating MMS
            mmss = [mms(V, i, solver=solver, min_owners=0).mms for i in agents(V)]
            push!(stats.mms_alphas, mms_alpha(V, A, mmss))
        end

        count += 1
    end

    b = @benchmark res = $run(V, C) setup = ((V, C) = $gen(); res = nothing) teardown = ($collect(res, V, C)) samples = samples evals = 1 seconds = Inf
    remove_timeouts!(b, TIME_LIMIT)

    return Experiment(b, samples, timeouts, constraint, stats)
end
