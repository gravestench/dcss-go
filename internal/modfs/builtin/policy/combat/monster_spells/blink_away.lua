local foe = require("policy.combat.monster_displacement.foe")
local landing = require("policy.combat.monster_displacement.landing")
local relocate = require("policy.combat.monster_displacement.relocate")

local effect = {}

-- Source Blink Away still needs a foe to flee from, even though the final
-- landing may break line of sight to that foe.
function effect.plan(ctx, caster, target)
    if not relocate.can_move(ctx, caster) then
        return nil
    end

    return foe.plan(ctx, caster, target)
end

-- Far cells receive weight proportional to distance from the foe.
function effect.resolve(ctx, caster, _, _, plan)
    local focus = foe.require_plan(ctx, caster, plan)
    local x, y = landing.weighted(ctx, caster, focus, false, false)

    if x then
        relocate.move(ctx, caster, x, y, caster)
    end
end

return effect
