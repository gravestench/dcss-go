local boons = require("policy.combat.monster_support.boons")
local display = require("policy.combat.monster_support.display")
local duration = require("policy.combat.monster_support.duration")
local self_target = require("policy.combat.monster_support.self_target")

local sprint = {}

-- Sprint's Swift enchantment is only useful while its timer is absent.
function sprint.plan(ctx, caster)
    if boons.swift_active(ctx, caster) then
        return nil
    end

    return self_target.plan(caster)
end

-- The saved Swift timer lowers movement energy without changing attacks.
function sprint.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    boons.swift(ctx, caster, duration.beneficial(ctx, caster))
    ctx:emit("spell", "The " .. display.name(ctx, caster) ..
        " puts on a burst of speed!")
end

return sprint
