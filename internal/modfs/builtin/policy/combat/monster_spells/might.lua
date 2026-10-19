local boons = require("policy.combat.monster_support.boons")
local eligibility = require("policy.combat.monster_support.boon_eligibility")
local display = require("policy.combat.monster_support.display")
local duration = require("policy.combat.monster_support.duration")
local self_target = require("policy.combat.monster_support.self_target")
local channels = require("constants.message_channels")

local might = {}

-- A duplicate Might enchantment cannot earn another monster spell slot.
function might.plan(ctx, caster, foe)
    if boons.mighty(ctx, caster) or
        not self_target.useful(ctx, caster, foe) or
        not eligibility.might(ctx, caster) then
        return nil
    end

    return self_target.plan(caster)
end

-- Both spells and Chaos read the same saved melee-damage timer.
function might.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    boons.might(ctx, caster, duration.beneficial(ctx, caster))
    ctx:emit(channels.SPELL, "The " .. display.name(ctx, caster) ..
        " seems to grow stronger.")
end

return might
