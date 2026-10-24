-- The Shining One heals only after a kill of an evil creature. His
-- classifier is the same one used for first-sight and death conduct.
local facts = require("policy.religion.conduct.monster_facts")
local roll = require("policy.religion.kill_recovery.roll")
local stats = require("policy.combat.monster_stats")

local shining_one = {}

-- Evil holiness, unholy spells, and priest allegiance come from the
-- shared classifier; the source then makes independent HP and MP rolls.
function shining_one.amounts(ctx, victim, definition)
    if not facts.evil(ctx, victim, definition) then
        return 0, 0
    end

    local hd = stats.base_hit_dice(ctx, victim, definition)
    local hp = roll.random(ctx, 1 + 2 * hd)
    local mp = roll.random(ctx, 2 + math.floor(hd / 3))

    return hp, mp
end

return shining_one
