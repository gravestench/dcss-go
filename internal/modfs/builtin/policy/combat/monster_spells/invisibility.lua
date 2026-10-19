local duration = require("policy.combat.monster_support.duration")
local enchant = require("policy.combat.monster_support.invisibility")
local self_target = require("policy.combat.monster_support.self_target")
local display = require("policy.combat.monster_support.display")
local channels = require("constants.message_channels")

local invisibility = {}

-- Invisibility uses the existing enchant record already read by perception.
function invisibility.plan(ctx, caster, foe)
    if enchant.active(ctx, caster) then
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

    enchant.grant(ctx, caster, duration.beneficial(ctx, caster))

    ctx:emit(channels.SPELL, "The " .. display.name(ctx, caster) ..
        " flickers and vanishes.")
end

return invisibility
