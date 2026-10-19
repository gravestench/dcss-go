local attacks = require("constants.auxiliary_attacks")
local auxiliary = require("policy.combat.auxiliary")
local levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")

local tentacles = {
    id = attacks.TENTACLES.id,
    order = attacks.TENTACLES.order,
    chance = 67,
    mutation_ids = { mutations.MUT_TENTACLE_ARMS },
}

-- Tentacle Slap is offered only when the active body supplies tentacle limbs.
function tentacles.available(ctx)
    return levels.effective(ctx, ctx:player(),
        mutations.MUT_TENTACLE_ARMS) > 0
end

-- Example: tentacles.describe() with Tentacle Arms selected -> squeeze profile with base damage 12
-- Source: melee-attack.cc:AuxTentacles.
-- Tentacle Arms grants a fixed-base squeeze before the shared auxiliary damage roll.
function tentacles.describe()
    return {
        name = "squeeze",
        verb = "squeeze",
        base = 12,
    }
end

auxiliary.register(tentacles)

return tentacles
