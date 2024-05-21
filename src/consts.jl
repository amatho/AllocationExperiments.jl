mutable struct Conf
    LOG::Bool
    LOG_EACH::UInt
    GUROBI
    HIGHS
end

const CONF = Conf(true, 100, nothing, nothing)
const GRB_ENV_REF = Ref{Gurobi.Env}()
const TIME_LIMIT = 300
const SAMPLES = 1000
const DEFAULT_SEED = 7101575807226829984
const DEFAULT_GEN_RNG = rng_with_seed(DEFAULT_SEED)

function __init__()
    debug_logger = Logging.ConsoleLogger(Logging.Info)
    Logging.global_logger(debug_logger)

    global GRB_ENV_REF
    GRB_ENV_REF[] = Gurobi.Env()
    CONF.GUROBI = optimizer_with_attributes(
        () -> Gurobi.Optimizer(GRB_ENV_REF[]),
        "LogToConsole" => 0,
        "TimeLimit" => TIME_LIMIT
    )

    CONF.HIGHS = optimizer_with_attributes(
        HiGHS.Optimizer,
        "log_to_console" => false,
        "time_limit" => float(TIME_LIMIT)
    )

    return
end
