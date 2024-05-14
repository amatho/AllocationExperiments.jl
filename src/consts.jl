mutable struct Conf
    LOG::Bool
    LOG_EACH::UInt
end


const CONF = Conf(false, 10)
const GRB_ENV_REF = Ref{Gurobi.Env}()
const TIME_LIMIT = 300
const SAMPLES = 1000
const VALUATION = (n, m) -> DiscreteUniform(1, 50)
const DEFAULT_SEED = 7101575807226829984
const DEFAULT_GEN_RNG = rng_with_seed(DEFAULT_SEED)