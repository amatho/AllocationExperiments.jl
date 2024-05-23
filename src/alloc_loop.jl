function check_and_fix(ctx, C::MatroidConstraint)
    M = C.matroid
    satisfies = true
    A, model = ctx.alloc_var, ctx.model

    for (i, B) in ctx.alloc
        if !is_indep(M, B)
            satisfies = false
            r = rank(M, B)
            @constraint(model, sum(A[i, g] for g in B) <= r)
            ctx.added_constraints += 1
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
            ctx.added_constraints += 1
        end
    end

    return satisfies
end

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

function alloc_mnw_loop(V, C; solver=CONF.HIGHS, kwds...)
    ctx = Allocations.init_mip(V, solver; kwds...) |>
    Allocations.achieve_mnw(false) |>
    set_initial_constraints(V, C) |>
    Allocations.solve_mip

    while !check_and_fix(ctx, C)
        ctx = Allocations.solve_mip(ctx)
    end

    return Allocations.mnw_result(ctx)
end
