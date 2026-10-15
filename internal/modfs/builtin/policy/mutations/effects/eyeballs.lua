-- Source: attack.cc:calc_to_hit and fight.cc:aux_to_hit.
local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local effects = require("policy.mutations.effects.registry")

local eyeballs = {}

function eyeballs.hit_bonus(level)
    if level <= 0 then
        return 0
    end

    return 2 * level + 1
end

function eyeballs.see_invisible(level)
    return level >= 3 and 1 or 0
end

effects.add(mutations.MUT_EYEBALLS, {
    [capabilities.ATTACK_HIT_BONUS] = eyeballs.hit_bonus,
    [capabilities.SEE_INVISIBLE] = eyeballs.see_invisible,
})

return eyeballs
