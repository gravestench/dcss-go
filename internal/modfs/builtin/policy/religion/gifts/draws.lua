-- Gift timing draws stay on the religion stream. Keeping the source
-- random2avg and dice shapes here makes different patrons share the same
-- arithmetic without sharing their generosity rules.
local streams = require("constants.rng_streams")

local draws = {}

-- Source random2avg draws max exclusively first, then max inclusively.
function draws.average(ctx, bound)
    local first = ctx:random(streams.RELIGION, bound)
    local second = ctx:random(streams.RELIGION, bound + 1)

    return math.floor((first + second) / 2)
end

-- Source roll_dice uses one bounded draw per die and adds one per draw.
function draws.dice(ctx, count, sides)
    local total = 0

    for _ = 1, count do
        total = total + ctx:random(streams.RELIGION, sides) + 1
    end

    return total
end

return draws
