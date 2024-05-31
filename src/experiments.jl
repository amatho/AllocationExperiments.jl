function knu74_sym(rng, _, m)
    return MatroidConstraint(rand_matroid_knu74(m, rng=rng, r=2:4))
end

function knu74_asym(rng, n, m)
    return MatroidConstraints(rand_matroid_knu74(n, m, rng=rng, r=2:4))
end

function er59_sym(rng, _, m)
    min_verts = ceil(Int, sqrt(2 * m) + (1 / 2))
    return MatroidConstraint(rand_matroid_er59(m, rng=rng, verts=min_verts:m))
end

function er59_asym(rng, n, m)
    min_verts = ceil(Int, sqrt(2 * m) + (1 / 2))
    return MatroidConstraints(rand_matroid_er59(n, m, rng=rng, verts=min_verts:m))
end

mnw_matroid_lazy_knu74(; kwds...) =
    experiment_mip(alloc_mnw, knu74_sym; kwds...)

mnw_matroid_lazy_knu74_asym(; kwds...) =
    experiment_mip(alloc_mnw, knu74_asym; kwds...)

function mnw_matroid_lazy_knu74_ranks(; samples=SAMPLES, kwds...)
    multi_exp = MultiExperiment()
    r_values = 3:11
    samples = max(samples ÷ length(r_values), 1)

    for r in r_values
        function gen_matroids(rng, _, m)
            return MatroidConstraint(rand_matroid_knu74(m, r=r:r, rng=rng))
        end

        multi_exp.experiments["r=$r"] = experiment_mip(alloc_mnw, gen_matroids; samples=samples, n=3:3, m=n->6n:6n, kwds...)
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

mms_matroid_lazy_knu74(; kwds...) =
    experiment_mip(alloc_mms, knu74_sym; kwds...)

mms_matroid_lazy_knu74_asym(; kwds...) =
    experiment_mip(alloc_mms, knu74_asym; kwds...)

mms_matroid_lazy_er59(; kwds...) =
    experiment_mip(alloc_mms, er59_sym; kwds...)

mms_matroid_lazy_er59_asym(; kwds...) =
    experiment_mip(alloc_mms, er59_asym; kwds...)

mms_unconstrained(; kwds...) =
    experiment_mip(alloc_mms; kwds...)

rnd_matroid_lazy_knu74(; kwds...) =
    experiment_mip(Allocations.alloc_rand_mip, knu74_sym; kwds...)

rnd_matroid_lazy_knu74_asym(; kwds...) =
    experiment_mip(Allocations.alloc_rand_mip, knu74_asym; kwds...)

rnd_matroid_lazy_er59(; kwds...) =
    experiment_mip(Allocations.alloc_rand_mip, er59_sym; kwds...)

rnd_matroid_lazy_er59_asym(; kwds...) =
    experiment_mip(Allocations.alloc_rand_mip, er59_asym; kwds...)

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
    r_rng = gen_rng()

    if alloc_func == alloc_mms
        extra_kwds = (cutoff=true, mms_kwds=(solver=CONF.GUROBI_MMS,))
    elseif alloc_func == Allocations.alloc_rand_mip
        extra_kwds = (rng=r_rng,)
    else
        extra_kwds = ()
    end

    function gen()
        V = rand_additive(n=n, m=m, v=v, rng=v_rng)
        C = isnothing(gen_constraint) ? nothing : gen_constraint(c_rng, na(V), ni(V))

        # Run GC after generating instance
        BenchmarkTools.gcscrub()

        return (V, C)
    end

    function run(V, C)
        res = nothing

        try
            res = alloc_func(V, C; solver=solver, min_owners=0, extra_kwds...)
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
    solver_name_str = nothing
    stats = (agents=Int[], items=Int[], ranks=Float64[], ef1=Bool[], efx=Bool[],
        mms_alphas=Float64[], complete=Bool[], constraints=Int[],
        not_ef1=Pair{Profile,Constraint}[])
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

            if isnothing(solver_name_str)
                solver_name_str = solver_name(res.model)
            end

            A = res.alloc

            push!(stats.agents, na(A))
            push!(stats.items, ni(A))

            @assert check(V, A, C) "Allocation does not satisfy matroid constraint"

            if isa(C, MatroidConstraint)
                push!(stats.ranks, rank(C.matroid))
            elseif isa(C, MatroidConstraints)
                push!(stats.ranks, mean(rank(M) for M in C.matroids))
            end

            is_ef1 = check_ef1(V, A)
            push!(stats.ef1, is_ef1)
            push!(stats.efx, check_efx(V, A))
            push!(stats.complete, check_complete(A))

            if (alloc_func == alloc_mnw || alloc_func == alloc_mnw_loop) && !is_ef1
                push!(stats.not_ef1, V => C)
            end

            if alloc_func == alloc_mms
                mmss = res.mmss

                constraints = res.added_constraints + sum(res.mms_added_constraints)
                push!(stats.constraints, constraints)
            else
                push!(stats.constraints, res.added_constraints)

                try
                    mmss = [mms(V, i, C, solver=CONF.GUROBI_MMS, min_owners=0).mms for i in agents(V)]
                catch
                    mmss = zeros(na(V))
                end
            end
            push!(stats.mms_alphas, mms_alpha(V, A, mmss))
        end

        count += 1
    end

    b = @benchmark res = $run(V, C) setup = ((V, C) = $gen(); res = nothing) teardown = ($collect(res, V, C)) samples = samples evals = 1 seconds = Inf
    remove_timeouts!(b, TIME_LIMIT, timeouts)

    return Experiment(b, samples, timeouts, constraint, solver_name_str, stats)
end
