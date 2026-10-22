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
local piety = require("policy.religion.piety")
local identity = require("policy.religion.jiyva.identity")
local allegiance = require(
    "policy.magic.effects.statuses.monster_allegiance")
local summons = require("policy.magic.effects.summons.common")
local seals = require("policy.world.slime_seals")
local senses = require("policy.character.senses")
local targets = require("policy.ai.targets")

local jiyva = {}

-- The source grants the vault release once per character, even if Jiyva
-- is later abandoned and rejoined. The saved per-god bit also makes a
-- sixth-star reward independent of whether Slime:5 exists yet.
local function unlock_vaults(ctx, player)
    local state = identity.worship(ctx, player)
    local spent = state and state.one_time_abilities or {}

    if not state or (state.penance[gods.JIYVA] or 0) > 0 or
        piety.rank(gods.JIYVA, state.piety) < 6 or
        spent[gods.JIYVA] then
        return false
    end

    spent[gods.JIYVA] = true
    state.one_time_abilities = spent
    ctx:set(player, component.RELIGION_WORSHIP, state)

    ctx:emit(channels.RELIGION,
        "Jiyva will now unseal the treasures of the Slime Pits.")

    local position = ctx:get(player, component.POSITION)

    if position then
        seals.release(ctx, position.level_id)
    end

    return true
end

-- The common piety owner reports upward rank crossings after saving the
-- new number. Reaching six stars spends Jiyva's one-time map reward.
function jiyva.rank_gained(ctx, player)
    return unlock_vaults(ctx, player)
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
    local worship = identity.worship(ctx, player)
    local actor = ctx:get(entity, component.ACTOR)

    if not worship or not actor then
        return false
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    if not identity.slime(definition) or
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
function jiyva.penance_ended(ctx, player)
    for _, entity in ipairs(ctx:query({ component.JIYVA_SLIME })) do
        local state = ctx:get(entity, component.JIYVA_SLIME)

        if state.attempted then
            state.attempted = false
            ctx:set(entity, component.JIYVA_SLIME, state)
        end
    end

    -- A sixth-star worshipper can finish penance without a rank change.
    -- The capstone resumes as soon as Jiyva is back in good standing.
    unlock_vaults(ctx, player)
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

    if not identity.slime(definition) or not valid_attitude then
        error("invalid saved Jiyva slime allegiance " .. ctx:id(entity))
    end
end

return jiyva
