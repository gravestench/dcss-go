local allies = require("policy.combat.monster_displacement.allies")
local target = require("policy.combat.monster_summons.target")

local effect = {}

-- An allied monster already adjacent to the foe needs no encircling
-- blink; the source chooses only aligned actors farther than one cell.
function effect.plan(ctx, caster, foe)
    local plan = target.plan(ctx, caster, foe)

    if plan and #allies.candidates(ctx, caster, plan,
        "encircle") > 0 then
        return plan
    end

    return nil
end

-- Keep the originally chosen foe cell as the anchor after intent saving.
function effect.resolve(ctx, caster, _, _, plan)
    target.require_cell(ctx, caster, plan)
    allies.move(ctx, caster, plan, "encircle")
end

return effect
