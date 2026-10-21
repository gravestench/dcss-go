-- Theory of operation: a generated Pan lord's saved ring ID projects one
-- source cloud kind around its current cell. The ring does not own a second
-- timer: spawning the lord creates its first field, and each later monster
-- action refreshes the field after movement and combat. Existing clouds
-- remain normal saved ECS entities with ordinary age and exposure rules.
local adjacent = require("constants.adjacent_cells")
local component = require("constants.component")
local placement = require("policy.clouds.placement")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")
local traits = require("constants.pan_lord_traits")

local ring = {}

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
function ring.surround(ctx, lord)
    local state = ctx:get(lord, component.PANDEMONIUM_LORD)

    if not state then
        return
    end

    local kind_id = traits.cloud_for_ring[state.ring_id]

    if not kind_id then
        return
    end

    local health = ctx:get(lord, component.HEALTH)
    local position = ctx:get(lord, component.POSITION)

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

        if eligible(ctx, lord, kind_id, position.level_id, x, y) then
            local turns = 2 + ctx:random(streams.CLOUDS, 6)

            placement.place(ctx, kind_id, lord, position.level_id,
                x, y, turns * 10)
        end
    end
end

return ring
