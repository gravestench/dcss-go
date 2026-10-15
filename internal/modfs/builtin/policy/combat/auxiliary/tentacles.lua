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

function tentacles.available(ctx)
    return levels.effective(ctx, ctx:player(),
        mutations.MUT_TENTACLE_ARMS) > 0
end

-- Source: melee-attack.cc:AuxTentacles.
function tentacles.describe()
    return {
        name = "squeeze",
        verb = "squeeze",
        base = 12,
    }
end

auxiliary.register(tentacles)

return tentacles
