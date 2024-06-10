function check_and_fix(ctx, M::Matroid, i)
    A, model = ctx.alloc_var, ctx.model
    B = bundle(ctx.alloc, i)

    if !is_indep(M, B)
        r = rank(M, B)
        @constraint(model, sum(A[i, g] for g in B) <= r)
        ctx.added_constraints += 1

        return false
    end

    return true
end

function check_and_fix(ctx, C::MatroidConstraint)
    M = C.matroid
    satisfies = true
    for i in agents(ctx.profile)
        satisfies = min(satisfies, check_and_fix(ctx, M, i))
    end
    return satisfies
end

function check_and_fix(ctx, C::MatroidConstraints)
    satisfies = true
    for (i, M) in enumerate(C.matroids)
        satisfies = min(satisfies, check_and_fix(ctx, M, i))
    end
    return satisfies
end

check_and_fix(ctx, C::Allocations.SymmetrizedConstraint{MatroidConstraint}) =
    check_and_fix(ctx, C.C)

check_and_fix(ctx, C::Allocations.SymmetrizedConstraint{MatroidConstraints}) =
    check_and_fix(ctx, MatroidConstraint(C.C.matroids[C.i]))

set_initial_constraints(V, C::MatroidConstraint) = function (ctx)
    for i in agents(V)
        Allocations.matroid_initial_constraint(ctx, C.matroid, i)
    end
    return ctx
end

set_initial_constraints(V, C::MatroidConstraints) = function (ctx)
    for (i, M) in enumerate(C.matroids)
        Allocations.matroid_initial_constraint(ctx, M, i)
    end
    return ctx
end

set_initial_constraints(V, C::Allocations.SymmetrizedConstraint{MatroidConstraint}) =
    set_initial_constraints(V, C.C)

set_initial_constraints(V, C::Allocations.SymmetrizedConstraint{MatroidConstraints}) =
    set_initial_constraints(V, MatroidConstraint(C.C.matroids[C.i]))

solve_mip_loop(V, C) = function (ctx)
    ctx = ctx |>
          set_initial_constraints(V, C) |>
          Allocations.solve_mip

    total_solve_time = solve_time(ctx.model)
    while total_solve_time < TIME_LIMIT && !check_and_fix(ctx, C)
        ctx = Allocations.solve_mip(ctx)
        total_solve_time += solve_time(ctx.model)
    end

    if total_solve_time >= TIME_LIMIT
        @warn "loop method reached time limit" TIME_LIMIT total_solve_time
        return nothing
    end

    return ctx
end

# Loop version of alloc_mnw
function alloc_mnw_loop(V, C; solver=CONF.HIGHS, kwds...)
    ctx = Allocations.init_mip(V, solver; kwds...) |>
          Allocations.achieve_mnw(false) |>
          solve_mip_loop(V, C)

    return isnothing(ctx) ? nothing : Allocations.mnw_result(ctx)
end

# Loop version of alloc_mm
function alloc_mm_loop(V, C=nothing; cutoff=nothing, ignored_agents=[],
    solver=CONF.HIGHS, kwds...)
    ctx = Allocations.init_mip(V, solver; kwds...) |>
          Allocations.achieve_mm(cutoff, ignored_agents) |>
          solve_mip_loop(V, C)

    return isnothing(ctx) ? nothing : Allocations.mm_result(ctx)
end

# Loop version of mms
function mms_loop(V::Additive, i, C=nothing; solver=CONF.HIGHS, kwds...)

    # Let all agents be clones of agent i
    Vᵢ = Additive([Allocations.value(V, i, g) for _ in agents(V), g in items(V)])
    Cᵢ = Allocations.SymmetrizedConstraint(C, i)
    minbᵢ = Allocations.get_limit(get(kwds, :min_bundle, nothing), i)
    maxbᵢ = Allocations.get_limit(get(kwds, :max_bundle, nothing), i)

    # maximin in this scenario is MMS for agent i
    res = alloc_mm_loop(Vᵢ, Cᵢ; solver=solver, kwds...,
        min_bundle=minbᵢ, max_bundle=maxbᵢ)

    return isnothing(res) ? nothing : (mms=res.mm, model=res.model, added_constraints=res.added_constraints)

end

# Loop version of alloc_mms
function alloc_mms_loop(V::Additive, C=nothing; cutoff=false, solver=CONF.HIGHS,
    mms_kwds=(), kwds...)

    N, M = agents(V), items(V)

    X = zeros(na(V), ni(V))

    ress = [mms_loop(V, i, C; solver=solver, kwds..., mms_kwds...) for i in N]
    if any(isnothing, ress)
        return nothing
    end

    # Individual maximin shares -- also included in the result
    mmss = [res.mms for res in ress]

    mms_models = [res.model for res in ress]

    for (i, μ) in enumerate(mmss), g in M
        X[i, g] = Allocations.value(V, i, g) / μ
    end

    max_alpha = cutoff ? 1.0 : nothing

    res = alloc_mm_loop(Additive(X), C;
        cutoff=max_alpha,
        ignored_agents=N[iszero.(mmss)],
        solver=solver,
        kwds...)
    if isnothing(res)
        return nothing
    end

    mms_added_constraints = [res.added_constraints for res in ress]

    return (alloc=res.alloc,
        model=res.model,
        mms_models=mms_models,
        alpha=res.mm,
        mmss=mmss,
        added_constraints=res.added_constraints,
        mms_added_constraints=mms_added_constraints)

end
