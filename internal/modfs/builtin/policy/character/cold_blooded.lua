-- Example: Cold exposure can slow a cold-blooded player when the cold stream succeeds.
-- Source: ouch.cc:expose_player_to_element.
local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local effects = require("policy.mutations.effects.registry")
local slow = require("policy.character.slow")

local cold = {}

-- Treat any positive cold-blooded mutation rank as one exposure gate.
function cold.level(level)
    return level > 0 and 1 or 0
end

-- Cold resistance lowers the slowing chance before the cold-blooded mutation applies slow.
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

-- Use the current player for the exposure command and return whether Slow was applied.
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
