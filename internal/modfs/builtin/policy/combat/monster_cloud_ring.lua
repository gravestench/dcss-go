-- Theory of operation: an actor's saved Pan lord choice, source species
-- flag, or explicit modded ring ID selects one cloud kind. Spawning creates
-- the first field; each later action refreshes it after movement and combat.
-- The clouds are ordinary saved ECS entities with normal age and exposure.
local adjacent = require("constants.adjacent_cells")
local categories = require("constants.catalog")
local component = require("constants.component")
local catalog = require("policy.catalog")
local placement = require("policy.clouds.placement")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")
local rings = require("constants.monster_cloud_rings")

local ring = {}

-- Generated lords save a random ring on their actor. Other monsters use
-- immutable catalog data, so they need no duplicate component or reroll.
local function source_ring(ctx, monster)
    local lord = ctx:get(monster, component.PANDEMONIUM_LORD)

    if lord then
        return lord.ring_id
    end

    local actor = ctx:get(monster, component.ACTOR)

    if not actor then
        return nil
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    if definition.cloud_ring_id then
        return definition.cloud_ring_id
    end

    for _, flag in ipairs(definition.flags or {}) do
        local selected = rings.FOR_FLAG[flag]

        if selected then
            return selected
        end
    end

    return nil
end

-- A solid cell, an aligned monster, or a different cloud blocks this cloud.
-- Same-type clouds permit the source lifetime draw but cloud placement keeps
-- the existing entity and duration unchanged.
local function eligible(ctx, lord, kind_id, level_id, x, y)
    if not ctx:walkable(level_id, x, y) then
        return false
    end

    local _, existing = placement.at(ctx, level_id, x, y)

    if existing and existing.kind_id ~= kind_id then
        return false
    end

    local occupant = ctx:actor_at(level_id, x, y)

    return not occupant or not targets.aligned(ctx, lord, occupant)
end

-- Crawl deletes a matching cloud under the monster, then visits all eight
-- adjacent cells. It draws 2..7 turns only for eligible cells, even when an
-- existing same-type cloud subsequently declines replacement.
function ring.surround(ctx, monster)
    local ring_id = source_ring(ctx, monster)

    if not ring_id or ring_id == rings.NONE then
        return
    end

    local kind_id = rings.CLOUD_FOR_RING[ring_id]

    if not kind_id then
        error("monster has unknown cloud ring " .. ring_id)
    end

    local health = ctx:get(monster, component.HEALTH)
    local position = ctx:get(monster, component.POSITION)

    if not health or health.current <= 0 or not position then
        return
    end

    local overhead, current = placement.at(ctx,
        position.level_id, position.x, position.y)

    if current and current.kind_id == kind_id then
        placement.remove(ctx, overhead)
    end

    for _, offset in ipairs(adjacent) do
        local x = position.x + offset[1]
        local y = position.y + offset[2]

        if eligible(ctx, monster, kind_id, position.level_id, x, y) then
            local turns = 2 + ctx:random(streams.CLOUDS, 6)

            placement.place(ctx, kind_id, monster, position.level_id,
                x, y, turns * 10)
        end
    end
end

return ring
