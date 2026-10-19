local allies = require("policy.combat.monster_displacement.allies")
local target = require("policy.combat.monster_summons.target")

local effect = {}

-- A rescue blink is useful only when an aligned movable actor is within
-- two cells of the selected foe at planning time.
function effect.plan(ctx, caster, foe)
    local plan = target.plan(ctx, caster, foe)

    if plan and #allies.candidates(ctx, caster, plan, "away") > 0 then
        return plan
    end

    return nil
end

-- Source Blink Allies Away attempts shuffled allies until its successful
-- move limit is reached; a blocked ally does not spend another ally's slot.
function effect.resolve(ctx, caster, _, _, plan)
    target.require_cell(ctx, caster, plan)
    allies.move(ctx, caster, plan, "away")
end

return effect
