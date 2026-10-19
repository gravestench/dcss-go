local boons = require("policy.combat.monster_support.boons")
local eligibility = require("policy.combat.monster_support.boon_eligibility")
local display = require("policy.combat.monster_support.display")
local duration = require("policy.combat.monster_support.duration")
local self_target = require("policy.combat.monster_support.self_target")
local channels = require("constants.message_channels")

local haste = {}

-- Plan only an absent, useful Haste so a rejected cast spends no action.
function haste.plan(ctx, caster, foe)
    if boons.hasted(ctx, caster) or
        not self_target.useful(ctx, caster, foe) or
        not eligibility.haste(ctx, caster) then
        return nil
    end

    return self_target.plan(caster)
end

-- Store the speed boon; monster energy reads this same state on later turns.
function haste.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    boons.haste(ctx, caster, duration.beneficial(ctx, caster))
    ctx:emit(channels.SPELL, "The " .. display.name(ctx, caster) ..
        " seems to speed up.")
end

return haste
