-- Theory of operation: source Abyss window changes erase most monsters,
-- but a banished monster, unique, or unusually strong stair user can return.
-- The saved transit ledger names live ECS actors parked on an inert region.
-- Their health, AI, and carried gear stay on those actors, so this rule never
-- invents a partial serialized monster or drops its unique identity.
local abyss = require("constants.abyss")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local streams = require("constants.rng_streams")
local catalog = require("policy.catalog")
local terrain = require("constants.terrain")

local transit = {}

-- Source excludes summons and conjured bodies before considering a unique,
-- a banished actor, or a strong ordinary monster. Stationary bodies cannot
-- follow the source's stair-user route.
local function should_keep(ctx, entity)
    if ctx:has(entity, component.SUMMON) then
        return false
    end

    local actor = ctx:get(entity, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local unique = false
    local conjured = false
    local stationary = false

    for _, flag in ipairs(definition.flags or {}) do
        unique = unique or flag == flags.UNIQUE
        conjured = conjured or flag == flags.CONJURED
        stationary = stationary or flag == flags.STATIONARY
    end

    if conjured then
        return false
    end

    if unique or ctx:has(entity, component.BANISHMENT) then
        return true
    end

    return not stationary and
        (definition.hd or 0) > 8 + ctx:random(streams.ABYSS_TRANSIT, 25)
end

-- Parked actors occupy ordinary, distinct cells on the transit grid. This
-- leaves normal ECS position and save validation in charge of their bodies.
local function reserve_cell(ctx, occupied)
    for y = 1, abyss.HEIGHT - 2 do
        for x = 1, abyss.WIDTH - 2 do
            local key = x .. ":" .. y

            if not occupied[key] and
                not ctx:actor_at(abyss.TRANSIT_LEVEL_ID, x, y) then
                occupied[key] = true

                return x, y
            end
        end
    end

    error("Abyss transit storage is full")
end

-- Decide before the grid transaction, while the discarded actors still
-- have their old positions. The returned list is staged after replacement.
function transit.plan(ctx, actors, state)
    local parked = {}
    local discarded = {}
    local occupied = {}
    local records = {}

    for _, record in ipairs(state.transit or {}) do
        records[#records + 1] = record
    end

    for _, actor in ipairs(actors) do
        if should_keep(ctx, actor) then
            local x, y = reserve_cell(ctx, occupied)

            parked[#parked + 1] = { actor = actor, x = x, y = y }
            records[#records + 1] = {
                entity_id = ctx:id(actor),
                x = x,
                y = y,
            }
        else
            discarded[#discarded + 1] = actor
        end
    end

    state.transit = records

    return parked, discarded
end

-- The region command first removes each actor's old position. Attach its
-- new reserve position in the same action, before any policy can save it.
function transit.store(ctx, parked)
    for _, entry in ipairs(parked) do
        ctx:place_actor(entry.actor, abyss.TRANSIT_LEVEL_ID,
            entry.x, entry.y)
    end
end

-- Destroy ordinary discarded bodies and their separately owned gear.
-- Transit actors are absent from this list and retain their equipment.
function transit.retire(ctx, actors)
    local discarded = {}

    for _, actor in ipairs(actors) do
        discarded[actor] = true
    end

    for _, item in ipairs(ctx:query({ component.CARRIED_BY })) do
        local carried = ctx:get(item, component.CARRIED_BY)

        if discarded[carried.holder] then
            ctx:destroy(item)
        end
    end

    for _, actor in ipairs(actors) do
        ctx:destroy(actor)
    end
end

-- A source lost monster has a one-in-two chance to remain lost on each
-- fresh Abyss area. Successful arrivals use a distant empty floor cell;
-- a blocked candidate waits for the next region rather than disappearing.
function transit.release(ctx, state)
    local remaining = {}
    local arrived = 0

    for _, record in ipairs(state.transit or {}) do
        local actor = ctx:entity(record.entity_id)
        local placed = false

        if not actor then
            error("Abyss transit actor has no ECS body")
        end

        if ctx:random(streams.ABYSS_TRANSIT, 2) == 1 then
            local cells = {}

            for y = 1, abyss.HEIGHT - 2 do
                for x = 1, abyss.WIDTH - 2 do
                    local distance = math.max(
                        math.abs(x - abyss.CENTRE_X),
                        math.abs(y - abyss.CENTRE_Y))

                    if distance >= 5 and
                        ctx:cell(abyss.LEVEL_ID, x, y) ==
                            terrain.DNGN_FLOOR and
                        not ctx:actor_at(abyss.LEVEL_ID, x, y) then
                        cells[#cells + 1] = { x = x, y = y }
                    end
                end
            end

            if #cells > 0 then
                local cell = cells[ctx:random(streams.ABYSS_TRANSIT,
                    #cells) + 1]

                ctx:move_actor(actor, abyss.LEVEL_ID, cell.x, cell.y)
                placed = true
                arrived = arrived + 1
            end
        end

        if not placed then
            remaining[#remaining + 1] = record
        end
    end

    state.transit = remaining

    return arrived
end

return transit
