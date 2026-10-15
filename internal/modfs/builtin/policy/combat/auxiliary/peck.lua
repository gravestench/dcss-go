local auxiliary = require("policy.combat.auxiliary")
local attacks = require("constants.auxiliary_attacks")
local levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")

local peck = {
    id = attacks.PECK.id,
    order = attacks.PECK.order,
    chance = 67,
    mutation_ids = { mutations.MUT_BEAK },
}

function peck.available(ctx)
    return levels.effective(ctx, ctx:player(), mutations.MUT_BEAK) > 0
end

function peck.describe()
    return {
        name = "peck",
        verb = "peck",
        base = 6,
    }
end

auxiliary.register(peck)

return peck
