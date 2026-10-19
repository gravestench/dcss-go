-- Zot clock bounds and reset periods are stored in aut for each branch.

-- zot.h and zot.cc: clocks are stored in aut, separately for each branch.
local clock = {
    MAX_AUT = 270000,
    FLOOR_AUT = 60000,
    ORDINARY_RESET_TURNS = 1000,
    SHORT_RESET_TURNS = 200,
    AUT_PER_TURN = 10,
    DRAIN_POWER = 270,
    RNG_STREAM = "zot-clock",
}

return clock
