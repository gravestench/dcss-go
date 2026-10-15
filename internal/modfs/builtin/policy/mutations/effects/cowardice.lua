local capabilities = require("constants.mutation_capabilities")
local component = require("constants.component")
local levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local cowardice = {}

function cowardice.changed(ctx, player)
    if levels.effective(ctx, player, mutations.MUT_COWARDICE) == 0 and
        ctx:has(player, component.HORROR) then
        ctx:remove(player, component.HORROR)
    end
end

registry.add(mutations.MUT_COWARDICE, {
    [capabilities.ON_CHANGE] = cowardice.changed,
})

return cowardice
