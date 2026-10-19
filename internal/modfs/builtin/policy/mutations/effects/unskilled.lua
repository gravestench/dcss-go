local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local unskilled = {}

-- Unskilled changes aptitude and triggers a training refresh when its level changes.
-- Example: Unskilled level one adds its aptitude penalty and sanitizes training on change.
function unskilled.aptitude_penalty(level)
    return level
end

-- Reassess training when the mutation changes because an aptitude penalty
-- can invalidate a previously selected skill without changing its record.
function unskilled.on_change(ctx, owner)
    require("policy.character.skill_availability").reassess(ctx, owner)
end

registry.add(mutations.MUT_UNSKILLED, {
    [capabilities.SKILL_APTITUDE_PENALTY] = unskilled.aptitude_penalty,
    [capabilities.ON_CHANGE] = unskilled.on_change,
})

return unskilled
