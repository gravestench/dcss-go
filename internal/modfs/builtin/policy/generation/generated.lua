-- Example: authored stairs on any Dungeon floor gain paired landings nearby.
local grid = require("policy.generation.grid")
local layouts = require("policy.generation.layouts.catalog")
local item_ids = require("ids.items")
local nearest = require("policy.generation.nearest")
local branches = require("ids.branches")
local live_stairs = require("policy.generation.generated_stairs")
local vault_catalog = require("policy.generation.vaults.catalog")
local vault_selection = require("policy.generation.vaults.selection")
local vault_placement = require("policy.generation.vaults.placement")
local vault_connect = require("policy.generation.vaults.connect")
local vault_glyphs = require("constants.vault_glyphs")
local vault_effects = require("constants.vault_effects")
local vault_extra = require("policy.generation.vaults.extra")
local branch_schedule = require("policy.generation.branch_schedule")

local generated = {}

local entrance_directions = {
    { x = 1, y = 0 },
    { x = -1, y = 0 },
    { x = 0, y = 1 },
    { x = 0, y = -1 },
}

-- Each floor draws three population dice from its own depth-specific die size.
local function monster_count(ctx, depth)
    local die_size = depth == 1 and 12 or 10
    local count = 0

    for _ = 1, 3 do
        count = count + ctx:random("population-count", die_size) + 1
    end

    return count
end

-- Separate authored up and down exits before destination landings are paired.
local function source_stairs(placed)
    local up = {}
    local down = {}

    for _, exit in ipairs(placed.exits) do
        if vault_glyphs.up[exit.source] then
            up[#up + 1] = exit
        elseif vault_glyphs.down[exit.source] then
            down[#down + 1] = exit
        end
    end

    return up, down
end

-- Keep every authored exit alongside ordinary stairs so live pairing can
-- connect it when this floor becomes the parent or child of another floor.
local function add_source_stairs(placed, up, down)
    local source_up, source_down = source_stairs(placed)

    for _, point in ipairs(source_up) do
        up[#up + 1] = point
    end

    for _, point in ipairs(source_down) do
        down[#down + 1] = point
    end
end

-- Use the selected layout's declared family for every nested vault
-- selector. Arrival helpers and later secondary maps share this rule.
local function layout_family(layout)
    local definition = layouts.get(layout.id)

    for tag in pairs(definition.tags) do
        local family = tag:match("^layout_type_(.+)$")

        if family then
            return family
        end
    end

    error("layout " .. layout.id .. " has no layout_type tag")
end

-- Fixed-orientation arrivals can collide with already generated stairs.
-- Only that placement conflict gets a new base layout; other errors reveal
-- a broken map or rule and should fail immediately.
-- Arrival placement precedes ordinary population so its stairs and protected cells shape D:1.
local function place_first_level(ctx, player)
    local random = grid.new(ctx)
    local selected = vault_selection.choose_catalog(random)
    local vault = vault_catalog.get(selected.id)
    local bottom = register.get("branches", branches.BRANCH_DUNGEON).depth

    for _ = 1, 32 do
        local definition = layouts.choose(random,
            branches.BRANCH_DUNGEON, 1, bottom, vault.tags)
        local first = layouts.execute(ctx, definition,
            branches.BRANCH_DUNGEON, 1)
        local placement_player = {
            species_id = player.species_id,
            name = player.name,
            started = player.started,
            branch_id = branches.BRANCH_DUNGEON,
            depth = 1,
            branch_bottom = bottom,
            absolute_depth = 1,
            layout_family = layout_family(first),
        }
        local ok, placed = pcall(vault_placement.place, ctx,
            first.builder, vault, placement_player)

        if ok then
            return first, placed, vault
        end

        if not tostring(placed):find("fixed orientation conflicts with an existing stair", 1, true) then
            error(placed)
        end
    end

    error("Dungeon:1 could not fit a fixed-orientation arrival after 32 layouts")
end

-- A no-monster-generation tag masks the authored occupied cells, not the entire Dungeon.
local function spawn_exclusions(placed, vault)
    local excluded = {}
    local points = {}

    -- Deduplicate exclusion points by cell before returning spawn masks.
    local function add(x, y)
        local key = x .. ":" .. y

        if not excluded[key] then
            excluded[key] = true
            points[#points + 1] = {
                x = x,
                y = y,
            }
        end
    end

    if vault.tags.no_monster_gen then
        for _, point in ipairs(placed.occupied) do
            add(point.x, point.y)
        end
    end

    for _, record in ipairs(placed.records) do
        if record.kind == vault_effects.MASK and
            record.identity:find("no_monster_gen", 1, true) then
            add(record.x, record.y)
        end
    end

    return points
end

generated.spawn_exclusions = spawn_exclusions

-- Protect arrival occupancy and all stairs before attempting extra vault fits.
local function protected_cells(level, placed)
    local cells = {}

    for _, point in ipairs(placed and placed.occupied or {}) do
        vault_extra.protect(cells, point)
    end

    for _, pair in ipairs(level.stairs) do
        vault_extra.protect(cells, pair.up)
        vault_extra.protect(cells, pair.down)
    end

    if placed then
        vault_extra.protect(cells, placed.entry)
    end

    return cells
end

-- Keep each extra map's typed records in its placement order for population.
local function append_vault_records(target, maps)
    for _, map in ipairs(maps) do
        for _, record in ipairs(map.records) do
            target[#target + 1] = record
        end
    end
end

-- Merge arrival and extra-vault masks so ordinary spawning respects every map.
local function extra_exclusions(base, maps)
    local points = {}

    for _, point in ipairs(base or {}) do
        points[#points + 1] = point
    end

    for _, map in ipairs(maps) do
        local vault = vault_catalog.get(map.id)

        for _, point in ipairs(spawn_exclusions(map, vault)) do
            points[#points + 1] = point
        end
    end

    return points
end

-- Keep base stairs as required points while an arrival vault connects.
local function base_stair_points(layout)
    local points = {}

    for _, pair in ipairs(layout.stairs) do
        points[#points + 1] = pair.up
        points[#points + 1] = pair.down
    end

    return points
end

-- Find connected floor away from the arrival and existing stairs. The
-- chosen cell is marked before extra vaults run so no later map can cover
-- the branch entrance or replace its saved source feature identity.
local function entrance_cell(builder, start, protected)
    local queue = { start }
    local seen = { [start.x .. ":" .. start.y] = true }
    local cursor = 1

    while cursor <= #queue do
        local point = queue[cursor]
        local key = point.x .. ":" .. point.y
        local distance = math.max(math.abs(point.x - start.x),
            math.abs(point.y - start.y))

        cursor = cursor + 1

        if distance >= 5 and builder:cell(point.x, point.y) == "." and
            not protected[key] then
            return point
        end

        for _, direction in ipairs(entrance_directions) do
            local x = point.x + direction.x
            local y = point.y + direction.y
            local neighbor = x .. ":" .. y
            local glyph = x >= 1 and x < 79 and y >= 1 and y < 69 and
                builder:cell(x, y)

            if glyph and glyph ~= "#" and not seen[neighbor] then
                seen[neighbor] = true
                queue[#queue + 1] = { x = x, y = y }
            end
        end
    end

    error("generated floor has no connected branch entrance cell")
end

-- Store source identity on the link while the grid uses the kernel's
-- ordinary linked-stair feature. Travel becomes available with the shared
-- branch installer; until then the player gets a named unavailable reason.
local function place_branch_entrances(builder, layout, protected,
    chosen, depth)
    local links = {}
    local entries = branch_schedule.entries(chosen,
        branches.BRANCH_DUNGEON, depth)
    local start = layout.stairs[1].up

    for _, entry in ipairs(entries) do
        local point = entrance_cell(builder, start, protected)
        local branch = register.get("branches", entry.branch_id)

        builder:set(point.x, point.y, ">")
        vault_extra.protect(protected, point)
        links[#links + 1] = {
            x = point.x,
            y = point.y,
            to_level_id = 0,
            to_x = 0,
            to_y = 0,
            unavailable = "The entrance to " .. branch.long_name ..
                " cannot be entered yet.",
            target_branch_id = entry.branch_id,
            source_feature = entry.entry_feature,
        }
    end

    return links
end

-- Generate one floor before pairing its stairs with neighboring floors.
-- The arrival only belongs to D:1; supplemental vaults use actual depth.
local function build_floor(ctx, player, depth, bottom, prior_vault_ids,
    chosen_schedule)
    local layout
    local arrival
    local arrival_vault

    if depth == 1 then
        layout, arrival, arrival_vault = place_first_level(ctx, player)
    else
        local random = grid.new(ctx)
        local definition = layouts.choose(random,
            branches.BRANCH_DUNGEON, depth, bottom)

        layout = layouts.execute(ctx, definition,
            branches.BRANCH_DUNGEON, depth)
    end

    local required = base_stair_points(layout)

    if arrival then
        vault_connect.finish(ctx, layout.builder, arrival, required)
    end

    local protected = protected_cells(layout, arrival)
    local branch_links = place_branch_entrances(layout.builder,
        layout, protected, chosen_schedule, depth)
    local extra, controller, extra_ids = vault_extra.generate(
        ctx,
        layout.builder,
        {
            branch_id = branches.BRANCH_DUNGEON,
            depth = depth,
            branch_bottom = bottom,
            absolute_depth = depth,
            layout_family = layout_family(layout),
            prior_vault_ids = prior_vault_ids,
            arrival_vault = arrival_vault,
            protected = protected,
            required = required,
            player = {
                species_id = player.species_id,
                name = player.name,
                started = player.started or false,
                branch_id = branches.BRANCH_DUNGEON,
                depth = depth,
                branch_bottom = bottom,
                absolute_depth = depth,
                layout_family = layout_family(layout),
            },
        }
    )

    local records = {}
    local source_up = {}
    local source_down = {}

    if layout.records then
        append_vault_records(records, { layout })
    end

    if arrival then
        append_vault_records(records, { arrival })
        add_source_stairs(arrival, source_up, source_down)
    end

    append_vault_records(records, extra)

    for _, map in ipairs(extra) do
        add_source_stairs(map, source_up, source_down)
    end

    return {
        depth = depth,
        layout = layout,
        arrival = arrival,
        arrival_vault = arrival_vault,
        extra = extra,
        controller = controller,
        vault_ids = extra_ids,
        records = records,
        protected = protected,
        source_up = source_up,
        source_down = source_down,
        links = branch_links,
    }
end

-- An arrival's authored entry wins over the first ordinary up stair.
local function floor_entry(floor)
    local entry = floor.layout.stairs[1].up

    if floor.arrival then
        for _, exit in ipairs(floor.arrival.exits) do
            if exit.source == "{" then
                return exit
            end
        end
    end

    return entry
end

-- Project the finished builder, links, population budget, and vault intent
-- into the level record that the Go world materializes and saves.
local function level_record(ctx, floor, depth)
    local arrival = floor.arrival
    local entry = floor_entry(floor)
    local base_exclusions

    if arrival then
        base_exclusions = spawn_exclusions(arrival, floor.arrival_vault)
    end

    return {
        id = depth,
        branch_id = branches.BRANCH_DUNGEON,
        rows = floor.layout.builder:rows(),
        stairs = floor.links,
        entry_x = entry.x,
        entry_y = entry.y,
        initial_monsters = monster_count(ctx, depth),
        vault_id = arrival and arrival.id or floor.controller,
        vault_ids = floor.vault_ids,
        vault_records = #floor.records > 0 and floor.records or nil,
        spawn_exclusions = extra_exclusions(base_exclusions, floor.extra),
    }
end

-- Carry item identities from Lua generation to Lua population. Go forwards
-- these intents without knowing which potion belongs on which floor.
local function starting_item(kind_id, level_id, cell)
    return {
        kind_id = kind_id,
        level_id = level_id,
        x = cell.x,
        y = cell.y,
    }
end

-- Build only the floor visible at launch. Its down links name D:2 without
-- preselecting D:2 terrain, vaults, monster budget, or destination cells.
function generated.first(ctx, input)
    local schedule = branch_schedule.choose(ctx)
    local bottom = register.get("branches", branches.BRANCH_DUNGEON).depth
    local player = {
        species_id = input.player_species_id,
        name = input.player_name,
        started = false,
    }
    local floor = build_floor(ctx, player, 1, bottom, {}, schedule)

    live_stairs.first(floor)

    local level = level_record(ctx, floor, 1)
    local entry = floor_entry(floor)
    local curing = nearest.open_floor(level.rows, entry, nil, 1)

    return {
        levels = { level },
        branch_schedule = schedule,
        entry = {
            x = entry.x,
            y = entry.y,
        },
        starting_items = {
            starting_item(item_ids.POT_CURING, 1, curing),
        },
    }
end

-- The current parent grid determines safe extra departures. All new-floor
-- layout and vault draws happen after the player's previous actions.
function generated.next(ctx, input)
    branch_schedule.validate(input.branch_schedule)
    local bottom = register.get("branches", branches.BRANCH_DUNGEON).depth
    local depth = input.depth
    local parent = input.parent

    if depth < 2 or depth > bottom or parent.id ~= depth - 1 then
        error("next Dungeon floor needs its contiguous parent")
    end

    local player = {
        species_id = input.player_species_id,
        name = input.player_name,
        started = true,
    }
    local floor = build_floor(ctx, player, depth, bottom,
        input.prior_vault_ids, input.branch_schedule)
    local patches, entry = live_stairs.pair(ctx, parent, floor, {
        x = input.from_x,
        y = input.from_y,
    })
    local level = level_record(ctx, floor, depth)
    local items = {}

    level.entry_x = entry.x
    level.entry_y = entry.y

    if depth == 2 then
        local base_entry = floor_entry(floor)
        local heal = nearest.open_floor(level.rows, base_entry, nil, 2)
        local haste = nearest.open_floor(level.rows, base_entry, heal, 2)

        items[#items + 1] = starting_item(
            item_ids.POT_HEAL_WOUNDS, depth, heal)
        items[#items + 1] = starting_item(
            item_ids.POT_HASTE, depth, haste)
    end

    return {
        level = level,
        parent_links = patches,
        entry = {
            x = entry.x,
            y = entry.y,
        },
        starting_items = items,
    }
end

return generated
