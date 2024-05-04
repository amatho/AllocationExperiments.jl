create_gurobi() = optimizer_with_attributes(() -> Gurobi.Optimizer(GRB_ENV_REF[]), "LogToConsole" => 0, "TimeLimit" => TIME_LIMIT)


function bench_mnw_matroid_lazy_knu74(; rng=default_rng(), samples=SAMPLES)
    function gen_matroid(m)
        AllocationInstances.rand_matroid_knu74_1(m, [0, 15, 6], rng=rng)
    end

    function set_constraints(M)
        return function (ctx)
            ctx |> Allocations.enforce_lazy(MatroidConstraint(M))
        end
    end

    bench_mnw_matroid(gen_matroid, set_constraints, rng=rng, samples=samples)
end


function bench_mnw_matroid_lazy_ws98()
end


# TODO: Investigate if this is possible
# function bench_mnw_matroid_bases_knu74(; rng=default_rng(), samples=SAMPLES)
#     function gen_matroid(m)
#         AllocationInstances.rand_matroid_knu74_1(m, [0, 15, 6], rng=rng)
#     end

#     function set_constraints(M::Union{ClosedSetsMatroid,FullMatroid})
#         return function (ctx)
#             V, A, model = ctx.profile, ctx.alloc_var, ctx.model

#             for i in agents(V), r in 1:M.r, C in M.F[r+1]
#                 @constraint(model, sum(A[i, g] for g in C) <= r)
#             end

#             return ctx
#         end
#     end

#     bench_mnw_matroid(gen_matroid, set_constraints, rng=rng, samples=samples)
# end


function bench_mnw_matroid(gen_matroid::Function, set_constraints::Function; rng=default_rng(), samples=SAMPLES)
    solver = create_gurobi()

    function gen()
        V = AllocationInstances.rand_additive(n=2:6, v=VALUATION_DISTRIBUTION, rng=rng)
        M = gen_matroid(ni(V))

        return (V, M)
    end

    function run(V, M)
        ctx = Allocations.init_mip(V, solver, min_owners=0)

        try
            ctx = ctx |>
                  Allocations.achieve_mnw(false) |>
                  set_constraints(M) |>
                  Allocations.solve_mip
        catch e
            if termination_status(ctx.model) == MOI.TIME_LIMIT
                @warn "MIP reached time limit" TIME_LIMIT
            else
                @error "MIP terminated unsuccessfully" termination = termination_status(ctx.model)
                rethrow(e)
            end
        end

        return ctx
    end

    function collect(ctx, M)
        term_status = termination_status(ctx.model)

        if term_status in Allocations.conf.MIP_SUCCESS
            result = Allocations.mnw_result(ctx)
            @info result status = term_status

            for B in result.alloc.bundle
                @assert is_indep(M, B)
            end
        end
    end

    @benchmark ctx = $run(V, M) setup = ((V, M) = $gen(); ctx = nothing) teardown = ($collect(ctx, M)) samples = samples evals = 1 seconds = TIME_LIMIT * samples
end


function bench_mnw_unconstrained(; rng=default_rng(), samples=SAMPLES)
    solver = create_gurobi()

    function gen()
        AllocationInstances.rand_additive(n=2:6, v=VALUATION_DISTRIBUTION, rng=rng)
    end

    function run(V)
        Allocations.init_mip(V, solver) |>
        Allocations.achieve_mnw(false) |>
        Allocations.solve_mip
    end

    function collect(ctx)
        result = Allocations.mnw_result(ctx)
        @info result
    end

    @benchmark ctx = $run(V) setup = (V = $gen(); ctx = nothing) teardown = ($collect(ctx)) samples = samples evals = 1 seconds = TIME_LIMIT * samples
end