-- Source piety uses six star thresholds and a shared upper bound. Keeping
-- these in one module prevents UI and gameplay from drifting apart.
local piety = {
    MAX = 200,
    HYSTERESIS_LIMIT = 1,
    RU_MAX = 160,
    FAITH_DIVISOR = 4,
    TIMEOUT_CHANCE = 4,
    UPPER_TAPER_CHANCE = 3,
    XOM_BREAKPOINTS = {
        20,
        50,
        80,
        120,
        180,
    },
    BREAKPOINTS = {
        30,
        50,
        75,
        100,
        120,
        160,
    },
}

return piety
