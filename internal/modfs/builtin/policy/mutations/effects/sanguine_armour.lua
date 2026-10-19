local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")
local sanguine = require("policy.character.sanguine_armour")

local effect = {}

-- Sanguine armour contributes a derived defense bonus, not a worn item.
-- Example: Sanguine Armour level two contributes 900 scaled AC only while its saved state is active.
function effect.armour(level, ctx, player)
    if not sanguine.active(ctx, player) then
        return 0
    end

    return 300 + level * 300
end

registry.add(mutations.MUT_SANGUINE_ARMOUR, {
    [capabilities.AC_FULL_X100] = effect.armour,
})

return effect
