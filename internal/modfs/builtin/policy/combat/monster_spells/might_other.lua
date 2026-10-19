local ally_target = require("policy.combat.monster_support.ally_target")
local boons = require("policy.combat.monster_support.boons")
local display = require("policy.combat.monster_support.display")
local duration = require("policy.combat.monster_support.duration")
local eligibility = require("policy.combat.monster_support.boon_eligibility")
local channels = require("constants.message_channels")
local spells = require("ids.spells")
local senses = require("policy.character.senses")

local might_other = {}

-- A second Might enchantment does not benefit the recipient; the source
-- still lets a stationary ally intercept the beam without gaining Might.
local function benefits(ctx, target)
    return not boons.mighty(ctx, target)
end

-- Reuse the source's allied beam selection, independent of self buffs.
function might_other.plan(ctx, caster)
    return ally_target.plan(ctx, caster, spells.SPELL_MIGHT_OTHER, benefits)
end

-- Shared boon state feeds the existing monster melee damage calculation.
function might_other.resolve(ctx, caster, _, _, plan)
    local target = ally_target.selected(ctx, caster, plan)

    if not target or not eligibility.might(ctx, target) or
        boons.mighty(ctx, target) then
        return
    end

    boons.might(ctx, target, duration.beneficial(ctx, target))

    -- A buffed ally may stand outside the player's sight.
    if senses.player_sees_actor(ctx, target) then
        ctx:emit(channels.SPELL, "The " .. display.name(ctx, target) ..
            " seems to grow stronger.")
    end
end

return might_other
