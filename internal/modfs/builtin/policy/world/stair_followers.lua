-- Theory of operation: tag nearby actors when a stair or portal action
-- begins, before monster decisions can move them. The arrival owner then
-- moves the marked ECS identities and removes every temporary mark.
local catalog = require("policy.catalog")
local behaviors = require("constants.ai_behaviors")
local categories = require("constants.catalog")
local component = require("constants.component")
local modes = require("constants.follower_travel")
local monsters = require("ids.monsters")
local twins = require("policy.monsters.elven_twins")
local eligibility = require("policy.world.follower_eligibility")
local placement = require("policy.world.stair_followers.placement")
local wave = require("policy.world.follower_wave")

local followers = {}
local SOURCE_LIMIT = 18

-- A mark is live for only one stair action. Clear all marks, including
-- actors no longer near the source cell after an aborted transition.
function followers.clear(ctx)
    for _, entity in ipairs(ctx:query({
        component.MONSTER_STAIR_FOLLOWER,
    })) do
        ctx:remove(entity, component.MONSTER_STAIR_FOLLOWER)
    end
end

-- A save is taken only between completed actions. Reject a stale mark
-- so restore cannot silently leave its monster unable to choose intents.
function followers.validate(ctx)
    local marked = ctx:query({
        component.MONSTER_STAIR_FOLLOWER,
    })

    if marked[1] then
        error("stale monster stair follower " .. ctx:id(marked[1]))
    end
end

-- The source has a special pair gate after ordinary follower tagging.
-- Both must qualify together; a lone survivor needs its grief allowance.
local function adjust_twins(ctx, tagged, level_id)
    for entity in pairs(tagged) do
        local other = twins.other(ctx, entity, level_id)
        local own = ctx:get(entity, component.ACTOR)
        local form = ctx:get(entity, component.MONSTER_POLYMORPH)
        local kind_id = form and form.original_kind_id or
            own.kind_id
        local is_twin = kind_id == monsters.MONS_DOWAN or
            kind_id == monsters.MONS_DUVESSA

        if is_twin then
            local grief = ctx:get(entity, component.MONSTER_ELVEN_TWIN)

            if (other and not tagged[other]) or
                (not other and not (grief and grief.can_climb)) then
                tagged[entity] = nil
            end
        end
    end
end

-- Select a connected wave from the player's cell. An accepted portal
-- action has no linked stone stair, but follows the same source tag wave.
-- The destination branch decides which marks may actually transit.
function followers.tag(ctx, player, origin, through_portal)
    followers.clear(ctx)

    if not through_portal and not eligibility.linked_stair(ctx, origin) then
        return 0
    end

    local selected = wave.select(ctx, player, origin, modes.STAIRS)
    local tagged = {}
    local count = 0

    for _, entity in ipairs(selected) do
        if count >= SOURCE_LIMIT then
            break
        end

        tagged[entity] = true
        count = count + 1
    end

    adjust_twins(ctx, tagged, origin.level_id)

    local kept = 0

    for _, entity in ipairs(selected) do
        if tagged[entity] then
            kept = kept + 1
            ctx:add(entity, component.MONSTER_STAIR_FOLLOWER, {
                taking_stairs = true,
                order = kept,
            })
        end
    end

    return kept
end

-- Sorting plain order numbers needs no ECS reads inside the comparator.
local function earlier_mark(first, second)
    return first.order < second.order
end

-- Sort the saved BFS order, not Akara query order or entity creation ID.
-- This keeps destination occupancy stable across catalog load orders.
local function ordered_marks(ctx)
    local entries = {}

    for _, entity in ipairs(ctx:query({
        component.MONSTER_STAIR_FOLLOWER,
        component.POSITION,
    })) do
        local mark = ctx:get(entity, component.MONSTER_STAIR_FOLLOWER)

        entries[#entries + 1] = {
            entity = entity,
            order = mark.order,
        }
    end

    table.sort(entries, earlier_mark)

    return entries
end

-- A remembered coordinate belongs to the old grid. Seekers now pursue
-- the arrival cell; wanderers release their old map coordinate so a save
-- and their next decision never interpret it in the destination map.
local function retarget_after_transit(ctx, entity, x, y)
    local ai = ctx:get(entity, component.AI)

    if not ai then
        return
    end

    if ai.behavior == behaviors.SEEK then
        ai.target_x = x
        ai.target_y = y
    else
        ai.target_x = 0
        ai.target_y = 0
        ai.memory_until_aut = 0
    end

    ctx:set(entity, component.AI, ai)
end

-- Transfer consumes the one-action marks after the player has settled.
-- The source serializes followers through transit; Akara can retain the
-- same entity directly because its dense grids and ECS IDs are separate.
-- A full destination leaves an actor safe on the old floor.
function followers.transfer(ctx, player, origin, level_id, x, y)
    if not eligibility.branch_allows(ctx, level_id) then
        followers.clear(ctx)
        return 0
    end

    local moved = 0

    for _, entry in ipairs(ordered_marks(ctx)) do
        local entity = entry.entity
        local position = ctx:get(entity, component.POSITION)

        if entity ~= player and position.level_id == origin.level_id then
            local arrival_x, arrival_y = placement.find(ctx, entity,
                level_id, x, y)

            if arrival_x then
                -- The saved roster belongs to the original spawn branch.
                -- Keep that provenance across later portal or stair trips.
                if not ctx:has(entity,
                    component.MONSTER_TRANSIT_ORIGIN) then
                    ctx:add(entity, component.MONSTER_TRANSIT_ORIGIN, {
                        level_id = origin.level_id,
                        branch_id = ctx:level_branch(origin.level_id),
                    })
                end

                ctx:move_actor(entity, level_id, arrival_x, arrival_y)
                retarget_after_transit(ctx, entity, x, y)
                moved = moved + 1
            else
                local actor = ctx:get(entity, component.ACTOR)
                local definition = catalog.get(categories.MONSTERS,
                    actor.kind_id)

                ctx:emit("stairs", "The " .. definition.name ..
                    " cannot follow you through the crowded stair.")
            end
        end
    end

    followers.clear(ctx)

    return moved
end

-- The generic portal transaction calls this after its owner moves the
-- player and before an ephemeral source floor can be retired. Forced
-- movement carries no marks, so it cannot accidentally acquire a wave.
function followers.portal_arrival(ctx, input)
    local player = ctx:player()
    local origin = input.origin
    local arrival = ctx:get(player, component.POSITION)

    if not origin or not arrival or
        origin.level_id == arrival.level_id then
        followers.clear(ctx)
        return { moved = 0 }
    end

    return {
        moved = followers.transfer(ctx, player, origin,
            arrival.level_id, arrival.x, arrival.y),
    }
end

register.policy({
    id = "world.portal_followers",
    run = followers.portal_arrival,
})

return followers
