-- Theory of operation: the Abyss is one saved level whose visible window
-- follows the player. When the player nears an edge, this rule plans a new
-- procedural window with the player's old neighborhood at its center.
-- A vault touched by that neighborhood moves in full or the plan fails;
-- no source map is silently cut in half. Go validates the complete plan
-- and publishes it only at the Lua action barrier.
local abyss = require("constants.abyss")
local component = require("constants.component")
local terrain = require("constants.terrain")
local window = require("policy.generation.abyss.terrain")
local paths = require("policy.generation.abyss.paths")
local vaults = require("policy.generation.abyss.vaults")
local rune = require("policy.world.abyss.rune")
local population = require("policy.world.abyss.population")
local transit = require("policy.world.abyss.transit")
local streams = require("constants.rng_streams")
local behaviors = require("constants.ai_behaviors")
local transporter_links = require("policy.generation.transporters")
local transporter_ids = require("constants.transporter")
local transporters = require("policy.world.transporters")

local shift = {}

-- A string key keeps coordinate membership independent of Lua table
-- iteration order. Saved sample queues and vault records stay sorted.
local function key(x, y)
    return x .. ":" .. y
end

-- The source preserves a square of radius LOS+2. Clamp its source side
-- to the generated interior; the one-cell perimeter remains a wall.
local function player_mask(position)
    local mask = {}

    for y = math.max(1, position.y - abyss.SHIFT_RADIUS),
        math.min(abyss.HEIGHT - 2, position.y + abyss.SHIFT_RADIUS) do
        for x = math.max(1, position.x - abyss.SHIFT_RADIUS),
            math.min(abyss.WIDTH - 2, position.x + abyss.SHIFT_RADIUS) do
            mask[key(x, y)] = true
        end
    end

    return mask
end

-- Source vault cells carry the same authored map ID. If any cell of a
-- map lies in the player mask, preserve every recorded cell of that map.
-- This conservative rule also keeps repeated copies of one source ID
-- together until placement instance IDs become available.
local function expand_vaults(mask, records)
    local touched = {}

    for _, record in ipairs(records) do
        if not record.overridden and record.vault_id and
            mask[key(record.x, record.y)] then
            touched[record.vault_id] = true
        end
    end

    for _, record in ipairs(records) do
        if not record.overridden and touched[record.vault_id] then
            mask[key(record.x, record.y)] = true
        end
    end

    return touched
end

-- Preserved source cells must land inside the next window. Rejecting a
-- clipped vault is safer than publishing half of an authored structure.
local function translated(x, y, dx, dy)
    local next_x = x + dx
    local next_y = y + dy

    if next_x < 1 or next_y < 1 or
        next_x >= abyss.WIDTH - 1 or
        next_y >= abyss.HEIGHT - 1 then
        error("Abyss protected region crosses the next window boundary")
    end

    return next_x, next_y
end

-- Generation works in the next window's coordinates. Carry the player
-- preservation mask through the same translation as its terrain so a
-- fresh furniture or rune map cannot overwrite the new landing cell.
local function translated_mask(mask, dx, dy)
    local moved = {}

    for coordinate in pairs(mask) do
        local x, y = coordinate:match("^(%d+):(%d+)$")
        local next_x, next_y = translated(tonumber(x),
            tonumber(y), dx, dy)

        moved[key(next_x, next_y)] = true
    end

    return moved
end

-- New cells have no memory until they are explored. Source map memory
-- moves with the protected area instead of revealing fresh terrain.
local function blank_memory()
    local known = {}
    local seen = {}
    local detected = {}
    local creatures = {}

    for y = 1, abyss.HEIGHT do
        known[y] = {}
        seen[y] = {}
        detected[y] = {}
        creatures[y] = {}

        for x = 1, abyss.WIDTH do
            known[y][x] = terrain.DNGN_UNSEEN
            seen[y][x] = false
            detected[y][x] = false
            creatures[y][x] = ""
        end
    end

    return known, seen, detected, creatures
end

-- Sample a complete next window, then overlay only the old protected
-- cells. This keeps the world-coordinate terrain continuous at its edge.
local function move_cells(ctx, state, plan, mask, dx, dy)
    local generated, updated = window.build(ctx, state)
    local known, seen, detected, creatures = blank_memory()

    for y = 1, abyss.HEIGHT - 2 do
        for x = 1, abyss.WIDTH - 2 do
            if mask[key(x, y)] then
                local next_x, next_y = translated(x, y, dx, dy)

                generated[next_y + 1][next_x + 1] =
                    plan.cells[y + 1][x + 1]
                known[next_y + 1][next_x + 1] =
                    plan.known[y + 1][x + 1]
                seen[next_y + 1][next_x + 1] =
                    plan.seen[y + 1][x + 1]
                detected[next_y + 1][next_x + 1] =
                    plan.detected_items[y + 1][x + 1]
                creatures[next_y + 1][next_x + 1] =
                    plan.detected_creatures[y + 1][x + 1]
            end
        end
    end

    plan.cells = generated
    plan.known = known
    plan.seen = seen
    plan.detected_items = detected
    plan.detected_creatures = creatures

    return updated
end

-- Keep source record indices stable across shifts. A discarded record
-- becomes an inert tombstone: carried items and other live entities can
-- still prove their provenance after its map leaves the current window.
-- Active records move with their terrain and retain the same array slot.
local function move_records(records, mask, dx, dy)
    local moved = {}

    for _, record in ipairs(records) do
        local copy = {}

        for name, value in pairs(record) do
            copy[name] = value
        end

        if not record.overridden and mask[key(record.x, record.y)] then
            local next_x, next_y = translated(record.x,
                record.y, dx, dy)

            copy.x = next_x
            copy.y = next_y
        else
            copy.overridden = true
            copy.pending = false
        end

        moved[#moved + 1] = copy
    end

    return moved
end

-- Only previously learned pairs whose whole vault moved may remain known.
-- The newly resolved record supplies the destination in the new frame;
-- dropped vaults and newly placed pairs cannot inherit stale knowledge.
local function moved_transporter_knowledge(records, mask, dx, dy)
    local remaps = {}

    for _, record in ipairs(records) do
        local kind = transporter_links.parse(record.identity or "")
        local old_x = record.x - dx
        local old_y = record.y - dy

        if not record.overridden and
            kind == transporter_ids.SOURCE_CALL and
            mask[key(old_x, old_y)] then
            local arguments = record.arguments or {}
            local old_key = abyss.LEVEL_ID .. ":" ..
                old_x .. ":" .. old_y

            remaps[old_key] = {
                key = abyss.LEVEL_ID .. ":" ..
                    record.x .. ":" .. record.y,
                destination = arguments[transporter_ids.DESTINATION_X] ..
                    ":" .. arguments[transporter_ids.DESTINATION_Y],
            }
        end
    end

    return remaps
end

-- An origin points to an authored record, not to the entity's current
-- cell. Shift its recorded source coordinate only when that record stays
-- active; tombstoned records keep their old location for carried gear.
local function move_origins(ctx, records, mask, dx, dy)
    for _, entity in ipairs(ctx:query({ component.VAULT_ORIGIN })) do
        local origin = ctx:get(entity, component.VAULT_ORIGIN)
        local record = records[origin.record_index]

        if origin.level_id == abyss.LEVEL_ID and record and
            not record.overridden and
            mask[key(origin.spawn_x, origin.spawn_y)] then
            origin.spawn_x, origin.spawn_y = translated(
                origin.spawn_x, origin.spawn_y, dx, dy)
            ctx:set(entity, component.VAULT_ORIGIN, origin)
        end
    end
end

-- Fog machines have their own coordinates rather than core.position.
-- Their chained marker indices stay stable because the record array
-- retains tombstones. A machine whose source marker was erased retires.
local function move_fog_machines(ctx, mask, dx, dy)
    for _, entity in ipairs(ctx:query({ component.FOG_MACHINE })) do
        local fields = ctx:get(entity, component.FOG_MACHINE)

        if fields.level_id == abyss.LEVEL_ID then
            if mask[key(fields.x, fields.y)] then
                fields.x, fields.y = translated(fields.x,
                    fields.y, dx, dy)

                for index = 1, #fields.positions_x do
                    fields.positions_x[index], fields.positions_y[index] =
                        translated(fields.positions_x[index],
                            fields.positions_y[index], dx, dy)
                end

                ctx:set(entity, component.FOG_MACHINE, fields)
            else
                ctx:destroy(entity)
            end
        end
    end
end

-- A surviving monster's remembered target is also a map coordinate.
-- Carry a target inside the protected area to the new frame; otherwise
-- clear the pursuit so it cannot point into unrelated fresh terrain.
local function move_actor_targets(ctx, moves, mask, dx, dy)
    for _, move in ipairs(moves) do
        local ai = ctx:get(move.actor, component.AI)

        if ai and (ai.target_x ~= 0 or ai.target_y ~= 0) then
            if mask[key(ai.target_x, ai.target_y)] then
                ai.target_x, ai.target_y = translated(
                    ai.target_x, ai.target_y, dx, dy)

                if not ctx:walkable(abyss.LEVEL_ID,
                    ai.target_x, ai.target_y) then
                    ai.target_x = 0
                    ai.target_y = 0
                    ai.memory_until_aut = 0
                    ai.behavior = behaviors.WANDER
                end
            else
                ai.target_x = 0
                ai.target_y = 0
                ai.memory_until_aut = 0
                ai.behavior = behaviors.WANDER
            end

            ctx:set(move.actor, component.AI, ai)
        end
    end
end

-- Stairs, colours, and spawn exclusions all use level-local cells.
-- Their other fields are kept verbatim for the host's typed validator.
local function move_points(points, mask, dx, dy)
    local moved = {}

    for _, point in ipairs(points) do
        if mask[key(point.x, point.y)] then
            local next_x, next_y = translated(point.x,
                point.y, dx, dy)
            local copy = {}

            for name, value in pairs(point) do
                copy[name] = value
            end

            copy.x = next_x
            copy.y = next_y
            moved[#moved + 1] = copy
        end
    end

    return moved
end

-- Fresh edge cells get new procedural change points. A preserved cell
-- keeps its prior point and feature so shifting does not restart its
-- morph clock or let a vault cell reappear as a different texture.
local function move_queue(prior, updated, mask, dx, dy)
    local old = {}

    for _, sample in ipairs(prior.sample_queue or {}) do
        old[key(sample.x, sample.y)] = sample
    end

    for _, sample in ipairs(updated.sample_queue) do
        local source_x = sample.x - dx
        local source_y = sample.y - dy

        if mask[key(source_x, source_y)] then
            local saved = old[key(source_x, source_y)]

            if saved then
                sample.change = saved.change
                sample.feature = saved.feature
            end
        end
    end

    table.sort(updated.sample_queue, function(left, right)
        if left.change ~= right.change then
            return left.change < right.change
        end

        if left.y ~= right.y then
            return left.y < right.y
        end

        return left.x < right.x
    end)
end

-- Every positioned actor on the old Abyss level either moves with the
-- protected cells or retires from this window. Lua's follow-up stage
-- decides whether a retired actor becomes transit or is destroyed.
local function move_actors(ctx, plan, mask, dx, dy)
    local moves = {}
    local retired = {}

    for _, actor in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
    })) do
        local position = ctx:get(actor, component.POSITION)

        if position.level_id == abyss.LEVEL_ID then
            if mask[key(position.x, position.y)] then
                local x, y = translated(position.x,
                    position.y, dx, dy)

                moves[#moves + 1] = {
                    actor = actor,
                    level_id = abyss.LEVEL_ID,
                    x = x,
                    y = y,
                }
            else
                retired[#retired + 1] = actor
            end
        end
    end

    plan.actor_moves = moves
    plan.actor_retire = retired
end

-- Plan without touching the live level or the caller's procedural state.
-- On success, the caller stages plan and updated state as one action.
function shift.plan(ctx, state, player)
    local position = ctx:get(player, component.POSITION)

    if not position or position.level_id ~= abyss.LEVEL_ID then
        error("Abyss shift requires a player on the Abyss level")
    end

    local dx = abyss.CENTRE_X - position.x
    local dy = abyss.CENTRE_Y - position.y
    local plan = ctx:region_plan(abyss.LEVEL_ID)

    if dx == 0 and dy == 0 then
        return plan, state, nil, 0, 0
    end

    local mask = player_mask(position)
    local touched = expand_vaults(mask, plan.vault_records)
    local next_state = {}

    for name, value in pairs(state) do
        next_state[name] = value
    end

    next_state.world_x = state.world_x - dx
    next_state.world_y = state.world_y - dy
    next_state.shift_count = state.shift_count + 1

    local updated = move_cells(ctx, next_state, plan, mask, dx, dy)

    move_queue(state, updated, mask, dx, dy)

    local new_cells
    local new_records
    local new_ids
    local protected

    new_cells, new_records, new_ids, protected = vaults.fill(ctx,
        plan.cells, updated, translated_mask(mask, dx, dy))
    plan.cells = new_cells

    local path_records
    local path_ids

    plan.cells, path_records, path_ids, protected = paths.place(ctx,
        plan.cells, updated, protected)

    local prior_vault_ids = plan.vault_ids

    plan.vault_records = move_records(plan.vault_records,
        mask, dx, dy)

    for _, record in ipairs(new_records) do
        plan.vault_records[#plan.vault_records + 1] = record
    end

    for _, record in ipairs(path_records) do
        plan.vault_records[#plan.vault_records + 1] = record
    end

    -- A retained pair moves with its vault; new tagged maps can also add
    -- pairs. Recompute source coordinates after both record sets are final.
    transporter_links.resolve(plan)

    plan.stairs = move_points(plan.stairs, mask, dx, dy)
    plan.cell_colours = move_points(plan.cell_colours,
        mask, dx, dy)
    plan.spawn_exclusions = move_points(plan.spawn_exclusions,
        mask, dx, dy)
    plan.vault_ids = {}

    for _, id in ipairs(prior_vault_ids or {}) do
        if touched[id] then
            plan.vault_ids[#plan.vault_ids + 1] = id
        end
    end

    for _, id in ipairs(new_ids) do
        plan.vault_ids[#plan.vault_ids + 1] = id
    end

    for _, id in ipairs(path_ids) do
        plan.vault_ids[#plan.vault_ids + 1] = id
    end

    updated.selected_map_ids = plan.vault_ids
    move_actors(ctx, plan, mask, dx, dy)

    return plan, updated, mask, dx, dy, protected
end

-- Items and other positioned, nonactor entities are not in the level's
-- actor occupancy index. Move their ECS positions after the region has
-- been staged, or retire them when their old cell was erased.
local function move_positioned_objects(ctx, mask, dx, dy)
    for _, entity in ipairs(ctx:query({ component.POSITION })) do
        if not ctx:has(entity, component.ACTOR) then
            local position = ctx:get(entity, component.POSITION)

            if position and position.level_id == abyss.LEVEL_ID then
                if mask[key(position.x, position.y)] then
                    local x, y = translated(position.x,
                        position.y, dx, dy)

                    ctx:set(entity, component.POSITION, {
                        level_id = abyss.LEVEL_ID,
                        x = x,
                        y = y,
                    })
                else
                    ctx:destroy(entity)
                end
            end
        end
    end
end

-- Clouds own coordinates in their Lua component rather than core.position.
-- Copy every other field, including damage credit and opacity, unchanged.
local function move_clouds(ctx, mask, dx, dy)
    for _, cloud in ipairs(ctx:query({ component.WORLD_CLOUD })) do
        local fields = ctx:get(cloud, component.WORLD_CLOUD)

        if fields.level_id == abyss.LEVEL_ID then
            if mask[key(fields.x, fields.y)] then
                local x, y = translated(fields.x, fields.y,
                    dx, dy)

                fields.x = x
                fields.y = y
                ctx:set(cloud, component.WORLD_CLOUD, fields)
            else
                ctx:destroy(cloud)
            end
        end
    end
end

-- The complete region must be staged before ordinary ECS edits so the
-- host's rollback order restores old coordinates after any later error.
-- Transit classification happens before replacement while actor positions
-- still describe the old window; the reserve positions stage afterward.
function shift.apply(ctx, state, player)
    local plan, updated, mask, dx, dy, protected = shift.plan(ctx,
        state, player)

    if not mask then
        return state
    end

    local rune_cell = rune.plan(ctx, plan, updated,
        protected, mask)

    -- The source adds fifteen monsters plus one or two per branch depth
    -- after every window shift. This budget belongs to this new area.
    plan.initial_monsters = abyss.SHIFT_MONSTERS_BASE +
        updated.branch_depth *
        (1 + ctx:random(streams.POPULATION_COUNT, 2))
    local parked, discarded = transit.plan(ctx,
        plan.actor_retire, updated)

    ctx:replace_region(abyss.LEVEL_ID, plan)
    transporters.remap_knowledge(ctx, player, abyss.LEVEL_ID,
        moved_transporter_knowledge(plan.vault_records, mask, dx, dy))
    transit.store(ctx, parked)
    move_actor_targets(ctx, plan.actor_moves, mask, dx, dy)
    move_origins(ctx, plan.vault_records, mask, dx, dy)
    move_fog_machines(ctx, mask, dx, dy)
    move_positioned_objects(ctx, mask, dx, dy)
    move_clouds(ctx, mask, dx, dy)

    transit.retire(ctx, discarded)

    -- New-edge rune items did not exist in the old window and must not
    -- enter the survivor/retirement sweep above.
    rune.spawn(ctx, rune_cell)
    population.materialize(ctx, plan)
    transit.release(ctx, updated)

    return updated
end

return shift
