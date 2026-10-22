-- Theory of operation: Jiyva's zero-star passive makes jellies and the
-- source's two eye genera good-neutral when they next act. An attempted
-- conversion is saved on that actor. Penance blocks the change but still
-- consumes the attempt; paying it off clears those attempts for another
-- monster turn. Desertion restores hostility only to Jiyva's converts.
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local gods = require("constants.gods")
local flags = require("constants.monster_flags")
local monsters = require("ids.monsters")
local allegiance = require(
    "policy.magic.effects.statuses.monster_allegiance")
local summons = require("policy.magic.effects.summons.common")
local senses = require("policy.character.senses")
local targets = require("policy.ai.targets")

local jiyva = {}

local slime_genera = {
    [monsters.MONS_JELLY] = true,
    [monsters.MONS_FLOATING_EYE] = true,
    [monsters.MONS_GLOWING_ORANGE_BRAIN] = true,
}

-- Source mons_class_is_slime uses these genera rather than holiness or
-- glyph. A modded member can join the family by using a source genus ID.
local function is_slime(definition)
    return slime_genera[definition.genus_id] or false
end

-- The rank-minus-one passive survives penance. Only the actual conversion
-- waits; this matters because penance still consumes the actor's attempt.
local function worship_state(ctx, player)
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    if state and state.god_id == gods.JIYVA then
        return state
    end

    return nil
end

-- A monster changing its real side loses only owned summons still on the
-- former side. Collect first because expiry removes entities from the ECS.
local function dismiss_opposed_summons(ctx, owner, new_attitude)
    local opposed = {}

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        local state = ctx:get(entity, component.SUMMON)

        if state.owner == owner and state.attitude ~= new_attitude then
            opposed[#opposed + 1] = entity
        end
    end

    for _, entity in ipairs(opposed) do
        summons.expire(ctx, entity)
    end
end

-- Source monster names omit the article for uniques such as Dissolution.
local function subject(definition)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.UNIQUE then
            return definition.name
        end
    end

    return "The " .. definition.name
end

-- The source calls slime_convert just before the monster chooses an act.
-- Temporary charm and already-neutral sides prevent another attempt.
function jiyva.neutralise(ctx, player, entity)
    local worship = worship_state(ctx, player)
    local actor = ctx:get(entity, component.ACTOR)

    if not worship or not actor then
        return false
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    if not is_slime(definition) or
        targets.attitude(ctx, entity) ~= attitudes.HOSTILE then
        return false
    end

    local state = ctx:get(entity, component.JIYVA_SLIME) or {
        attitude = attitudes.HOSTILE,
        attempted = false,
    }

    if state.attempted then
        return false
    end

    state.attempted = true

    if (worship.penance[gods.JIYVA] or 0) == 0 then
        state.attitude = attitudes.GOOD_NEUTRAL
    end

    if ctx:has(entity, component.JIYVA_SLIME) then
        ctx:set(entity, component.JIYVA_SLIME, state)
    else
        ctx:add(entity, component.JIYVA_SLIME, state)
    end

    if state.attitude == attitudes.GOOD_NEUTRAL then
        dismiss_opposed_summons(ctx, entity, state.attitude)
    end

    if state.attitude == attitudes.GOOD_NEUTRAL and
        senses.player_sees_actor(ctx, entity) then
        local message

        if definition.genus_id == monsters.MONS_FLOATING_EYE then
            message = subject(definition) ..
                " stares at you suspiciously for a moment, then relaxes."
        else
            message = subject(definition) ..
                " trembles before you."
        end

        ctx:emit(channels.RELIGION, message)
    end

    return state.attitude == attitudes.GOOD_NEUTRAL
end

-- The source's DACT_SLIME_NEW_ATTEMPT clears saved attempt flags on every
-- slime after penance ends, including one that never converted.
function jiyva.penance_ended(ctx)
    for _, entity in ipairs(ctx:query({ component.JIYVA_SLIME })) do
        local state = ctx:get(entity, component.JIYVA_SLIME)

        if state.attempted then
            state.attempted = false
            ctx:set(entity, component.JIYVA_SLIME, state)
        end
    end
end

-- Abandonment affects only good-neutral Jiyva converts, not unrelated
-- neutral monsters. Charm is removed as part of the source daction.
function jiyva.leave(ctx)
    local changed = false

    for _, entity in ipairs(ctx:query({ component.JIYVA_SLIME })) do
        local state = ctx:get(entity, component.JIYVA_SLIME)

        if state.attitude == attitudes.GOOD_NEUTRAL then
            state.attitude = attitudes.HOSTILE
            state.attempted = false
            ctx:set(entity, component.JIYVA_SLIME, state)
            allegiance.clear_charm(ctx, entity)
            dismiss_opposed_summons(ctx, entity, state.attitude)

            changed = true
        end
    end

    if changed then
        ctx:emit(channels.MONSTER,
            "All of your fellow slimes turn on you.")
    end
end

-- A saved allegiance tag cannot turn a non-slime into a god gift.
function jiyva.validate(ctx, entity)
    local state = ctx:get(entity, component.JIYVA_SLIME)

    if not state then
        return
    end

    local actor = ctx:get(entity, component.ACTOR)

    if not actor then
        error("Jiyva allegiance has no monster actor " .. ctx:id(entity))
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)
    local valid_attitude = state.attitude == attitudes.HOSTILE or
        state.attitude == attitudes.GOOD_NEUTRAL

    if not is_slime(definition) or not valid_attitude then
        error("invalid saved Jiyva slime allegiance " .. ctx:id(entity))
    end
end

return jiyva
