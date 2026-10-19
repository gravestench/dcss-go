local landing = require("policy.combat.monster_displacement.landing")
local relocate = require("policy.combat.monster_displacement.relocate")
local self_target = require("policy.combat.monster_support.self_target")

local effect = {}

-- A no-tele caster cannot offer Blink as a useful spellbook action.
function effect.plan(ctx, caster)
    return relocate.can_move(ctx, caster) and
        self_target.plan(caster) or nil
end

-- Source monster_blink finds a distant nearby cell only after the action
-- commits; a blocked search spends the cast without moving the caster.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local x, y = landing.ordinary(ctx, caster)

    if x then
        relocate.move(ctx, caster, x, y, caster)
    end
end

return effect
