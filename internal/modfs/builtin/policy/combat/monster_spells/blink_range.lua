local foe = require("policy.combat.monster_displacement.foe")
local landing = require("policy.combat.monster_displacement.landing")
local relocate = require("policy.combat.monster_displacement.relocate")

local effect = {}

-- This blink requires a visible foe because its destination remains in
-- that foe's sight while increasing their separation.
function effect.plan(ctx, caster, target)
    if not relocate.can_move(ctx, caster) then
        return nil
    end

    return foe.plan(ctx, caster, target)
end

-- Source blink_range prefers distant legal cells that the foe can still
-- see, rather than an arbitrary random teleport.
function effect.resolve(ctx, caster, _, _, plan)
    local focus = foe.require_plan(ctx, caster, plan)
    local x, y = landing.weighted(ctx, caster, focus,
        false, true)

    if x then
        relocate.move(ctx, caster, x, y, caster)
    end
end

return effect
