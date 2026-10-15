-- Source: ouch.cc:expose_player_to_element.
local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local effects = require("policy.mutations.effects.registry")
local slow = require("policy.character.slow")

local cold = {}

function cold.level(level)
    return level > 0 and 1 or 0
end

function cold.expose(ctx, player, strength, resistance)
    if strength <= 0 or resistance > 0 or
        effects.sum(ctx, player, capabilities.COLD_BLOODED) == 0 then
        return false
    end

    if ctx:random("cold", 2) ~= 0 then
        return false
    end

    return slow.apply(ctx, player, strength)
end

function cold.run(ctx, input)
    return {
        slowed = cold.expose(ctx, ctx:player(),
            input.strength, input.resistance),
    }
end

effects.add(mutations.MUT_COLD_BLOODED, {
    [capabilities.COLD_BLOODED] = cold.level,
})

register.policy({
    id = "combat.player_cold_exposure",
    run = cold.run,
})

return cold
