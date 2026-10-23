-- Theory of operation: Fedhas' zero-star plant passive changes hostile
-- plants to good-neutral on their next action. The actor keeps that real
-- allegiance in ECS, including while off-level. Desertion turns all plants
-- hostile and clears the one-shot attempt so rejoining can convert them.
-- Joining also ends the current level's hostile awakened forest.
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local gods = require("constants.gods")
local holiness = require("constants.monster_holiness")
local monsters = require("ids.monsters")
local allegiance = require(
    "policy.magic.effects.statuses.monster_allegiance")
local targets = require("policy.ai.targets")

local fedhas = {}

-- A monster's catalog holiness is the source plant test. A mod can add a
-- plant by setting its holiness without editing this god's rule.
local function is_plant(definition)
    for _, value in ipairs(definition.holiness or {}) do
        if value == holiness.PLANT then
            return true
        end
    end

    return false
end

-- Snaplasher vines are plant-holy but explicitly excluded from the source
-- neutralisation rule; desertion still affects them like other plants.
local function can_neutralise(actor, definition)
    return is_plant(definition) and
        actor.kind_id ~= monsters.MONS_SNAPLASHER_VINE and
        actor.kind_id ~= monsters.MONS_SNAPLASHER_VINE_SEGMENT
end

-- The passive is present from zero stars and suspends under penance. Read
-- the current worship record so changing gods takes effect immediately.
function fedhas.passive_active(ctx, player)
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    return state and state.god_id == gods.FEDHAS and
        (state.penance[gods.FEDHAS] or 0) == 0 or false
end

-- Source fedhas_neutralise runs as the monster acts, not at conversion.
-- Store the result separately from vault-authored side and summon owner.
function fedhas.neutralise(ctx, player, entity)
    if not fedhas.passive_active(ctx, player) then
        return false
    end

    local actor = ctx:get(entity, component.ACTOR)

    if not actor then
        return false
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    if not can_neutralise(actor, definition) or
        targets.real_attitude(ctx, entity) ~= attitudes.HOSTILE then
        return false
    end

    local state = ctx:get(entity, component.FEDHAS_PLANT) or {}

    if state.attempted then
        return false
    end

    state.attitude = attitudes.GOOD_NEUTRAL
    state.attempted = true

    if ctx:has(entity, component.FEDHAS_PLANT) then
        ctx:set(entity, component.FEDHAS_PLANT, state)
    else
        ctx:add(entity, component.FEDHAS_PLANT, state)
    end

    return true
end

-- Source on_join removes the current floor's forest enchantment from its
-- casters. Future hostile casts use the passive check in forest policy.
function fedhas.join(ctx, player)
    local position = ctx:get(player, component.POSITION)

    if position then
        for _, caster in ipairs(ctx:query({
            component.MONSTER_AWAKE_FOREST,
            component.POSITION,
        })) do
            local forest_position = ctx:get(caster, component.POSITION)

            if forest_position.level_id == position.level_id then
                ctx:remove(caster, component.MONSTER_AWAKE_FOREST)
            end
        end
    end

    ctx:emit(channels.MONSTER,
        "The plants of the dungeon cease their hostilities.")
end

-- Desertion schedules the source's all-level plant hostility immediately in
-- this ECS world, including plants outside the current level.
function fedhas.leave(ctx)
    local changed = false

    for _, entity in ipairs(ctx:query({ component.ACTOR })) do
        local actor = ctx:get(entity, component.ACTOR)
        local definition = catalog.get(categories.MONSTERS, actor.kind_id)

        if is_plant(definition) then
            -- Source desertion strips charm before restoring hostility.
            -- Preserve unrelated frenzy and berserk state on the actor.
            local former = targets.real_attitude(ctx, entity)

            if former == attitudes.NEUTRAL or
                former == attitudes.GOOD_NEUTRAL then
                if not ctx:has(entity, component.RELIGION_WAS_NEUTRAL) then
                    ctx:add(entity, component.RELIGION_WAS_NEUTRAL, {
                        remembered = true,
                    })
                end
            end

            allegiance.clear_charm(ctx, entity)

            local state = {
                attitude = attitudes.HOSTILE,
                attempted = false,
            }

            if ctx:has(entity, component.FEDHAS_PLANT) then
                ctx:set(entity, component.FEDHAS_PLANT, state)
            else
                ctx:add(entity, component.FEDHAS_PLANT, state)
            end

            changed = true
        end
    end

    if changed then
        ctx:emit(channels.MONSTER,
            "The plants of the dungeon turn on you.")
    end
end

-- A restored allegiance can affect every later combat decision. Reject a
-- tag on a nonplant or an impossible attempted/attitude pair at load time.
function fedhas.validate(ctx, entity)
    local state = ctx:get(entity, component.FEDHAS_PLANT)

    if not state then
        return
    end

    local actor = ctx:get(entity, component.ACTOR)

    if not actor then
        error("Fedhas allegiance has no monster actor " .. ctx:id(entity))
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)
    local coherent = state.attitude == attitudes.HOSTILE and
        not state.attempted or
        state.attitude == attitudes.GOOD_NEUTRAL and state.attempted

    if not is_plant(definition) or not coherent then
        error("invalid saved Fedhas plant allegiance " .. ctx:id(entity))
    end
end

return fedhas
