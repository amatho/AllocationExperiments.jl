mutable struct Conf
    LOG::Bool
    LOG_EACH::Int
    GUROBI
    GUROBI_MMS
    HIGHS
end

const CONF = Conf(true, 10, nothing, nothing, nothing)
const GRB_ENV_REF = Ref{Gurobi.Env}()
const TIME_LIMIT = 300
const SAMPLES = 1000
const DEFAULT_SEED = 7101575807226829984
const DEFAULT_GEN_RNG = rng_with_seed(DEFAULT_SEED)

function parse_env(t::Type, key::AbstractString)
    val = get(ENV, key, nothing)
    if !isnothing(val)
        val = tryparse(t, val)
    end
    return val
end

function __init__()
    debug_logger = Logging.ConsoleLogger(Logging.Info)
    Logging.global_logger(debug_logger)

    global GRB_ENV_REF
    GRB_ENV_REF[] = Gurobi.Env(output_flag=0)

    gurobi_attributes = Pair["TimeLimit" => TIME_LIMIT]
    highs_attributes = Pair[
        "log_to_console" => false,
        "time_limit" => float(TIME_LIMIT)
    ]
    threads = parse_env(Int, "SLURM_CPUS_PER_TASK")
    if !isnothing(threads)
        push!(gurobi_attributes, "Threads" => threads)
        push!(highs_attributes, "threads" => threads)
    end
    mem = parse_env(Int, "SLURM_MEM_PER_NODE")
    if !isnothing(mem)
        push!(gurobi_attributes, "SoftMemLimit" => mem / 1024)
    end

    display(gurobi_attributes)
    display(highs_attributes)

    CONF.GUROBI = optimizer_with_attributes(
        () -> Gurobi.Optimizer(GRB_ENV_REF[]),
        gurobi_attributes...
    )
    CONF.GUROBI_MMS = optimizer_with_attributes(
        () -> Gurobi.Optimizer(GRB_ENV_REF[]),
        "MIPGap" => 0.05,
        gurobi_attributes...
    )

    CONF.HIGHS = optimizer_with_attributes(
        HiGHS.Optimizer,
        highs_attributes...
    )

    return
end
