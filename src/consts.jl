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

function __init__()
    debug_logger = Logging.ConsoleLogger(Logging.Info)
    Logging.global_logger(debug_logger)

    global GRB_ENV_REF
    GRB_ENV_REF[] = Gurobi.Env(output_flag=0)
    CONF.GUROBI = optimizer_with_attributes(
        () -> Gurobi.Optimizer(GRB_ENV_REF[]),
        "TimeLimit" => TIME_LIMIT
    )
    CONF.GUROBI_MMS = optimizer_with_attributes(
        () -> Gurobi.Optimizer(GRB_ENV_REF[]),
        "TimeLimit" => TIME_LIMIT,
        "MIPGap" => 0.05
    )

    CONF.HIGHS = optimizer_with_attributes(
        HiGHS.Optimizer,
        "log_to_console" => false,
        "time_limit" => float(TIME_LIMIT)
    )

    return
end
