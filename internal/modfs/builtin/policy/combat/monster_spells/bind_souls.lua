-- This spell marks every eligible nearby ally; the mark itself is saved on
-- each actor, and the shared death phase turns that actor into a simulacrum.
local self_target = require("policy.combat.monster_support.self_target")
local bound_souls = require("policy.combat.monster_bound_souls")
local channels = require("constants.message_channels")

local effect = {}

-- Avoid spending a cast when no natural, corporeal ally can benefit.
function effect.plan(ctx, caster)
    if #bound_souls.recipients(ctx, caster) == 0 then
        return nil
    end

    return self_target.plan(caster)
end

-- Re-evaluate live recipients after validating the saved self target.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    bound_souls.mark(ctx, caster,
        bound_souls.recipients(ctx, caster))
    ctx:emit(channels.SPELL,
        "The monster binds the souls of nearby monsters.")
end

return effect
