create_gurobi() = optimizer_with_attributes(() -> Gurobi.Optimizer(GRB_ENV_REF[]), "LogToConsole" => 0, "TimeLimit" => TIME_LIMIT)


function bench_mnw_matroid_lazy_knu74(; gen_rng=DEFAULT_GEN_RNG, samples=SAMPLES)
    rng = gen_rng()
    function gen_matroid(m)
        rand_matroid_knu74_1(m, [0, 15, 6], rng=rng)
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
        rand_matroid_er59(m, rng=rng)
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
#         rand_matroid_knu74_1(m, [0, 15, 6], rng=rng)
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
        V = rand_additive(n=2:6, v=VALUATION, rng=rng)
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

    count = 0
    ranks = Int[]
    ef1_checks = Bool[]
    efx_checks = Bool[]
    mms_alphas = Float64[]
    function collect(ctx, M)
        if count == 0
            count += 1
            return
        end

        term_status = termination_status(ctx.model)

        if term_status in Allocations.conf.MIP_SUCCESS
            result = Allocations.mnw_result(ctx)
            count % 10 == 0 && @info "Finished sample number $count"

            V, A = ctx.profile, result.alloc

            @assert check(V, A, MatroidConstraint(M)) "Allocation does not satisfy matroid constraint"

            push!(ranks, rank(M))
            push!(ef1_checks, check_ef1(V, A))
            push!(efx_checks, check_efx(V, A))

            mmss = [mms(V, i, solver=solver).mms for i in agents(V)]
            push!(mms_alphas, mms_alpha(V, A, mmss))

            count += 1
        end
    end

    b = @benchmark ctx = $run(V, M) setup = ((V, M) = $gen(); ctx = nothing) teardown = ($collect(ctx, M)) samples = samples evals = 1 seconds = TIME_LIMIT * samples

    mean_rank = mean(ranks)
    mean_ef1 = mean(ef1_checks)
    mean_efx = mean(efx_checks)
    mean_mms_alpha = mean(mms_alphas)
    @info "Statistics over $samples samples" mean_rank mean_ef1 mean_efx mean_mms_alpha

    b
end


function bench_mnw_unconstrained(; gen_rng=DEFAULT_GEN_RNG, samples=SAMPLES)
    solver = create_gurobi()

    rng = gen_rng()
    function gen()
        rand_additive(n=2:6, v=VALUATION, rng=rng)
    end

    function run(V)
        Allocations.init_mip(V, solver, min_owners=0) |>
        Allocations.achieve_mnw(false) |>
        Allocations.solve_mip
    end

    count = 0
    ef1_checks = Bool[]
    efx_checks = Bool[]
    mms_alphas = Float64[]
    function collect(ctx)
        if count == 0
            count += 1
            return
        end

        result = Allocations.mnw_result(ctx)
        count % 10 == 0 && @info "Finished sample number $count"

        V, A = ctx.profile, result.alloc

        push!(ef1_checks, check_ef1(V, A))
        push!(efx_checks, check_efx(V, A))

        mmss = [mms(V, i, solver=solver).mms for i in agents(V)]
        push!(mms_alphas, mms_alpha(V, A, mmss))

        count += 1
    end

    b = @benchmark ctx = $run(V) setup = (V = $gen(); ctx = nothing) teardown = ($collect(ctx)) samples = samples evals = 1 seconds = TIME_LIMIT * samples

    mean_ef1 = mean(ef1_checks)
    mean_efx = mean(efx_checks)
    mean_mms_alpha = mean(mms_alphas)
    @info "Statistics over $samples samples" mean_ef1 mean_efx mean_mms_alpha

    b
end
