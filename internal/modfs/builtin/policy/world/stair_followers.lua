-- Theory of operation: tag nearby actors when an ordinary stair action
-- begins, before monster decisions can move them. The stair system later
-- moves the marked ECS identities and removes every temporary mark.
local catalog = require("policy.catalog")
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

-- Select a connected wave from the player's cell. The eight-neighbor
-- order is fixed in Lua, so content load order cannot change a seed.
function followers.tag(ctx, player, origin)
    followers.clear(ctx)

    if not eligibility.linked_stair(ctx, origin) or
        not eligibility.branch_allows(ctx, origin.level_id) then
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

-- Transfer consumes the one-action marks after the player has settled.
-- The source serializes followers through transit; Akara can retain the
-- same entity directly because its dense grids and ECS IDs are separate.
-- A full destination leaves an actor safe on the old floor.
function followers.transfer(ctx, player, origin, level_id, x, y)
    local moved = 0

    for _, entry in ipairs(ordered_marks(ctx)) do
        local entity = entry.entity
        local position = ctx:get(entity, component.POSITION)

        if entity ~= player and position.level_id == origin.level_id then
            local arrival_x, arrival_y = placement.find(ctx, entity,
                level_id, x, y)

            if arrival_x then
                ctx:move_actor(entity, level_id, arrival_x, arrival_y)
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

return followers
