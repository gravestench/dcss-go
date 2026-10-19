local duration = require("policy.combat.monster_support.duration")
local self_target = require("policy.combat.monster_support.self_target")
local component = require("constants.component")
local display = require("policy.combat.monster_support.display")

local invisibility = {}

-- Invisibility uses the existing enchant record already read by perception.
function invisibility.plan(ctx, caster, foe)
    local current = ctx:get(caster, component.MONSTER_ENCHANT)

    if current and current.invisible_aut > 0 then
        return nil
    end

    if not self_target.useful(ctx, caster, foe) then
        return nil
    end

    return self_target.plan(caster)
end

-- Preserve blindness and corrosion while granting a new invisibility timer.
function invisibility.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local current = ctx:get(caster, component.MONSTER_ENCHANT) or {
        blind_aut = 0,
        corrosion_aut = 0,
        invisible_aut = 0,
    }

    current.invisible_aut = duration.beneficial(ctx, caster)

    if ctx:has(caster, component.MONSTER_ENCHANT) then
        ctx:set(caster, component.MONSTER_ENCHANT, current)
    else
        ctx:add(caster, component.MONSTER_ENCHANT, current)
    end

    ctx:emit("spell", "The " .. display.name(ctx, caster) ..
        " flickers and vanishes.")
end

return invisibility
