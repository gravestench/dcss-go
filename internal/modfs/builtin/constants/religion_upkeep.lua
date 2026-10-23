-- God time first fires at twenty baseline turns. Later checks are spaced
-- ten to thirty baseline turns apart, inclusive, as in timed-effects.cc.
local upkeep = {
    FIRST_AUT = 200,
    MIN_INTERVAL_AUT = 100,
    INTERVAL_SPAN = 201,
}

return upkeep
