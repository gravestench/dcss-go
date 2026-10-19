local ally_target = require("policy.combat.monster_support.ally_target")
local display = require("policy.combat.monster_support.display")
local duration = require("policy.combat.monster_support.duration")
local invisibility = require("policy.combat.monster_support.invisibility")
local channels = require("constants.message_channels")
local spells = require("ids.spells")
local senses = require("policy.character.senses")

local invisibility_other = {}

-- The source never targets a monster whose invisibility enchant is active.
local function benefits(ctx, target)
    return not invisibility.active(ctx, target)
end

-- Choose one allied recipient through the same beam path as other buffs.
function invisibility_other.plan(ctx, caster)
    return ally_target.plan(ctx, caster,
        spells.SPELL_INVISIBILITY_OTHER, benefits)
end

-- Perception reads the shared enchant owner, so this recipient disappears
-- from sight through the same rules as a monster's self spell.
function invisibility_other.resolve(ctx, caster, _, _, plan)
    local target = ally_target.selected(ctx, caster, plan)

    if not target or invisibility.active(ctx, target) then
        return
    end

    -- Record sight before applying the enchant, so an observed ally can
    -- visibly vanish without revealing one the player never perceived.
    local seen = senses.player_sees_actor(ctx, target)

    invisibility.grant(ctx, target, duration.beneficial(ctx, target))

    if seen then
        ctx:emit(channels.SPELL, "The " .. display.name(ctx, target) ..
            " flickers and vanishes.")
    end
end

return invisibility_other
