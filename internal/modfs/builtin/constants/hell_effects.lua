-- Hell's entry punishment has four equally weighted source outcomes.
-- The constants name both the selection slots and their source parameters.
local effects = {
    BAD_MUTATION = "bad_mutation",
    DRAIN = "drain",
    STAT_LOSS = "stat_loss",
    NONE = "none",

    LOUD_CHANCE = 6,
    LOUD_VOLUME = 15,
    MAX_PIETY = 200,
    DRAIN_POWER = 100,
    STAT_DIE = 5,
}

effects.OUTCOMES = {
    effects.BAD_MUTATION,
    effects.DRAIN,
    effects.STAT_LOSS,
    effects.NONE,
}

return effects
