-- Throw Ally is a physical relocation and impact, not a beam.
local target = require("policy.combat.monster_summons.target")
local throwing = require("policy.combat.monster_throw_ally")

local effect = {}

-- A legal adjacent ally and a visible landing near the selected foe make
-- this slot useful to the source monster AI.
function effect.plan(ctx, caster, foe)
    if not throwing.possible(ctx, caster, foe) then
        return nil
    end

    return target.plan(ctx, caster, foe)
end

-- The intent retains the original foe; no later actor may inherit a toss
-- aimed at that foe's old cell.
function effect.resolve(ctx, caster, foe, _, plan)
    target.require_cell(ctx, caster, plan)

    if plan.entity ~= foe then
        error("Throw Ally target differs from selected foe")
    end

    return throwing.resolve(ctx, caster, foe)
end

return effect
