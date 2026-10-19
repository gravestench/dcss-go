local auxiliary = require("policy.combat.auxiliary")
local attacks = require("constants.auxiliary_attacks")
local mutations = require("ids.mutations")

local headbutt = {
    id = attacks.HEADBUTT.id,
    order = attacks.HEADBUTT.order,
    chance = 67,
    mutation_ids = { mutations.MUT_HORNS },
}

-- Headbutt availability is based on horns in the attack snapshot, not a new mutation lookup.
function headbutt.available(_, input)
    return input.horns > 0
end

-- Example: headbutt.describe(nil, input) with input.horns = 2 -> base damage 11
-- Scale the fixed headbutt base damage by the effective horn level in the attack snapshot.
function headbutt.describe(_, input)
    return {
        name = "headbutt",
        verb = "headbutt",
        base = 5 + input.horns * 3,
    }
end

auxiliary.register(headbutt)

return headbutt
