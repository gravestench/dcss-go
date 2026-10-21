-- Theory of operation: a Pan region starts with one mandatory authored
-- primary. An encompassing map is the entire floor; an ordinary primary
-- overlays a source Pan layout and connects its doors to that layout.
-- Later optional maps and population use the same finished builder.
local branches = require("ids.branches")
local branch_levels = require("policy.generation.branch_levels")
local connect = require("policy.generation.vaults.connect")
local extra = require("policy.generation.vaults.extra")
local grid = require("policy.generation.grid")
local layouts = require("policy.generation.layouts.catalog")
local nearest = require("policy.generation.nearest")
local placement = require("policy.generation.vaults.placement")
local selection = require("policy.generation.pan.selection")
local streams = require("constants.rng_streams")
local pan_constants = require("constants.pan_region")
local vaults = require("policy.generation.vaults.catalog")

local region = {}

-- A new visit gets a fresh storage ID while the previous region is still
-- present. The branch and local depth remain Pan:1; only the opaque Go grid
-- key changes. Portal commit discards the previous region after success.
function region.level_id(regions_seen)
    if type(regions_seen) ~= "number" or regions_seen < 0 or
        regions_seen % 1 ~= 0 then
        error("Pan region count must be a nonnegative integer")
    end

    return branch_levels.id(branches.BRANCH_PANDEMONIUM, 1) +
        regions_seen * pan_constants.LEVEL_ID_STRIDE
end

-- Hooks read a snapshot of saved player facts while the region is planned.
-- Passing these facts explicitly keeps generation independent of a mutable
-- Lua global and lets portal travel commit the plan only after it succeeds.
local function placement_player(history)
    return {
        branch_id = branches.BRANCH_PANDEMONIUM,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 24,
        species_id = history.species_id,
        name = history.player_name,
        started = true,
        prior_vault_ids = history.prior_vault_ids,
        collected_runes = history.collected_runes,
        pan_rune_count = history.pan_rune_count,
    }
end

-- All occupied primary cells are protected from the optional Pan pass.
-- Source transparent spaces are absent from this set, so a later extra
-- map can still use a genuinely empty area of the chosen rectangle.
local function protected_cells(placed)
    local protected = {}

    for _, point in ipairs(placed.occupied) do
        protected[point.x .. ":" .. point.y] = true
    end

    return protected
end

-- A later opaque vault replaces the terrain and entities beneath each of
-- its cells. Retire older cell records too: a source wall record from the
-- base layout must not repaint a keyed monster's floor after DES carving.
-- Level-wide style records have no cell and remain in source order.
local function overlay_records(records, placed)
    local occupied = protected_cells(placed)
    local combined = {}

    for _, record in ipairs(records) do
        local coordinate = record.x and record.y and
            (record.x .. ":" .. record.y)

        if not coordinate or not occupied[coordinate] then
            combined[#combined + 1] = record
        end
    end

    for _, record in ipairs(placed.records or {}) do
        combined[#combined + 1] = record
    end

    return combined
end

-- Only placement conflicts can ask for a new procedural base layout. A
-- malformed hook or source directive must surface immediately to the mod
-- author instead of spending 32 draws and reporting a misleading fit error.
local function layout_conflict(message)
    return message:find("conflicts with an existing stair", 1, true) or
        message:find("no ordinary Dungeon floor to connect", 1, true) or
        message:find("cannot fit without replacing", 1, true)
end

-- A regular Pan primary receives a separate layout. Keep the selected
-- primary fixed while redrawing a conflicting base so layout RNG, not file
-- order or a second map draw, resolves its geometric fit.
local function build_regular(ctx, map, player, history)
    local random = grid.new(ctx)
    local last_conflict

    for _ = 1, 32 do
        local definition = layouts.choose(random,
            branches.BRANCH_PANDEMONIUM, 1, 1, map.tags)
        local layout = layouts.execute(ctx, definition,
            branches.BRANCH_PANDEMONIUM, 1, {
                up = 0,
                down = 0,
            }, history.prior_vault_ids)
        local builder = layout.builder
        local okay, placed = pcall(placement.place, ctx, builder,
            map, player, {
                whole_level = true,
            })

        if okay then
            local connected, message = pcall(connect.finish, ctx,
                builder, placed, {})

            if connected then
                return builder, placed, definition.id,
                    layout.records or {}, layout.vault_ids or {}
            end

            placed = message
        end

        if not layout_conflict(tostring(placed)) then
            error(placed)
        end

        last_conflict = placed
    end

    error("Pan primary could not fit after 32 layouts: " ..
        tostring(last_conflict))
end

-- An encompassing map has no ordinary floor outside its rectangle, so
-- connector carving would invent terrain that the source map did not ask
-- for. Its authored cell and feature records stand on their own.
local function build_encompassing(ctx, map, player)
    local builder = grid.new(ctx)
    local placed = placement.place(ctx, builder, map, player, {
        whole_level = true,
    })

    return builder, placed, nil, {}, {}
end

-- Return a complete primary plan without publishing a live level. The
-- caller can add optional maps, decode terrain, and validate the result
-- before generic portal travel replaces the previous Pan region.
function region.build_primary(ctx, map, history)
    if map.family ~= "pan" then
        error("Pan primary must come from vaults/pan")
    end

    local player = placement_player(history)
    local builder
    local placed
    local layout_id
    local layout_records
    local layout_vault_ids

    if map.orientation == "encompass" then
        builder, placed, layout_id, layout_records, layout_vault_ids =
            build_encompassing(ctx, map, player)
    else
        builder, placed, layout_id, layout_records, layout_vault_ids =
            build_regular(ctx, map, player, history)
    end

    local records = overlay_records(layout_records, placed)

    -- A source entry glyph may itself be a portal or stair. Arrival uses
    -- nearby open floor so it never replaces the authored exit feature.
    local entry = nearest.open_floor(builder:rows(), placed.entry, nil, 1)

    return {
        builder = builder,
        map = placed,
        entry = entry,
        layout_id = layout_id,
        layout_vault_ids = layout_vault_ids,
        records = records,
        protected = protected_cells(placed),
    }
end

-- Only the Pan source extra pool follows a non-encompassing primary. Its
-- already placed primary ID joins the uniqueness ledger before any later
-- candidate draws, but the region record keeps that ID exactly once.
local function add_extras(ctx, built, history)
    if not built.layout_id then
        return {}, {}
    end

    local prior = {}

    for _, id in ipairs(history.prior_vault_ids or {}) do
        prior[#prior + 1] = id
    end

    prior[#prior + 1] = built.map.id

    for _, id in ipairs(built.layout_vault_ids or {}) do
        prior[#prior + 1] = id
    end

    for _, id in ipairs(built.map.vault_ids or {}) do
        prior[#prior + 1] = id
    end

    local context = {
        branch_id = branches.BRANCH_PANDEMONIUM,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 24,
        branch_vault_family = "pan",
        regular_extra_only = true,
        prior_vault_ids = prior,
        protected = built.protected,
        required = {},
        player = placement_player(history),
    }
    local placed, _, ids = extra.generate(ctx,
        built.builder, context)

    return placed, ids
end

-- Pan uses three eight-sided population dice. Keep the shared named RNG
-- stream so a save in a later region resumes ambient monster draws exactly.
local function monster_count(ctx)
    local total = 0

    for _ = 1, 3 do
        total = total + ctx:random(streams.POPULATION_COUNT, 8) + 1
    end

    return total
end

-- Choose, build, and describe one region without changing the live world.
-- Generic portal travel installs this complete plan atomically, then records
-- the region number and selected IDs in its saved session state.
function region.generate(ctx, history)
    local random = grid.new(ctx)
    local selected = selection.choose(random, history)
    local built = region.build_primary(ctx, vaults.get(selected.id), history)
    local extras, extra_ids = add_extras(ctx, built, history)
    local records = built.records
    local ids = {}

    for _, id in ipairs(built.layout_vault_ids or {}) do
        ids[#ids + 1] = id
    end

    ids[#ids + 1] = built.map.id

    for _, id in ipairs(built.map.vault_ids or {}) do
        ids[#ids + 1] = id
    end

    for _, map in ipairs(extras) do
        records = overlay_records(records, map)
    end

    for _, id in ipairs(extra_ids) do
        ids[#ids + 1] = id
    end

    local branch_id = branches.BRANCH_PANDEMONIUM

    -- Extras can replace open cells outside the protected primary. Choose
    -- the landing from the finished map, anchored to the primary's authored
    -- entry, so a late extra cannot strand the arriving player in rock.
    local entry = nearest.open_floor(built.builder:rows(),
        built.map.entry, nil, 1)

    return {
        id = region.level_id(history.levels_seen or 0),
        branch_id = branch_id,
        local_depth = 1,
        rows = built.builder:rows(),
        stairs = {},
        entry_x = entry.x,
        entry_y = entry.y,
        initial_monsters = monster_count(ctx),
        vault_id = built.map.id,
        vault_ids = ids,
        vault_records = records,
    }
end

return region
