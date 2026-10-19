-- Source: attack.cc:calc_to_hit and fight.cc:aux_to_hit.
local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local effects = require("policy.mutations.effects.registry")

local eyeballs = {}

-- Add an attack hit bonus only while this mutation is active; rank zero contributes nothing.
-- Example: eyeballs.hit_bonus(3) returns 7; see_invisible(3) grants a separate flag.
function eyeballs.hit_bonus(level)
    if level <= 0 then
        return 0
    end

    return 2 * level + 1
end

-- Extra eyeballs reveal invisible creatures only at level three; their
-- earlier hit bonus remains a separate capability.
function eyeballs.see_invisible(level)
    return level >= 3 and 1 or 0
end

effects.add(mutations.MUT_EYEBALLS, {
    [capabilities.ATTACK_HIT_BONUS] = eyeballs.hit_bonus,
    [capabilities.SEE_INVISIBLE] = eyeballs.see_invisible,
})

return eyeballs
