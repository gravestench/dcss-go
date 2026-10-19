local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local engulf = require("policy.combat.engulf")
local flags = require("constants.monster_flags")
local intelligence = require("constants.monster_intelligence")
local landing = require("policy.combat.monster_displacement.landing")
local monsters = require("ids.monsters")
local relocate = require("policy.combat.monster_displacement.relocate")
local silence = require("policy.world.silence")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")
local attitudes = require("constants.attitude")

local recall = {}
local sight = 7

-- Friendly attitude variants are coaligned in source monster tactics;
-- neutral actors do not become helpers merely because neither attacks.
local function aligned(ctx, caster, candidate)
    return targets.attitude(ctx, caster) ~= attitudes.NEUTRAL and
        targets.real_attitude(ctx, candidate) ~= attitudes.NEUTRAL and
        targets.allied(ctx, caster) ==
            targets.real_allied(ctx, candidate)
end

-- Source monster flags are arrays. A private predicate keeps the recall
-- eligibility test about source behavior rather than table representation.
local function has_flag(definition, wanted)
    for _, value in ipairs(definition.flags or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Only living, intelligent, threatening monsters on the caster's side can
-- answer the source Word. Stationary, conjured, and ghost actors cannot.
function recall.eligible(ctx, caster, candidate)
    if candidate == caster or candidate == ctx:player() or
        not aligned(ctx, caster, candidate) then
        return false
    end

    local actor = ctx:get(candidate, component.ACTOR)
    local health = ctx:get(candidate, component.HEALTH)

    if not actor or not health or health.current <= 0 or actor.speed <= 0 or
        actor.kind_id == monsters.MONS_PLAYER_GHOST then
        return false
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    return (intelligence.rank[definition.intelligence_id] or 0) >=
            intelligence.rank[intelligence.HUMAN] and
        not has_flag(definition, flags.STATIONARY) and
        not has_flag(definition, flags.CONJURED) and
        not has_flag(definition, flags.NO_THREAT)
end

-- Recall considers the caster's whole current level, then excludes actors
-- already in its sight. Stable ECS order precedes the saved shuffle draw.
function recall.candidates(ctx, caster)
    local origin = ctx:get(caster, component.POSITION)
    local result = {}

    if not origin then
        return result
    end

    for _, entity in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        local position = ctx:get(entity, component.POSITION)

        if position.level_id == origin.level_id and
            recall.eligible(ctx, caster, entity) and
            not ctx:visible(origin.level_id, origin.x, origin.y,
                sight, position.x, position.y) then
            result[#result + 1] = entity
        end
    end

    return result
end

-- The source AI avoids a long chant when nearby allies already outweigh
-- reinforcements. Two saved d22 draws preserve its tactical probability.
function recall.can_start(ctx, caster)
    local state = ctx:get(caster, component.MONSTER_RECALL)

    if state and (state.chant_aut > 0 or state.breath_aut > 0) then
        return false
    end

    if #recall.candidates(ctx, caster) < 3 then
        return false
    end

    local origin = ctx:get(caster, component.POSITION)
    local nearby_hd = 0

    for _, entity in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        local position = ctx:get(entity, component.POSITION)
        local health = ctx:get(entity, component.HEALTH)

        if entity ~= caster and entity ~= ctx:player() and
            health.current > 0 and
            position.level_id == origin.level_id and
            aligned(ctx, caster, entity) and
            ctx:visible(origin.level_id, origin.x, origin.y,
                sight, position.x, position.y) then
            local actor = ctx:get(entity, component.ACTOR)
            local definition = catalog.get(categories.MONSTERS,
                actor.kind_id)

            local firewood = has_flag(definition, flags.STATIONARY) and
                has_flag(definition, flags.NO_THREAT)

            if not firewood then
                nearby_hd = nearby_hd + (definition.hd or 0)
            end
        end
    end

    local first = ctx:random(streams.MONSTER_SPELL, 22) + 1
    local second = ctx:random(streams.MONSTER_SPELL, 22) + 1

    return 25 + first + second > nearby_hd
end

-- Starting a chant changes only the caster's saved timer; the spell's
-- reinforcements are chosen when that timer completes three actions later.
function recall.start(ctx, caster, foe)
    local state = ctx:get(caster, component.MONSTER_RECALL)

    if state then
        state.chant_aut = 30
        state.foe = foe
        ctx:set(caster, component.MONSTER_RECALL, state)
    else
        ctx:add(caster, component.MONSTER_RECALL, {
            foe = foe,
            chant_aut = 30,
            breath_aut = 0,
        })
    end
end

-- Source silence and incapacitation interrupt recitation rather than
-- freezing the timer for a later turn.
local function interrupted(ctx, caster)
    if ctx:has(caster, component.MONSTER_MUTE) or
        engulf.silenced(ctx, caster) then
        return true
    end

    local confusion = ctx:get(caster, component.MONSTER_CONFUSION)
    local fear = ctx:get(caster, component.MONSTER_MASS_ENCHANT)
    local stasis = ctx:get(caster, component.MONSTER_STASIS)
    local paralysis = ctx:get(caster, component.PARALYSIS)

    if confusion and confusion.remaining_aut > 0 or
        fear and fear.fear_aut > 0 or
        stasis and (stasis.hibernating or stasis.petrifying_aut > 0 or
            stasis.petrified_aut > 0) or
        paralysis and paralysis.remaining_aut > 0 then
        return true
    end

    local origin = ctx:get(caster, component.POSITION)
    return silence.at(ctx, origin.level_id, origin.x, origin.y)
end

-- Source recall randomizes its follower list, tries a nearby habitable
-- cell for each, and counts only successful relocations toward its limit.
local function bring_followers(ctx, caster, state)
    local values = recall.candidates(ctx, caster)
    local origin = ctx:get(caster, component.POSITION)
    local limit = 3 + ctx:random(streams.MONSTER_SPELL, 5)
    local moved = 0

    for index = #values, 2, -1 do
        local chosen = ctx:random(streams.MONSTER_SPELL, index) + 1

        values[index], values[chosen] = values[chosen], values[index]
    end

    for _, entity in ipairs(values) do
        if moved >= limit then
            break
        end

        local x, y = landing.near(ctx, entity, origin, 3)

        if x and relocate.move(ctx, entity, x, y, caster, false) then
            moved = moved + 1

            local ai = ctx:get(entity, component.AI)

            if ai then
                local foe_pos = state.foe and ctx:get(state.foe,
                    component.POSITION)

                ai.behavior = "seek"
                ai.target_x = foe_pos and foe_pos.x or origin.x
                ai.target_y = foe_pos and foe_pos.y or origin.y
                ai.memory_until_aut = ctx:aut() + 250
                ctx:set(entity, component.AI, ai)
            end

            local player = ctx:player()
            local player_pos = player and ctx:get(player,
                component.POSITION)

            if player_pos and player_pos.level_id == origin.level_id and
                ctx:visible(origin.level_id, player_pos.x,
                    player_pos.y, sight, x, y) then
                ctx:emit(channels.SPELL, "An ally is recalled.")
            end
        end
    end

    return moved
end

-- An active caster ages its saved chant or breath once per action. Finishing
-- the chant causes one source draw for follower count and one for cooldown.
function recall.tick(ctx, caster, delta)
    local state = ctx:get(caster, component.MONSTER_RECALL)

    if not state then
        return
    end

    if state.chant_aut > 0 then
        if interrupted(ctx, caster) then
            ctx:remove(caster, component.MONSTER_RECALL)
            local player = ctx:player()
            local player_pos = player and ctx:get(player,
                component.POSITION)
            local caster_pos = ctx:get(caster, component.POSITION)

            if player_pos and caster_pos and
                player_pos.level_id == caster_pos.level_id and
                ctx:visible(caster_pos.level_id, player_pos.x,
                    player_pos.y, sight, caster_pos.x,
                    caster_pos.y) then
                ctx:emit(channels.SPELL,
                    "The recall chant is interrupted.")
            end

            return
        end

        state.chant_aut = math.max(0, state.chant_aut - delta)

        if state.chant_aut == 0 then
            bring_followers(ctx, caster, state)
            state.breath_aut = (4 + ctx:random(
                streams.MONSTER_SPELL, 9)) * 10
        end
    else
        state.breath_aut = math.max(0, state.breath_aut - delta)
    end

    if state.chant_aut == 0 and state.breath_aut == 0 then
        ctx:remove(caster, component.MONSTER_RECALL)
    else
        ctx:set(caster, component.MONSTER_RECALL, state)
    end
end

return recall
