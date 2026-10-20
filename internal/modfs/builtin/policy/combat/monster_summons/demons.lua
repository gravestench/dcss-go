local choice = require("policy.combat.monster_summons.choice")
local tiers = require("data.demon_tiers")
local streams = require("constants.rng_streams")

local demons = {}

-- One uniform draw picks inside the requested tier. A missing tier is a
-- rule error rather than an implicit fallback to unrelated demons.
function demons.tier(ctx, tier)
    local kinds = tiers[tier]

    if not kinds then
        error("unsupported source demon tier " .. tostring(tier))
    end

    return choice.uniform(ctx, kinds)
end

-- Source summon_any_demon picks a common tier-four demon sixty percent
-- of the time and a tier-three demon otherwise.
function demons.common(ctx)
    local tier = ctx:random(streams.MONSTER_SPELL, 10) < 6 and 4 or 3

    return demons.tier(ctx, tier)
end

-- Greater demons use the same sixty/forty split between tiers two and one.
function demons.greater(ctx)
    local tier = ctx:random(streams.MONSTER_SPELL, 10) < 6 and 2 or 1

    return demons.tier(ctx, tier)
end

return demons
