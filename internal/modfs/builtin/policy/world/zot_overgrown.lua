-- Theory of operation: the source overgrown stair vault starts when its
-- authored marker enters player LOS. A saved controller then rolls 30–100
-- turn countdowns and changes up to ten marked plants into oklobs. Each
-- marked cell is a separate ECS entity so save/restore keeps coordinates
-- without copying a private target list into the controller.
local component = require("constants.component")
local channels = require("constants.message_channels")
local monsters = require("ids.monsters")
local factory = require("policy.population.factory")
local senses = require("policy.character.senses")
local streams = require("constants.rng_streams")
local time = require("constants.time")
local triggers = require("constants.vault_triggers")

local overgrown = {}
local MIN_DELAY_TURNS = 30
local MAX_DELAY_TURNS = 100
local MAX_CONVERSIONS = 10

local source_plants = {
    [monsters.MONS_PLANT] = true,
    [monsters.MONS_FUNGUS] = true,
    [monsters.MONS_BUSH] = true,
}

-- Keep the source marker spelling in one constant; other DES markers stay
-- inert typed records for the feature that owns them.
function overgrown.is_record(identity)
    return identity == triggers.ZOT_OVERGROWN_START or
        identity == triggers.ZOT_OVERGROWN_TICK or
        identity == triggers.ZOT_OVERGROWN_TARGET
end

-- Roll on the gameplay stream, never the layout stream. The deadline is
-- absolute game time so saving and returning to Zot cannot restart it.
local function next_deadline(ctx)
    local range = MAX_DELAY_TURNS - MIN_DELAY_TURNS + 1
    local turns = MIN_DELAY_TURNS +
        ctx:random(streams.ZOT_OVERGROWN, range)

    return ctx:aut() + turns * time.AUT_PER_TURN
end

-- Materialize only the LOS controller and surviving source plant marks.
-- The turn marker declares the source timer site but needs no entity of
-- its own because the controller stores the deadline and conversion count.
function overgrown.materialize(ctx, level, record)
    if record.identity ~= triggers.ZOT_OVERGROWN_TICK then
        local role = record.identity == triggers.ZOT_OVERGROWN_START and
            triggers.ZOT_OVERGROWN_CONTROLLER or
            triggers.ZOT_OVERGROWN_PLANT
        local entity = ctx:create()

        ctx:add(entity, component.WORLD_ZOT_OVERGROWN, {
            level_id = level.id,
            x = record.x,
            y = record.y,
            vault_id = record.source_id,
            role = role,
            next_aut = role == triggers.ZOT_OVERGROWN_CONTROLLER and
                next_deadline(ctx) or 0,
        })
    end

    return {
        level_id = level.id,
        index = record.index,
    }
end

-- Query the saved target cells rather than trying to infer plant positions
-- from a transformed MAP. Only source plant, fungus, and bush actors count.
local function candidates(ctx, controller)
    local possible = {}

    for _, entity in ipairs(ctx:query({ component.WORLD_ZOT_OVERGROWN })) do
        local target = ctx:get(entity, component.WORLD_ZOT_OVERGROWN)

        if target.role == triggers.ZOT_OVERGROWN_PLANT and
            target.level_id == controller.level_id and
            target.vault_id == controller.vault_id then
            local actor = ctx:actor_at(target.level_id, target.x, target.y)
            local identity = actor and ctx:get(actor, component.ACTOR)

            if identity and source_plants[identity.kind_id] then
                possible[#possible + 1] = {
                    actor = actor,
                    x = target.x,
                    y = target.y,
                }
            end
        end
    end

    table.sort(possible, function(left, right)
        return left.y < right.y or
            (left.y == right.y and left.x < right.x)
    end)

    return possible
end

-- A completed source timer has no further gameplay work. Retiring its ECS
-- markers also prevents an old unseen floor from retaining dead controllers.
local function finish(ctx, controller)
    for _, entity in ipairs(ctx:query({ component.WORLD_ZOT_OVERGROWN })) do
        local state = ctx:get(entity, component.WORLD_ZOT_OVERGROWN)

        if state.level_id == controller.level_id and
            state.vault_id == controller.vault_id then
            ctx:destroy(entity)
        end
    end
end

-- The source gives a distinct first and later warning only when the
-- converted cell is visible; an unseen conversion still changes the world.
local function convert(ctx, controller, possible)
    local chosen = possible[ctx:random(streams.ZOT_OVERGROWN,
        #possible) + 1]

    -- Remove the old actor from the level's spatial index before the
    -- replacement takes its square; destroying ECS state alone leaves the
    -- grid occupied until the command batch commits.
    ctx:remove_actor(chosen.actor, controller.level_id)
    ctx:destroy(chosen.actor)
    factory.spawn(ctx, monsters.MONS_OKLOB_PLANT,
        controller.level_id, chosen.x, chosen.y, {})

    local position = {
        level_id = controller.level_id,
        x = chosen.x,
        y = chosen.y,
    }

    if senses.player_sees_cell(ctx, position) then
        if controller.warned then
            ctx:emit(channels.VAULT,
                "Another plant grows acid sacs!")
        else
            ctx:emit(channels.VAULT,
                "One of the plants suddenly grows acid sacs!")
            controller.warned = true
        end
    end

    controller.count = controller.count + 1
end

-- This runs once for each player action. LOS starts the source event, while
-- an absolute saved deadline advances it on later turns and across saves.
function overgrown.update(ctx, actor)
    if actor ~= ctx:player() then
        return
    end

    local position = ctx:get(actor, component.POSITION)

    if not position then
        return
    end

    for _, entity in ipairs(ctx:query({ component.WORLD_ZOT_OVERGROWN })) do
        local state = ctx:get(entity, component.WORLD_ZOT_OVERGROWN)

        if state.role == triggers.ZOT_OVERGROWN_CONTROLLER and
            state.level_id == position.level_id then
            local marker = {
                level_id = state.level_id,
                x = state.x,
                y = state.y,
            }

            if not state.started then
                -- The source turn trigger repeats even before LOS starts
                -- the event. Refresh an elapsed dormant deadline so a
                -- late first sighting never uses an ancient timer tick.
                if ctx:aut() >= state.next_aut then
                    state.next_aut = next_deadline(ctx)
                end

                if senses.player_sees_cell(ctx, marker) then
                    state.started = true
                    ctx:emit(channels.VAULT,
                        "You have a sense of imminent foreboding.")
                end

                ctx:set(entity, component.WORLD_ZOT_OVERGROWN, state)
            elseif ctx:aut() >= state.next_aut then
                local possible = candidates(ctx, state)

                if state.count >= MAX_CONVERSIONS or #possible == 0 then
                    finish(ctx, state)
                else
                    convert(ctx, state, possible)
                    state.next_aut = next_deadline(ctx)
                    ctx:set(entity, component.WORLD_ZOT_OVERGROWN, state)
                end
            end
        end
    end
end

return overgrown
