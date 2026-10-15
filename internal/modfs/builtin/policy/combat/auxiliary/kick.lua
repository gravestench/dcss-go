local auxiliary = require("policy.combat.auxiliary")
local attacks = require("constants.auxiliary_attacks")
local mutations = require("ids.mutations")

local kick = {
    id = attacks.KICK.id,
    order = attacks.KICK.order,
    chance = 100,
    mutation_ids = {
        mutations.MUT_HOOVES,
        mutations.MUT_TALONS,
        mutations.MUT_TENTACLE_SPIKE,
    },
}

function kick.available(_, input)
    return input.hooves > 0 or input.talons > 0 or
        input.tentacle_spike > 0
end

-- Source: melee-attack.cc:AuxKick. Tentacle spikes are a kick variant.
function kick.describe(_, input)
    if input.hooves > 0 then
        return {
            name = "kick",
            verb = "kick",
            base = 5 + math.floor(input.hooves * 5 / 3),
        }
    end

    if input.talons > 0 then
        return {
            name = "kick",
            verb = "claw",
            base = 6 + input.talons,
        }
    end

    return {
        name = "tentacle spike",
        verb = "pierce",
        base = 5 + input.tentacle_spike,
    }
end

auxiliary.register(kick)

return kick
