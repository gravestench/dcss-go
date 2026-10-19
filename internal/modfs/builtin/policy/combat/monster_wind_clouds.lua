-- Wind Blast advects existing cloud entities; it never recreates them.
-- Their decay, source credit, and special state therefore survive a push.
local component = require("constants.component")
local geometry = require("policy.combat.monster_wind_geometry")
local placement = require("policy.clouds.placement")

local clouds = {}

-- Gather before moving any cloud so one cloud cannot be pushed twice by
-- the same blast. Farthest clouds move first and free space for nearer ones.
local function candidates(ctx, source, aim, radius)
    local selected = {}

    for _, entity in ipairs(ctx:query({ component.WORLD_CLOUD })) do
        local state = ctx:get(entity, component.WORLD_CLOUD)
        local distance = geometry.distance(source, state)

        if state.level_id == source.level_id and
            distance <= radius + 2 and
            geometry.in_cone(source, aim, state) and
            geometry.visible_solid(ctx, source, state) then
            selected[#selected + 1] = {
                entity = entity,
                distance = distance,
            }
        end
    end

    table.sort(selected, function(first, second)
        if first.distance ~= second.distance then
            return first.distance > second.distance
        end

        return ctx:id(first.entity) < ctx:id(second.entity)
    end)

    return selected
end

-- A cloud can cross occupied actor cells, but not solid cells or another
-- cloud. Actor and cloud occupancy are intentionally independent.
local function can_enter(ctx, level_id, cell)
    return ctx:walkable(level_id, cell.x, cell.y) and
        not placement.at(ctx, level_id, cell.x, cell.y)
end

-- Near clouds travel four steps; those farther out travel three or two.
-- An obstruction can bend the flow into a same-radius adjacent cell.
local function push_one(ctx, source, candidate)
    local state = ctx:get(candidate.entity, component.WORLD_CLOUD)
    local distance = geometry.distance(source, state)
    local remaining = distance > 5 and 2 or distance > 2 and 3 or 4

    while remaining > 0 do
        local next_cell = geometry.next_cell(ctx, source, state)

        if not next_cell then
            break
        end

        local destination = next_cell

        if not can_enter(ctx, state.level_id, destination) then
            destination = nil

            for _, cell in ipairs(geometry.alternates(source,
                state, next_cell, state)) do
                if can_enter(ctx, state.level_id, cell) then
                    destination = cell

                    break
                end
            end
        end

        if not destination then
            break
        end

        state.x = destination.x
        state.y = destination.y
        ctx:set(candidate.entity, component.WORLD_CLOUD, state)
        remaining = remaining - 1
    end
end

-- Run the source cloud pass after actors have settled, before collision
-- damage or traps can disperse and rearrange those actors.
function clouds.push(ctx, source, aim, radius)
    for _, candidate in ipairs(candidates(ctx, source,
        aim, radius)) do
        push_one(ctx, source, candidate)
    end
end

return clouds
