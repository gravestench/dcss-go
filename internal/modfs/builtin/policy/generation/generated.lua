-- Example: authored stairs on any Dungeon floor gain paired landings nearby.
local grid = require("policy.generation.grid")
local layouts = require("policy.generation.layouts.catalog")
local availability = require("policy.generation.floor_availability")
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
local temple_plan = require("policy.generation.temple.plan")
local branch_levels = require("policy.generation.branch_levels")
local temple_catalog = require("policy.generation.temple.catalog")
local branch_entry = require("policy.generation.vaults.branch_entry")
local temple_floor = require("policy.generation.temple.floor")
local altar_catalog = require("policy.generation.altar.catalog")
local shop_spec = require("policy.generation.vaults.shop_spec")
local shoals_heights = require("policy.generation.shoals_heights")

local generated = {}

local entrance_directions = {
    { x = 1, y = 0 },
    { x = -1, y = 0 },
    { x = 0, y = 1 },
    { x = 0, y = -1 },
}

-- Each floor draws three population dice from its own depth-specific die size.
local function monster_count(ctx, branch_id, depth)
    local branch = register.get("branches", branch_id)
    local die_size = tonumber(branch.mon_die_size_expr)

    if not die_size then
        -- Source Dungeon generation uses its own deeper-floor die. Other
        -- branches use the source default of twelve sides per die.
        die_size = branch_id == branches.BRANCH_DUNGEON and
            depth > 1 and 10 or 12
    end
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

    -- A procedural primary layout can contain its own authored rooms.
    -- Secondary vaults must not replace those cells or leave their saved
    -- source-feature records pointing at unrelated later terrain.
    for key in pairs(level.protected or {}) do
        cells[key] = true
    end

    for _, point in ipairs(placed and placed.occupied or {}) do
        vault_extra.protect(cells, point)
    end

    for _, pair in ipairs(level.stairs) do
        if pair.up then
            vault_extra.protect(cells, pair.up)
        end

        if pair.down then
            vault_extra.protect(cells, pair.down)
        end
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
        local vault = map.family == "altar" and
            altar_catalog.get(map.id) or vault_catalog.get(map.id)

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
        if pair.up then
            points[#points + 1] = pair.up
        end

        if pair.down then
            points[#points + 1] = pair.down
        end
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
-- ordinary linked-stair feature. The branch floor is built on first entry,
-- so its stable ID is pending while the destination coordinates are not.
local function place_branch_entrances(ctx, builder, layout, protected,
    required, player, chosen, branch_id, depth, temple)
    local links = {}
    local maps = {}
    local entries = branch_schedule.entries(chosen, branch_id, depth)
    local start = layout.stairs[1].up

    for _, entry in ipairs(entries) do
        local point
        local branch = register.get("branches", entry.branch_id)
        local is_temple = entry.branch_id == branches.BRANCH_TEMPLE
        local available = is_temple and
            temple_catalog.main(temple.map_id) ~= nil or
            availability.can_build(entry.branch_id, 1)

        if is_temple or entry.branch_id == branches.BRANCH_SLIME then
            local placed

            placed, point = branch_entry.place(ctx, builder, protected,
                required, player, entry.branch_id)

            if placed then
                maps[#maps + 1] = placed
            end
        end

        if not point then
            point = entrance_cell(builder, start, protected)
            builder:set(point.x, point.y, ">")
            vault_extra.protect(protected, point)
        end

        links[#links + 1] = {
            x = point.x,
            y = point.y,
            to_level_id = available and
                branch_levels.id(entry.branch_id, 1) or 0,
            to_x = 0,
            to_y = 0,
            pending = available,
            unavailable = available and "" or
                "The entrance to " .. branch.long_name ..
                    " has no ported primary layout yet.",
            target_branch_id = entry.branch_id,
            source_feature = entry.entry_feature,
        }
    end

    return links, maps
end

-- Generate one floor before pairing its stairs with neighboring floors.
-- The arrival only belongs to D:1; supplemental vaults use actual depth.
local function build_floor_once(ctx, player, branch_id, depth, prior_vault_ids,
    chosen_schedule, temple, end_choice)
    if branch_id == branches.BRANCH_TEMPLE then
        return temple_floor.build(ctx, temple, player)
    end

    local branch = register.get("branches", branch_id)
    local bottom = branch.depth
    local absolute_depth = branch.absolute_depth + depth - 1

    -- Source Dungeon stores zero as its branch offset, while item and
    -- monster generation use one-based absolute depth on D:1.
    if branch_id == branches.BRANCH_DUNGEON then
        absolute_depth = depth
    end
    local profile = {
        up = branch_id ~= branches.BRANCH_DUNGEON and depth == 1 and 1 or 3,
        down = (branch_id == branches.BRANCH_DUNGEON or
            depth < bottom) and 3 or 0,
    }
    local layout
    local arrival
    local arrival_vault

    if branch_id == branches.BRANCH_DUNGEON and depth == 1 then
        layout, arrival, arrival_vault = place_first_level(ctx, player)
    else
        local random = grid.new(ctx)
        local definition = layouts.choose(random,
            branch_id, depth, bottom)

        layout = layouts.execute(ctx, definition,
            branch_id, depth, profile, prior_vault_ids)
    end

    local required = base_stair_points(layout)

    if arrival then
        vault_connect.finish(ctx, layout.builder, arrival, required)
    end

    local protected = protected_cells(layout, arrival)
    local entry_player = {
        branch_id = branch_id,
        depth = depth,
        branch_bottom = bottom,
        absolute_depth = absolute_depth,
        species_id = player.species_id,
        name = player.name,
        started = player.started,
    }
    local branch_links, entry_maps = place_branch_entrances(ctx,
        layout.builder, layout, protected, required, entry_player,
        chosen_schedule, branch_id, depth, temple)
    local extra, controller, extra_ids = vault_extra.generate(
        ctx,
        layout.builder,
        {
            branch_id = branch_id,
            depth = depth,
            branch_bottom = bottom,
            absolute_depth = absolute_depth,
            end_vault_family = branch.end_vault_required and
                depth == bottom and branch.end_vault_family or nil,
            end_choice = end_choice,
            layout_family = layout_family(layout),
            branch_vault_family = branch.abbreviation:lower(),
            prior_vault_ids = prior_vault_ids,
            primary_room_ids = layout.room_ids,
            overflow_schedule = temple.overflow_schedule,
            arrival_vault = arrival_vault,
            protected = protected,
            required = required,
            player = {
                species_id = player.species_id,
                name = player.name,
                started = player.started or false,
                branch_id = branch_id,
                depth = depth,
                branch_bottom = bottom,
                absolute_depth = absolute_depth,
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

    append_vault_records(records, entry_maps)
    append_vault_records(records, extra)

    -- A Temple entrance map can also contain an ordinary Dungeon stair.
    -- Pair those authored exits with the next floor just like extra vault
    -- exits; the scheduled Temple feature keeps its separate branch link.
    for _, map in ipairs(entry_maps) do
        add_source_stairs(map, source_up, source_down)
    end

    local vault_ids = {}

    -- Whole-map layouts can place named helper vaults before the ordinary
    -- secondary pass. Preserve that history for uniqueness and save checks.
    for _, id in ipairs(layout.vault_ids or {}) do
        vault_ids[#vault_ids + 1] = id
    end

    for _, map in ipairs(entry_maps) do
        vault_ids[#vault_ids + 1] = map.id
    end

    for _, id in ipairs(extra_ids) do
        vault_ids[#vault_ids + 1] = id
    end

    for _, map in ipairs(extra) do
        add_source_stairs(map, source_up, source_down)
    end

    return {
        id = branch_levels.id(branch_id, depth),
        branch_id = branch_id,
        depth = depth,
        layout = layout,
        arrival = arrival,
        arrival_vault = arrival_vault,
        extra = extra,
        controller = controller,
        end_vault_id = branch.end_vault_required and
            depth == bottom and controller or nil,
        vault_ids = vault_ids,
        records = records,
        protected = protected,
        source_up = source_up,
        source_down = source_down,
        links = branch_links,
    }
end

-- A fixed end map may cover stairs completed by an otherwise valid base
-- layout. Redraw the whole floor in that one case so no partial geometry,
-- records, or uniqueness history escape from a rejected attempt.
local function build_floor(ctx, player, branch_id, depth, prior_vault_ids,
    chosen_schedule, temple)
    local branch = register.get("branches", branch_id)
    local required_end = branch.end_vault_required and depth == branch.depth

    if not required_end then
        return build_floor_once(ctx, player, branch_id, depth,
            prior_vault_ids, chosen_schedule, temple)
    end

    local last_fit_error
    local end_choice = {}

    for _ = 1, 32 do
        local okay, result = pcall(build_floor_once, ctx, player,
            branch_id, depth, prior_vault_ids, chosen_schedule,
            temple, end_choice)

        if okay then
            return result
        end

        local failed_fit = tostring(result):find(
            "end vault could not fit on base layout:", 1, true)
        local invalid_rune = tostring(result):find(
            "end vault rejected rune selection:", 1, true)

        if not failed_fit and not invalid_rune then
            error(result)
        end

        last_fit_error = result
    end

    error(branch.abbreviation .. ":" .. depth ..
        " could not fit an end vault after 32 layouts: " ..
        tostring(last_fit_error))
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
local function level_record(ctx, floor)
    local arrival = floor.arrival
    local entry = floor_entry(floor)
    local base_exclusions

    if arrival then
        base_exclusions = spawn_exclusions(arrival, floor.arrival_vault)
    end

    -- Shop records must still own the floor cell chosen by their DES map.
    -- A later connector or branch stair must not leave a stale shop intent.
    for _, record in ipairs(floor.records) do
        if record.kind == vault_effects.FEATURE and
            shop_spec.is_shop(record.identity) and
            floor.layout.builder:cell(record.x, record.y) ~= "." then
            error(string.format("%s shop at %d:%d lost its floor cell (%s)",
                record.vault_id or "vault", record.x, record.y,
                tostring(floor.layout.builder:cell(record.x, record.y))))
        end
    end

    return {
        id = floor.id,
        branch_id = floor.branch_id,
        local_depth = floor.depth,
        rows = floor.layout.builder:rows(),
        heightmap = shoals_heights.overlay(floor),
        stairs = floor.links,
        entry_x = entry.x,
        entry_y = entry.y,
        initial_monsters = floor.branch_id == branches.BRANCH_TEMPLE and
            0 or monster_count(ctx, floor.branch_id, floor.depth),
        vault_id = floor.end_vault_id or floor.layout.primary_id or
            (arrival and arrival.id or floor.controller),
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
    local temple = temple_plan.choose(ctx)
    local schedule = branch_schedule.choose(ctx)
    local player = {
        species_id = input.player_species_id,
        name = input.player_name,
        started = false,
    }
    local floor = build_floor(ctx, player,
        branches.BRANCH_DUNGEON, 1, {}, schedule, temple)

    live_stairs.first(floor)

    local level = level_record(ctx, floor)
    local entry = floor_entry(floor)
    local curing = nearest.open_floor(level.rows, entry, nil, 1)

    return {
        levels = { level },
        branch_schedule = schedule,
        temple_plan = temple,
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
    temple_plan.validate(input.temple_plan)
    local branch_id = input.branch_id
    local depth = input.local_depth
    local branch = register.get("branches", branch_id)
    local bottom = branch.depth
    local parent = input.parent
    local level_id = branch_levels.id(branch_id, depth)

    if input.level_id ~= level_id or depth > bottom or
        not availability.can_build(branch_id, depth) then
        error("next floor has invalid branch depth or ID")
    end

    if depth == 1 then
        local entry = input.branch_schedule.entries[branch_id]

        if not entry or parent.branch_id ~= entry.parent_id or
            parent.local_depth ~= entry.parent_depth then
            error("branch entry does not match its scheduled parent")
        end
    elseif parent.branch_id ~= branch_id or
        parent.local_depth ~= depth - 1 then
        error("next branch floor needs its contiguous parent")
    end

    local player = {
        species_id = input.player_species_id,
        name = input.player_name,
        started = true,
    }
    local floor = build_floor(ctx, player, branch_id, depth,
        input.prior_vault_ids, input.branch_schedule, input.temple_plan)
    local patches, entry = live_stairs.pair(ctx, parent, floor, {
        x = input.from_x,
        y = input.from_y,
    })
    local level = level_record(ctx, floor)
    local items = {}

    level.entry_x = entry.x
    level.entry_y = entry.y

    if branch_id == branches.BRANCH_DUNGEON and depth == 2 then
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
