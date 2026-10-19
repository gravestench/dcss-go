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

-- The beak mutation gates Peck; the shared auxiliary resolver handles its chance and order.
function peck.available(ctx)
    return levels.effective(ctx, ctx:player(), mutations.MUT_BEAK) > 0
end

-- Example: peck.describe() with Peck selected -> fixed base damage 6
-- Peck keeps a fixed message because its beak attack has no equipment variant.
function peck.describe()
    return {
        name = "peck",
        verb = "peck",
        base = 6,
    }
end

auxiliary.register(peck)

return peck
