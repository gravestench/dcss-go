local streams = require("constants.rng_streams")

local choice = {}

-- Source random_choose takes one draw over the number of alternatives.
-- Keeping the stream here gives every monster pool the same saved owner.
function choice.uniform(ctx, values)
    if #values == 0 then
        error("monster summon pool is empty")
    end

    return values[ctx:random(streams.MONSTER_SPELL, #values) + 1]
end

-- Source random_choose_weighted gives each positive integer weight a
-- contiguous range in one draw. Invalid modded weights fail at the call.
function choice.weighted(ctx, entries)
    local total = 0

    for _, entry in ipairs(entries) do
        if type(entry.weight) ~= "number" or
            entry.weight <= 0 or
            entry.weight ~= math.floor(entry.weight) then
            error("monster summon weight must be a positive integer")
        end

        total = total + entry.weight
    end

    if total == 0 then
        error("monster summon weighted pool is empty")
    end

    local drawn = ctx:random(streams.MONSTER_SPELL, total)

    for _, entry in ipairs(entries) do
        if drawn < entry.weight then
            return entry.id
        end

        drawn = drawn - entry.weight
    end

    error("monster summon weighted pool failed to select")
end

return choice
