-- Ru starts the first bargain early, then waits longer after each choice.
-- Rejection stacks a piety-scaled penalty before Faith shortens the wait.
local timing = {
    BASE_DELAY = 90,
    MIN_PENALTY_PIETY = 100,
    PENALTY_DIVISOR = 3,
    FAITH_MULTIPLIER = 2,
    NORMAL_MULTIPLIER = 3,
}

return timing
