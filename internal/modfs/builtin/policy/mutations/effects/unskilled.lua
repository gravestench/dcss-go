local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local unskilled = {}

function unskilled.aptitude_penalty(level)
    return level
end

function unskilled.on_change(ctx, owner)
    require("policy.character.skill_availability").reassess(ctx, owner)
end

registry.add(mutations.MUT_UNSKILLED, {
    [capabilities.SKILL_APTITUDE_PENALTY] = unskilled.aptitude_penalty,
    [capabilities.ON_CHANGE] = unskilled.on_change,
})

return unskilled
