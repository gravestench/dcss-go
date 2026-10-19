local component = require("constants.component")
local foe = require("policy.combat.monster_displacement.foe")
local landing = require("policy.combat.monster_displacement.landing")
local relocate = require("policy.combat.monster_displacement.relocate")

local effect = {}

-- Closing a gap is pointless when the caster is already adjacent.
function effect.plan(ctx, caster, target)
    local focus = foe.position(ctx, caster, target)
    local origin = ctx:get(caster, component.POSITION)

    if not relocate.can_move(ctx, caster) or not focus or
        math.max(math.abs(origin.x - focus.x),
            math.abs(origin.y - focus.y)) <= 1 then
        return nil
    end

    return foe.plan(ctx, caster, target)
end

-- Keep the moved monster in its foe's sight and prefer nearby cells by
-- the source's squared remaining-sight-radius weight.
function effect.resolve(ctx, caster, _, _, plan)
    local focus = foe.require_plan(ctx, caster, plan)
    local x, y = landing.weighted(ctx, caster, focus, true, true)

    if x then
        relocate.move(ctx, caster, x, y, caster)
    end
end

return effect
