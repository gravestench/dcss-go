local ally_target = require("policy.combat.monster_support.ally_target")
local boons = require("policy.combat.monster_support.boons")
local display = require("policy.combat.monster_support.display")
local duration = require("policy.combat.monster_support.duration")
local eligibility = require("policy.combat.monster_support.boon_eligibility")
local channels = require("constants.message_channels")
local spells = require("ids.spells")
local senses = require("policy.character.senses")

local haste_other = {}

-- The source tracer selects an ally lacking Haste. A stationary or stasis
-- ally may still intercept the beam, but the beam then grants no speed.
local function benefits(ctx, target)
    return not boons.hasted(ctx, target)
end

-- Select one useful monster before the cast consumes an action or RNG.
function haste_other.plan(ctx, caster)
    return ally_target.plan(ctx, caster, spells.SPELL_HASTE_OTHER, benefits)
end

-- The recipient, not the caster, owns the duration and later speed change.
function haste_other.resolve(ctx, caster, _, _, plan)
    local target = ally_target.selected(ctx, caster, plan)

    if not target or not eligibility.haste(ctx, target) or
        boons.hasted(ctx, target) then
        return
    end

    boons.haste(ctx, target, duration.beneficial(ctx, target))

    -- The recipient's saved speed boon does not reveal an unseen ally.
    if senses.player_sees_actor(ctx, target) then
        ctx:emit(channels.SPELL, "The " .. display.name(ctx, target) ..
            " seems to speed up.")
    end
end

return haste_other
