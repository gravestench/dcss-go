local attacks = require("constants.auxiliary_attacks")
local auxiliary = require("policy.combat.auxiliary")
local levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")

local pseudopods = {
    id = attacks.PSEUDOPODS.id,
    order = attacks.PSEUDOPODS.order,
    chance = 67,
}

-- Use effective pseudopod rank so transformed bodies can suppress the mutation.
local function level(ctx)
    return levels.effective(ctx, ctx:player(), mutations.MUT_PSEUDOPODS)
end

-- Only an active pseudopod mutation provides this auxiliary attack.
function pseudopods.available(ctx)
    return level(ctx) > 0
end

-- Example: pseudopods.describe(ctx) with effective Pseudopods level 2 -> base damage 8
-- Source: melee-attack.cc:AuxPseudopods.
-- Pseudopod base damage grows by four for each effective mutation level.
function pseudopods.describe(ctx)
    return {
        name = "bludgeon",
        verb = "bludgeon",
        base = 4 * level(ctx),
    }
end

auxiliary.register(pseudopods)

return pseudopods
