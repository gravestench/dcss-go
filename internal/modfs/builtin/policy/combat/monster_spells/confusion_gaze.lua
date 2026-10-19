-- A Golden Eye tests its chosen foe's will, then confuses without a bolt.
local catalog = require("policy.catalog")
local component = require("constants.component")
local channels = require("constants.message_channels")
local flags = require("constants.monster_flags")
local gazes = require("policy.combat.monster_gazes")
local hex = require("policy.combat.monster_spells.hex")
local monster_confusion = require(
    "policy.magic.effects.statuses.confusing_touch")
local player_confusion = require("policy.magic.player_confusion")
local player_resistance = require("policy.combat.player_resistance")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")

local effect = {}
local profile = {
    is_enchantment = true,
    power_hd_factor = 8,
    rng_stream = streams.MONSTER_SPELL,
}

-- Monster::confuse checks clarity after the will contest and before
-- applying the confusion enchantment.
local function has_clarity(definition)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.CLARITY then
            return true
        end
    end

    return false
end

-- Source `can_see` needs sight to the foe, not an unoccupied bolt path.
function effect.plan(ctx, caster, foe)
    return gazes.plan(ctx, caster, foe,
        spells.SPELL_CONFUSION_GAZE)
end

-- The source will check uses eight spell HD. A successful gaze then rolls
-- five to seven turns and lets the existing status owner store the result.
-- Example: an eye can confuse a player behind another monster.
function effect.resolve(ctx, caster, foe, _, plan)
    gazes.require(ctx, caster, foe, plan)

    if hex.resisted(ctx, caster, foe, profile) then
        ctx:emit(channels.SPELL, "The confusion gaze is resisted.")

        return
    end

    if ctx:has(foe, component.PLAYER) then
        if player_resistance.clarity(ctx, foe) then
            ctx:emit(channels.SPELL, "You feel momentarily confused.")

            return
        end

        local turns = 5 + ctx:random(streams.MONSTER_SPELL, 3)

        player_confusion.extend(ctx, foe, turns)
        ctx:emit(channels.SPELL, "You feel confused.")

        return
    end

    local actor = ctx:get(foe, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    if has_clarity(definition) then
        return
    end

    local turns = 5 + ctx:random(streams.MONSTER_SPELL, 3)

    monster_confusion.apply_unresisted(ctx, foe, definition, turns)
end

return effect
