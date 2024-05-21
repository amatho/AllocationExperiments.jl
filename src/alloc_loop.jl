function check_and_fix(ctx, C::MatroidConstraint)
    M = C.matroid
    satisfies = true
    V, A, model = ctx.profile, ctx.alloc_var, ctx.model

    for (_, B) in ctx.alloc
        if !is_indep(M, B)
            satisfies = false
            r = rank(M, B)
            for i in agents(V)
                @constraint(model, sum(A[i, g] for g in B) <= r)
            end
        end
    end

    return satisfies
end

function check_and_fix(ctx, C::MatroidConstraints)
    satisfies = true
    A, model = ctx.alloc_var, ctx.model

    for (i, B) in ctx.alloc
        M = C.matroids[i]
        if !is_indep(M, B)
            satisfies = false
            r = rank(M, B)
            @constraint(model, sum(A[i, g] for g in B) <= r)
        end
    end
end

set_initial_constraints(ctx, V, C::MatroidConstraint) = for i in agents(V)
    Allocations.matroid_initial_constraint(ctx, C.matroid, i)
end

set_initial_constraints(ctx, V, C::MatroidConstraints) = for (i, M) in enumerate(C.matroids)
    Allocations.matroid_initial_constraint(ctx, M, i)
end

function alloc_mnw_loop(V, C; solver=CONF.HIGHS, kwds...)
    ctx = Allocations.init_mip(V, solver; kwds...) |>
    Allocations.achieve_mnw(false)
    set_initial_constraints(ctx, V, C)
    ctx = Allocations.solve_mip(ctx)

    while !check_and_fix(ctx, C)
        ctx = Allocations.solve_mip(ctx)
    end

    return Allocations.mnw_result(ctx)
end
