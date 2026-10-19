local attacks = require("constants.auxiliary_attacks")
local auxiliary = require("policy.combat.auxiliary")
local mutations = require("ids.mutations")
local roll = require("policy.combat.roll")

local punch = {
    id = attacks.PUNCH.id,
    order = attacks.PUNCH.order,
    mutation_ids = {
        mutations.MUT_CLAWS,
        mutations.MUT_TENTACLE_ARMS,
    },
}

-- Example: punch.chance(nil, input) with input.unarmed5 = 9 -> 8 percent attempt chance
-- Scale punch attempt chance from Unarmed Combat after offhand eligibility has been checked.
function punch.chance(_, input)
    return 5 + math.floor(input.unarmed5 / 3)
end

-- A usable offhand is required before Punch can enter the auxiliary sequence.
function punch.available(_, input)
    return input.punch_eligible
end

-- Source: melee-attack.cc:AuxPunch. Claws add one 1d3 roll per usable
-- mutation level, while Blade Hands adds six before the common damage roll.
function punch.describe(ctx, input)
    local base = 5 + roll.random_divide(ctx, input.unarmed1, 2)
    local name = "punch"

    if input.form_id == "blade_hands" then
        base = base + 6
        name = "slash"
    elseif input.claws > 0 then
        for _ = 1, input.claws do
            base = base + 1 + roll.melee(ctx, 3)
        end

        name = "claw"
    elseif input.tentacles > 0 then
        name = "tentacle-slap"
    end

    return {
        name = name,
        verb = name,
        base = base,
    }
end

auxiliary.register(punch)

return punch
