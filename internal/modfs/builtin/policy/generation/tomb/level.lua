-- Tomb is one three-floor authored route. Build and resolve it as a single
-- Lua result so named landings are concrete before the first player move.
local branches = require("ids.branches")
local effects = require("constants.vault_effects")
local features = require("content.terrain_features")
local grid = require("policy.generation.grid")
local hatches = require("policy.generation.tomb.hatches")
local levels = require("policy.generation.branch_levels")
local monster_budget = require("policy.generation.monster_budget")
local placement = require("policy.generation.vaults.placement")
local vaults = require("policy.generation.vaults.catalog")
local maps = require("ids.tomb_maps")

local tomb = {}

local source_maps = {
    maps.FIRST,
    maps.SECOND,
    maps.THIRD,
}

-- One builder-owned counter balances the three active guardian pools across
-- the source's parent maps and selected helpers, then disappears.
local function player_context(depth, guardian_counts)
    return {
        branch_id = branches.BRANCH_TOMB,
        depth = depth,
        branch_bottom = 3,
        absolute_depth = 20 + depth,
        settings = {
            guardian_counts = guardian_counts,
        },
    }
end

-- The selected source MAP and its nested helper maps produce one immutable
-- floor record. Each floor keeps its full vault history for save/replay.
local function build_floor(ctx, depth, guardian_counts)
    local id = source_maps[depth]
    local builder = grid.new(ctx)
    local selected = vaults.get(id)
    local placed = placement.place(nil, builder, selected,
        player_context(depth, guardian_counts))
    local cells = features.decode_source_rows(builder:rows())
    local records = features.apply_vault_terrain(cells,
        placed.records, ctx, depth)
    local vault_ids = { id }

    for _, helper_id in ipairs(placed.vault_ids) do
        vault_ids[#vault_ids + 1] = helper_id
    end

    return {
        id = levels.id(branches.BRANCH_TOMB, depth),
        branch_id = branches.BRANCH_TOMB,
        local_depth = depth,
        cells = cells,
        stairs = {},
        entry_x = 0,
        entry_y = 0,
        initial_monsters = monster_budget.roll(ctx,
            branches.BRANCH_TOMB, depth),
        vault_id = id,
        vault_ids = vault_ids,
        vault_records = records,
        source_exits = placed.exits,
    }
end

-- Tomb:1 has one source stone stair back to the Crypt gate. It is also
-- where a player entering Tomb lands; no ordinary stair completion runs.
local function parent_exit(first, parent, from_x, from_y)
    local found

    for _, exit in ipairs(first.source_exits) do
        if exit.source == "(" then
            if found then
                error("Tomb:1 has multiple Crypt return stairs")
            end

            found = exit
        end
    end

    if not found then
        error("Tomb:1 has no Crypt return stair")
    end

    first.stairs[#first.stairs + 1] = {
        x = found.x,
        y = found.y,
        to_level_id = parent.id,
        to_x = from_x,
        to_y = from_y,
        unavailable = "",
    }
    first.entry_x = found.x
    first.entry_y = found.y

    return found
end

-- The destination of each floor's first named downward hatch is a safe
-- population anchor. Only the first floor's entry is used for this move.
local function set_later_entries(floors)
    for index = 2, #floors do
        local floor = floors[index]
        local found

        for _, record in ipairs(floor.vault_records) do
            local arguments = record.arguments or {}

            if record.kind == effects.MARKER and
                arguments.hatch_kind == "dest" then
                found = record
                break
            end
        end

        if not found then
            error("Tomb:" .. index .. " has no arrival marker")
        end

        floor.entry_x = found.x
        floor.entry_y = found.y
    end
end

-- Return the same transaction shape used by ordinary next-floor policy,
-- except that `levels` holds every newly connected Tomb floor.
function tomb.generate(ctx, input)
    if input.branch_id ~= branches.BRANCH_TOMB or
        input.local_depth ~= 1 or
        input.level_id ~= levels.id(branches.BRANCH_TOMB, 1) then
        error("Tomb bundle requires its first scheduled floor")
    end

    local guardian_counts = {
        0,
        0,
        0,
    }
    local floors = {}

    for depth = 1, 3 do
        floors[depth] = build_floor(ctx, depth, guardian_counts)
    end

    local entry = parent_exit(floors[1], input.parent,
        input.from_x, input.from_y)

    hatches.resolve(floors)
    set_later_entries(floors)

    for _, floor in ipairs(floors) do
        floor.source_exits = nil
    end

    return {
        levels = floors,
        parent_links = {
            {
                x = input.from_x,
                y = input.from_y,
                to_x = entry.x,
                to_y = entry.y,
                new = false,
            },
        },
        entry = {
            x = entry.x,
            y = entry.y,
        },
        starting_items = {},
    }
end

return tomb
