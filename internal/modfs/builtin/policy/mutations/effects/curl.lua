local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")
local curl = require("policy.character.curl")

local effect = {}

-- Curling armour is a derived value consumed by the player's defense formula.
-- Example: Curl contributes 700 scaled AC only while the player's curl state is active.
function effect.armour(level, ctx, player)
    if level > 0 and curl.active(ctx, player) then
        return 700
    end

    return 0
end

registry.add(mutations.MUT_CURL, {
    [capabilities.AC_FULL_X100] = effect.armour,
})

return effect
