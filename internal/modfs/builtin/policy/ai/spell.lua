local effects = require("policy.combat.monster_spells")
local spellbook = require("policy.combat.monster_spellbook")
local prospect = require("policy.ai.spell_prospect")
local target = require("policy.combat.monster_spell_target")
local statuses = require("policy.magic.effects.statuses.player")
local engulf = require("policy.combat.engulf")
local component = require("constants.component")
local intents = require("constants.intent")
local spell_flags = require("constants.spell_flags")
local brilliance = require("policy.combat.monster_support.brilliance")

local spell = {}

-- Spell range uses grid distance, matching diagonal targeting.
local function distance_between(position, target)
    return math.max(math.abs(position.x - target.x),
        math.abs(position.y - target.y))
end

-- Sample silence before considering the caster's spell slots.
local function silenced(ctx, entity, position, player)
    if ctx:has(entity, component.MONSTER_MUTE) then
        return true
    end

    if engulf.silenced(ctx, entity) then
        return true
    end

    local radius = statuses.silence_radius(ctx, ctx:player())

    return radius >= 0 and distance_between(position, player) <= radius
end

-- Collect tactical flags once so slot filters see one state.
local function condition_for(ctx, entity, position, player, fleeing)
    local health = ctx:get(entity, component.HEALTH)

    if not health then
        error("monster " .. ctx:id(entity) .. " has no health for spell choice")
    end

    return {
        hp = health.current,
        max_hp = health.max,
        distance = distance_between(position, player),
        fleeing = fleeing,
        silenced = silenced(ctx, entity, position, player),
    }
end

-- Retry only when an effect cannot plan a target; a no-spell prospect result is final for this turn.
local function select_targetable(ctx, entity, book, condition)
    -- The prospect policy accepts a draw callback so all choices use this
    -- actor's saved monster-spell stream, including a brilliance reroll.
    local function random(bound)
        return ctx:random("monster_spell", bound)
    end

    local reroll = brilliance.empowered(ctx, entity)

    for attempt = 1, 2 do
        local preference = nil

        if attempt == 2 and random(2) == 0 then
            preference = spell_flags.SELF_ENCHANT
        end

        local slot, index = prospect.choose(book, condition, random,
            preference)

        -- mon-cast.cc grants an empowered caster one extra prospect when
        -- the 200-point draw selected no spell. A target failure still uses
        -- the ordinary second attempt below.
        if not slot and reroll then
            slot, index = prospect.choose(book, condition, random,
                preference)
            reroll = false
        end

        -- Source does not retry when the 200-point roll chose no spell.
        if not slot then
            return nil
        end

        local effect = effects.effect(slot.spell_id)

        local plan = effect.plan(ctx, entity, ctx:player(), slot)

        if plan then
            return slot, index, plan
        end
    end

    return nil
end

-- Build a cast intent only after book selection, target planning, and antimagic checks agree.
-- Example: silence is included in prospect conditions before a book slot becomes a targetable intent.
function spell.choose(ctx, entity, position, player, fleeing)
    local book = spellbook.for_actor(ctx, entity)

    if not book then
        return nil
    end

    local condition = condition_for(ctx, entity, position, player, fleeing)
    local slot, index, plan = select_targetable(ctx, entity, book,
        condition)

    if not slot or statuses.enfeeble_antimagic(ctx, entity, slot.flags) then
        return nil
    end

    local intent = {
        kind = intents.SPELL,
        spell_id = slot.spell_id,
        spell_slot = index,
    }

    return target.write(intent, plan)
end

return spell
