const GRB_ENV_REF = Ref{Gurobi.Env}()
const TIME_LIMIT = 300
const SAMPLES = 1000
const VALUATION_DISTRIBUTION = DiscreteUniform(1, 10)