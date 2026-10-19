local component = require("constants.component")
local fillings = require("constants.pie_fillings")
local stat_loss = require("policy.character.stat_loss")
local stats = require("constants.stats")

local raspberry = {
    id = fillings.RASPBERRY,
    weight = 10,
}

-- Example: raspberry.valid(ctx, target) with player target -> true eligibility
-- Only players have drainable stats, so monsters are excluded from raspberry selection.
function raspberry.valid(ctx, target)
    return ctx:has(target, component.PLAYER)
end

-- Raspberry drains each player stat independently on the monster-spell RNG stream.
function raspberry.apply(ctx, _, target)
    for _, stat in ipairs(stats.ORDER) do
        stat_loss.drain(ctx, target, stat,
            1 + ctx:random("monster_spell", 3))
    end

    ctx:emit("combat", "You feel diminished.")
end

return raspberry
