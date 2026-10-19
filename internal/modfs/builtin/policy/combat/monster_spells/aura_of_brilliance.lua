local brilliance = require("policy.combat.monster_support.brilliance")
local self_target = require("policy.combat.monster_support.self_target")

local aura = {}

-- A visible foe and another actual allied spellcaster justify this slot.
function aura.plan(ctx, caster, foe)
    if not brilliance.useful(ctx, caster, foe) then
        return nil
    end

    return self_target.plan(caster)
end

-- The caster aura projects independently saved power onto nearby allies.
function aura.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    brilliance.cast(ctx, caster)
end

return aura
