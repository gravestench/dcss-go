-- Theory of operation: the Arena has four complete source DES enclosures.
-- A staged builder chooses one by stable vault ID, projects its terrain and
-- spectator records, then exposes the authored A, B, and < cells to travel.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local catalog = require("policy.catalog")
local features = require("content.terrain_features")
local grid = require("policy.generation.grid")
local levels = require("policy.generation.branch_levels")
local placement = require("policy.generation.vaults.placement")
local terrain = require("constants.terrain")
local vaults = require("policy.generation.vaults.catalog")

local level = {}

-- Resolve map-local special cells against the placed map's zero-based
-- origin. The B barrier stays a wall until the marked enemy finally dies.
local function sites(definition, bounds, cells)
    local found = {}

    for local_y, row in ipairs(definition.rows) do
        for local_x = 1, #row do
            local glyph = row:sub(local_x, local_x)

            if glyph == "A" or glyph == "B" or glyph == "<" then
                if found[glyph] then
                    error("Arena layout repeats a special cell")
                end

                found[glyph] = {
                    x = bounds.x + local_x - 1,
                    y = bounds.y + local_y - 1,
                }
            end
        end
    end

    local entry = found.A
    local barrier = found.B
    local exit = found["<"]

    if not entry or not barrier or not exit or
        cells[entry.y + 1][entry.x + 1] == terrain.DNGN_ROCK_WALL or
        cells[exit.y + 1][exit.x + 1] ~= terrain.DNGN_EXIT_ARENA or
        cells[barrier.y + 1][barrier.x + 1] ~=
            terrain.DNGN_CLEAR_PERMAROCK_WALL then
        error("Arena layout " .. definition.id ..
            " has invalid entry, barrier, or exit: " ..
            tostring(entry and cells[entry.y + 1][entry.x + 1]) .. "," ..
            tostring(barrier and cells[barrier.y + 1][barrier.x + 1]) ..
            "," .. tostring(exit and cells[exit.y + 1][exit.x + 1]))
    end

    -- Source B is a sealed wall one cell below the enemy's landing.
    local target = { x = barrier.x, y = barrier.y - 1 }

    if cells[target.y + 1][target.x + 1] ~= terrain.DNGN_FLOOR then
        error("Arena target landing is not open floor")
    end

    return entry, target, barrier, exit
end

-- An explicit ID serves layout snapshots and modded scenarios. Otherwise
-- a single builder draw chooses from IDs sorted independently of VFS order.
local function choose(builder, requested_id)
    vaults.load()

    local ids = {}

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local entry = register.get(categories.VAULTS, id)

        if entry.family == "arena" then
            ids[#ids + 1] = id
        end
    end

    table.sort(ids)

    if #ids == 0 then
        error("Arena has no DES layouts")
    end

    if requested_id then
        for _, id in ipairs(ids) do
            if id == requested_id then
                return vaults.get(id)
            end
        end

        error("requested Arena layout is unavailable")
    end

    return vaults.get(ids[builder:roll(#ids) + 1])
end

-- The generic portal stages this complete floor before the actor action;
-- generation rejection can therefore roll back without spending a turn.
function level.generate(ctx, input)
    local branch = catalog.get(categories.BRANCHES,
        branches.BRANCH_ARENA)
    local player = {
        branch_id = branches.BRANCH_ARENA,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = branch.absolute_depth,
        species_id = input.species_id,
        name = input.player_name,
    }
    local builder = grid.new(ctx)
    local definition = choose(builder, input.layout_id)
    local placed = placement.place(ctx, builder, definition,
        player, { whole_level = true })
    local cells = features.decode_source_rows(builder:rows())
    local records = features.apply_vault_terrain(cells,
        placed.records, ctx, 1)
    local entry, target, barrier, exit = sites(definition,
        placed.bounds, cells)

    return {
        portal_data = {
            target_x = target.x,
            target_y = target.y,
            barrier_x = barrier.x,
            barrier_y = barrier.y,
            exit_x = exit.x,
            exit_y = exit.y,
        },
        level = {
            id = levels.id(branches.BRANCH_ARENA, 1),
            branch_id = branches.BRANCH_ARENA,
            local_depth = 1,
            cells = cells,
            stairs = {},
            entry_x = entry.x,
            entry_y = entry.y,
            initial_monsters = 0,
            vault_id = definition.id,
            vault_ids = { definition.id },
            vault_records = records,
        },
    }
end

return level
