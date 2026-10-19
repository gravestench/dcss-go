local recall = require("policy.combat.monster_displacement.recall")
local self_target = require("policy.combat.monster_support.self_target")

local effect = {}

-- The source caster needs at least three eligible allies outside its sight
-- and must not already be chanting or recovering its breath.
function effect.plan(ctx, caster)
    if not recall.can_start(ctx, caster) then
        return nil
    end

    return self_target.plan(caster)
end

-- Only the chant starts now. The active recall system will resolve it after
-- thirty aut, even if a save is taken between cast and completion.
function effect.resolve(ctx, caster, foe, _, plan)
    self_target.require_caster(plan, caster)
    recall.start(ctx, caster, foe)
end

return effect
