create_gurobi() = optimizer_with_attributes(() -> Gurobi.Optimizer(GRB_ENV_REF[]), "LogToConsole" => 0, "TimeLimit" => TIME_LIMIT)


function bench_mnw_matroid_lazy_knu74(; gen_rng=DEFAULT_GEN_RNG, samples=SAMPLES)
    rng = gen_rng()
    function gen_matroid(m)
        AllocationInstances.rand_matroid_knu74_1(m, [0, 6, 2], rng=rng)
    end

    function set_constraints(M)
        return function (ctx)
            ctx |> Allocations.enforce_lazy(MatroidConstraint(M))
        end
    end

    bench_mnw_matroid(gen_matroid, set_constraints, rng=gen_rng(), samples=samples)
end


function bench_mnw_matroid_lazy_er59(; gen_rng=DEFAULT_GEN_RNG, samples=SAMPLES)
    rng = gen_rng()
    function gen_matroid(m)
        min_verts = ceil(Int, sqrt(2*m) + (1/2))
        n = rand(rng, min_verts:3*m)
        g = erdos_renyi(n, m, seed=rand(rng, UInt))
        GraphicMatroid(g)
    end

    function set_constraints(M)
        return function (ctx)
            ctx |> Allocations.enforce_lazy(MatroidConstraint(M))
        end
    end

    bench_mnw_matroid(gen_matroid, set_constraints, rng=gen_rng(), samples=samples)
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

    ranks = Int[]
    function collect(ctx, M)
        term_status = termination_status(ctx.model)

        if term_status in Allocations.conf.MIP_SUCCESS
            result = Allocations.mnw_result(ctx)
            @info "MNW Result" alloc = result.alloc status = term_status

            for B in result.alloc.bundle
                @assert is_indep(M, B)
            end

            push!(ranks, rank(M))
        end
    end

    b = @benchmark ctx = $run(V, M) setup = ((V, M) = $gen(); ctx = nothing) teardown = ($collect(ctx, M)) samples = samples evals = 1 seconds = TIME_LIMIT * samples

    @info "Average rank" avg = StatsPlots.mean(ranks)

    b
end


function bench_mnw_unconstrained(; gen_rng=DEFAULT_GEN_RNG, samples=SAMPLES)
    solver = create_gurobi()

    rng = gen_rng()
    function gen()
        AllocationInstances.rand_additive(n=2:6, v=VALUATION_DISTRIBUTION, rng=rng)
    end

    function run(V)
        Allocations.init_mip(V, solver, min_owners=0) |>
        Allocations.achieve_mnw(false) |>
        Allocations.solve_mip
    end

    function collect(ctx)
        result = Allocations.mnw_result(ctx)
        @info alloc = result.alloc
    end

    @benchmark ctx = $run(V) setup = (V = $gen(); ctx = nothing) teardown = ($collect(ctx)) samples = samples evals = 1 seconds = TIME_LIMIT * samples
end