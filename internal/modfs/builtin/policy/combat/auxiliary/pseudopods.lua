local attacks = require("constants.auxiliary_attacks")
local auxiliary = require("policy.combat.auxiliary")
local levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")

local pseudopods = {
    id = attacks.PSEUDOPODS.id,
    order = attacks.PSEUDOPODS.order,
    chance = 67,
}

local function level(ctx)
    return levels.effective(ctx, ctx:player(), mutations.MUT_PSEUDOPODS)
end

function pseudopods.available(ctx)
    return level(ctx) > 0
end

-- Source: melee-attack.cc:AuxPseudopods.
function pseudopods.describe(ctx)
    return {
        name = "bludgeon",
        verb = "bludgeon",
        base = 4 * level(ctx),
    }
end

auxiliary.register(pseudopods)

return pseudopods
