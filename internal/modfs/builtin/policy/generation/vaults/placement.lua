-- Example: A vault that overlaps a protected stair tries another origin on the fixed grid.
local glyphs = require("constants.vault_glyphs")
local effects = require("constants.vault_effects")
local directives = require("constants.vault_directives")
local implicit = require("constants.vault_implicit")
local operations = require("policy.generation.vaults.operations")
local transforms = require("policy.generation.vaults.transforms")
local choice = require("policy.generation.vaults.specs.choice")
local monster_specs = require("policy.generation.vaults.specs.monster")
local item_specs = require("policy.generation.vaults.specs.item")
local resolve = require("policy.generation.vaults.specs.resolve")

-- Fit one source map on the established Dungeon grid, preserving the source
-- glyph and location of every dynamic or pending placement.
local placement = {}

local width = 80
local height = 70

-- Pad source rows to a rectangular mutable matrix before rotation.
local function matrix(rows)
    local cells = {}
    local map_width = 0

    for _, row in ipairs(rows) do
        map_width = math.max(map_width, #row)
    end

    for y, row in ipairs(rows) do
        cells[y] = {}

        for x = 1, map_width do
            cells[y][x] = row:sub(x, x)

            if cells[y][x] == "" then
                cells[y][x] = " "
            end
        end
    end

    return cells, map_width, #rows
end

-- A vault candidate cannot cover the level's protected stair landing even when its source glyph is transparent.
local function protected_stair(builder, left, top, map_width, map_height)
    for y = top, top + map_height - 1 do
        for x = left, left + map_width - 1 do
            local present = builder:cell(x, y)

            if glyphs.up[present] or glyphs.down[present] then
                return true
            end
        end
    end

    return false
end

-- Nonfloating vaults honor their side preference before random-fit attempts.
local function preferred_origin(vault, map_width, map_height, random)
    local whole_level = vault.orientation == "encompass"
    local maximum_width = whole_level and width or width - 4
    local maximum_height = whole_level and height or height - 4

    if map_width > maximum_width or map_height > maximum_height then
        error(string.format("%s: vault %s: MAP does not fit an 80x70 level",
            vault.path, vault.id))
    end

    local left = math.floor((width - map_width) / 2)
    local top = math.floor((height - map_height) / 2)
    local side = vault.orientation

    if side:find("west", 1, true) then
        left = 2
    elseif side:find("east", 1, true) then
        left = width - map_width - 2
    elseif side == "float" then
        left = 2 + random:roll(width - map_width - 3)
    end

    if side:find("north", 1, true) then
        top = 2
    elseif side:find("south", 1, true) then
        top = height - map_height - 2
    elseif side == "float" then
        top = 2 + random:roll(height - map_height - 3)
    end

    return left, top
end

-- Ignore transparent spaces but reject overwrites of protected authored cells.
local function protected_cell(builder, cells, left, top, protected)
    for local_y, row in ipairs(cells) do
        for local_x, source in ipairs(row) do
            if source ~= " " then
                local x = left + local_x - 1
                local y = top + local_y - 1
                local key = x .. ":" .. y
                local present = builder:cell(x, y)

                if glyphs.up[present] or glyphs.down[present] or
                    protected[key] then
                    return true
                end
            end
        end
    end

    return false
end

-- Floating vaults retry origins against protected cells without modifying the builder.
local function origin(vault, cells, map_width, map_height, builder, options)
    local protected = options and options.protected

    -- A procedural layout has already chosen the room's connecting wall.
    -- Check the entire candidate before drawing, so a rejected room cannot
    -- erase stairs or records belonging to an earlier placement.
    if options and (options.left ~= nil or options.top ~= nil) then
        local left = options.left
        local top = options.top

        if type(left) ~= "number" or type(top) ~= "number" or
            left % 1 ~= 0 or top % 1 ~= 0 or
            left < 1 or top < 1 or
            left + map_width >= width or top + map_height >= height then
            error(vault.path .. ": invalid exact room origin")
        end

        if protected_cell(builder, cells, left, top, protected or {}) then
            error(vault.path .. ": exact room origin overlaps protected terrain")
        end

        return left, top
    end

    -- A one-cell source `overwrite_floor_cell` map expects connected floor.
    -- Pick from legal existing floor cells instead of opening a rock wall.
    if vault.tags and vault.tags.overwrite_floor_cell then
        if map_width ~= 1 or map_height ~= 1 then
            error(vault.path .. ": overwrite_floor_cell needs one map cell")
        end

        local floors = {}

        for y = 2, height - 3 do
            for x = 2, width - 3 do
                local key = x .. ":" .. y

                if builder:cell(x, y) == "." and
                    not (protected and protected[key]) then
                    floors[#floors + 1] = { x = x, y = y }
                end
            end
        end

        if #floors == 0 then
            error(vault.path .. ": vault " .. vault.id ..
                ": cannot fit without replacing an existing stair")
        end

        local chosen = floors[builder:roll(#floors) + 1]

        return chosen.x, chosen.y
    end

    local left, top = preferred_origin(vault, map_width, map_height, builder)

    -- Use either the explicit protected set or the builder stair guard for a fit.
    local function conflict(x, y)
        if protected then
            return protected_cell(builder, cells, x, y, protected)
        end

        return protected_stair(builder, x, y, map_width, map_height)
    end

    if not conflict(left, top) then
        return left, top
    end

    if vault.orientation ~= "float" then
        error(string.format("%s: vault %s: fixed orientation conflicts with an existing stair",
            vault.path, vault.id))
    end

    for _ = 1, options and options.attempts or 32 do
        left = 2 + builder:roll(width - map_width - 3)
        top = 2 + builder:roll(height - map_height - 3)

        if not conflict(left, top) then
            return left, top
        end
    end

    error(string.format("%s: vault %s: MAP cannot fit without replacing an existing stair",
        vault.path, vault.id))
end

-- Convert source stair and feature glyphs only after retaining their original source identity.
local function rendered_glyph(source)
    if glyphs.up[source] then
        return "<"
    elseif glyphs.down[source] then
        return ">"
    elseif glyphs.wall[source] then
        return "#"
    elseif source == "+" or source == "=" then
        return "+"
    elseif source == "'" then
        return "'"
    end

    return "."
end

-- Implicit item and monster glyphs become typed records alongside rendered terrain.
local function add_source_record(records, vault, source, x, y, overridden)
    local feature = glyphs.terrain[source]

    if feature and source ~= "." and not overridden then
        records[#records + 1] = {
            kind = effects.SOURCE_FEATURE,
            identity = feature,
            source = source,
            x = x,
            y = y,
            vault_id = vault.id,
        }
    end

    local kind
    local identity

    if implicit.items[source] then
        kind = effects.ITEM
        identity = implicit.items[source]
    elseif implicit.monsters[source] then
        kind = effects.MONSTER
        identity = implicit.monsters[source]
    elseif implicit.traps[source] then
        kind = effects.FEATURE
        identity = implicit.traps[source]
    end

    if kind and not overridden then
        records[#records + 1] = {
            kind = kind,
            identity = identity,
            source = source,
            x = x,
            y = y,
            vault_id = vault.id,
            implicit = true,
            pending = true,
        }
    end
end

-- Keyed feature, monster, and item declarations turn their target glyphs
-- into placeholders. DCSS gives the cell plain floor unless KFEAT later
-- supplies terrain; the glyph's normal wall, stair, or implicit occupant
-- must not leak through alongside the explicit keyed record.
local function keyed_overrides(source_records)
    local overridden = {}

    for _, record in ipairs(source_records) do
        if record.directive == directives.KFEAT or
            record.directive == directives.KMONS or
            record.directive == directives.KITEM then
            for glyph in (record.targets or ""):gmatch(".") do
                overridden[glyph] = true
            end
        end
    end

    return overridden
end

-- Project the matrix and collect entry and exits while preserving source-cell records.
local function draw_map(vault, cells, builder, left, top, records,
    overridden)
    local entry
    local source_stair
    local exits = {}
    local occupied = {}
    local floor

    for local_y, row in ipairs(cells) do
        for local_x, source in ipairs(row) do
            if source ~= " " then
                local x = left + local_x - 1
                local y = top + local_y - 1
                local point = { x = x, y = y }
                local keyed = overridden[source]
                local rendered = keyed and "." or rendered_glyph(source)

                builder:set(x, y, rendered)
                occupied[#occupied + 1] = point
                add_source_record(records, vault, source, x, y, keyed)

                if source == "{" and not keyed then
                    source_stair = source_stair or point
                elseif source == "@" then
                    entry = entry or point
                end

                local boundary = local_x == 1 or local_x == #row or
                    local_y == 1 or local_y == #cells
                local doorway = boundary and (source == "+" or source == "=")

                if source == "@" or doorway or
                    (not keyed and (glyphs.up[source] or
                        glyphs.down[source])) then
                    exits[#exits + 1] = {
                        x = x,
                        y = y,
                        source = source,
                    }
                end

                if not floor and rendered == "." then
                    floor = point
                end
            end
        end
    end

    entry = source_stair or entry or floor

    -- A source no_exits decoration may be entirely solid. Its first cell
    -- anchors typed records, but it must never become a corridor target.
    if not entry and vault.tags.no_exits then
        entry = occupied[1]
    end

    if not entry then
        error(string.format("%s: vault %s: MAP has no traversable entry",
            vault.path, vault.id))
    end

    if #exits == 0 and not vault.tags.no_exits then
        exits[1] = {
            x = entry.x,
            y = entry.y,
            source = "@",
        }
    end

    return entry, exits, occupied
end

-- Adapt the vault layout roll to the entity-spec resolver interface.
local function choice_context(random)
    local context = {}

    -- Keep keyed entity alternatives on the same layout stream as map selection.
    function context:random(_, bound)
        return random:roll(bound)
    end

    return context
end

-- Copy a record or its scalar arguments without sharing mutable tables
-- between item slots or cells selected by a colon assignment.
local function copy_fields(source)
    local copy = {}

    for key, value in pairs(source) do
        copy[key] = value
    end

    return copy
end

-- A monster's comma slots are ordered fallbacks at one cell. An item_list
-- instead places every comma slot on that cell, each with its own choice.
local function select_entities(record, vault, random, depth, player)
    local parser = record.kind == effects.MONSTER and monster_specs or item_specs
    local resolver = record.kind == effects.MONSTER and resolve.monster or resolve.item
    local site = {
        path = record.path or vault.path,
        vault_id = record.vault_id or vault.id,
        line = record.line,
        directive = record.directive,
        glyph = record.source,
        branch_id = player and player.branch_id,
        local_depth = player and player.depth,
        absolute_depth = player and player.absolute_depth,
    }
    local expression = record.identity
    local slots = parser.parse(expression, site)
    local original = copy_fields(record)
    local selected_records = {}

    for slot_index, alternatives in ipairs(slots) do
        if record.kind == effects.MONSTER and slot_index > 1 then
            break
        end

        local selected = choice.pick(random, alternatives)
        local resolved = resolver(choice_context(random), selected, depth, site)
        local current = slot_index == 1 and record or copy_fields(original)
        local arguments = copy_fields(original.arguments or {})

        arguments.expression = expression
        -- Later monster slots wait until the live population owns unique
        -- history; item slots are all materialized at this coordinate.
        arguments.monster_slots = record.kind == effects.MONSTER and #slots or 0
        arguments.item_slot = record.kind == effects.ITEM and slot_index or 0
        arguments.path = site.path
        arguments.selected_expression = selected.source
        arguments.no_spawn = resolved.no_spawn or false
        arguments.kind_id = resolved.kind_id or ""
        arguments.class_id = resolved.class_id or ""
        arguments.base_id = resolved.base_id or ""
        arguments.blob_size = resolved.blob_size or 1
        arguments.band = resolved.band or false
        arguments.variant = resolved.variant or ""
        arguments.colour = resolved.colour or ""
        arguments.attitude = resolved.attitude or ""
        arguments.god_id = resolved.god_id or ""
        arguments.spells = resolved.spells and
            table.concat(resolved.spells, "|") or ""
        arguments.vault_awake = vault.tags and
            vault.tags.generate_awake or false
        arguments.generate_awake = resolved.generate_awake or
            arguments.vault_awake
        -- A source patrolling TAG applies to every actor in the map;
        -- a term-level modifier applies only to its selected alternative.
        arguments.vault_patrolling = vault.tags and
            vault.tags.patrolling or false
        arguments.patrolling = resolved.patrolling or
            arguments.vault_patrolling
        arguments.database_name = resolved.database_name or ""
        arguments.custom_name = resolved.custom_name or ""
        arguments.name_adjective = resolved.name_adjective or false
        arguments.hp = resolved.hp or 0
        arguments.hd = resolved.hd or 0
        arguments.permanent_enchantments = resolved.permanent_enchantments and
            table.concat(resolved.permanent_enchantments, "|") or ""
        arguments.quantity = resolved.quantity or 1
        arguments.quality = resolved.quality or ""
        arguments.request = resolved.request or ""
        arguments.generation_depth = resolved.generation_depth or 1
        arguments.disc = resolved.disc or ""
        arguments.numspells = resolved.numspells or 0
        arguments.slevels = resolved.slevels or 0
        arguments.owner = resolved.owner or ""
        arguments.plus = resolved.plus or 0
        arguments.has_plus = resolved.plus ~= nil
        arguments.ego = resolved.ego or ""
        arguments.has_ego = resolved.ego ~= nil
        arguments.allow_uniques = resolved.allow_uniques ~= false
        arguments.unique_id = resolved.unique_id or ""
        arguments.no_pickup = resolved.no_pickup or false
        arguments.ident = resolved.ident or ""
        arguments.tile = resolved.tile or ""
        arguments.weapon_tile = resolved.weapon_tile or ""
        arguments.item_name = resolved.item_name or ""

        current.identity = selected.name
        current.arguments = arguments
        current.pending = not resolved.no_spawn
        selected_records[#selected_records + 1] = current
    end

    return selected_records
end

-- Copy source metadata before adding projected level coordinates.
local function copy_record(source, x, y)
    local copy = copy_fields(source)

    copy.excluded_cells = nil
    copy.x = x
    copy.y = y

    return copy
end

-- Reuse a colon-assignment draw at another cell while giving each record
-- its own arguments for later population and save mutations.
local function reuse_entities(record, selected)
    local copies = {}

    for _, prior in ipairs(selected) do
        local copy = copy_fields(record)

        copy.identity = prior.identity
        copy.arguments = copy_fields(prior.arguments)
        copy.pending = prior.pending
        copies[#copies + 1] = copy
    end

    return copies
end

-- Preserve DES item slot order when adding several records at one cell.
local function append_entities(located, selected)
    for _, record in ipairs(selected) do
        located[#located + 1] = record
    end
end

-- Prefer explicit target glyphs over a record's fallback glyph argument.
local function matching_targets(record)
    if record.targets and record.targets ~= "" then
        return record.targets
    end

    if record.arguments and record.arguments.glyph then
        return record.arguments.glyph
    end

    return nil
end

-- Rotate record coordinates with the map so keyed effects stay on their intended glyphs.
local function rotated_point(record, width_before, height_before, turns)
    local x = record.local_x
    local y = record.local_y

    if turns == 1 then
        return height_before - y + 1, x
    elseif turns == 2 then
        return width_before - x + 1, height_before - y + 1
    elseif turns == 3 then
        return y, width_before - x + 1
    end

    return x, y
end

-- Parent record exclusions use source coordinates. Undo the map rotation
-- before testing a final cell against a nested helper's owned region.
local function original_point(x, y, width_before, height_before, turns)
    if turns == 1 then
        return y, height_before - x + 1
    elseif turns == 2 then
        return width_before - x + 1, height_before - y + 1
    elseif turns == 3 then
        return width_before - y + 1, x
    end

    return x, y
end

-- Match authored record targets to transformed cells before translating them to level positions.
local function locate_records(source_records, cells, left, top, entry,
    width_before, height_before, turns, random, vault, depth, player)
    local located = {}
    local shared_local = {}

    for _, record in ipairs(source_records) do
        local targets = matching_targets(record)
        local count = 0
        local shared_selection

        if record.local_x and record.local_y then
            local x, y = rotated_point(record, width_before, height_before, turns)
            local placed = copy_record(record, left + x - 1, top + y - 1)
            local selected = { placed }

            placed.local_x = nil
            placed.local_y = nil

            if placed.kind == effects.ITEM or placed.kind == effects.MONSTER then
                local key = table.concat({
                    placed.vault_id,
                    placed.line,
                    placed.kind,
                    placed.identity,
                    placed.targets or "",
                }, ":")

                if record.assignment_mode == ":" and shared_local[key] then
                    selected = reuse_entities(placed, shared_local[key])
                else
                    selected = select_entities(placed, vault, random, depth,
                        player)

                    if record.assignment_mode == ":" then
                        shared_local[key] = selected
                    end
                end
            end

            append_entities(located, selected)
            count = 1
        elseif targets then
            for local_y, row in ipairs(cells) do
                for local_x, glyph in ipairs(row) do
                    local original_x, original_y = original_point(
                        local_x, local_y,
                        width_before, height_before, turns)
                    local key = original_x .. ":" .. original_y

                    if glyph ~= " " and targets:find(glyph, 1, true) and
                        not (record.excluded_cells and
                            record.excluded_cells[key]) then
                        local placed = copy_record(record,
                            left + local_x - 1, top + local_y - 1)
                        local selected = { placed }

                        placed.source = glyph

                        if placed.kind == effects.ITEM or
                            placed.kind == effects.MONSTER then
                            if record.assignment_mode == ":" then
                                if not shared_selection then
                                    shared_selection = select_entities(placed,
                                        vault, random, depth, player)
                                    selected = shared_selection
                                else
                                    selected = reuse_entities(placed,
                                        shared_selection)
                                end
                            else
                                selected = select_entities(placed, vault,
                                    random, depth, player)
                            end
                        end

                        append_entities(located, selected)
                        count = count + 1
                    end
                end
            end
        end

        if count == 0 and not targets then
            local pending = copy_record(record, entry.x, entry.y)

            if pending.pending == nil then
                pending.pending = true
            end

            located[#located + 1] = pending
        end
    end

    return located
end

-- Commit terrain only after origin, transforms, and record positions have passed validation.
function placement.place(_, builder, vault, player, options)
    local depth = player and (player.absolute_depth or player.depth) or 1
    local cells, map_width, map_height = matrix(vault.rows)
    local width_before = map_width
    local height_before = map_height
    local source_records = operations.apply(vault, cells, builder, 0, player)
    local overridden = keyed_overrides(source_records)
    local turns = 0

    if options and options.turns ~= nil then
        if type(options.turns) ~= "number" or
            options.turns % 1 ~= 0 or
            options.turns < 0 or options.turns > 3 then
            error(vault.path .. ": invalid exact room rotation")
        end

        turns = options.turns
        cells = transforms.rotate(cells, turns)
        map_width = #cells[1]
        map_height = #cells
    elseif vault.orientation == "float" and
        not (vault.tags and vault.tags.no_rotate) then
        turns = builder:roll(4)
        cells = transforms.rotate(cells, turns)
        map_width = #cells[1]
        map_height = #cells
    end

    local left, top = origin(vault, cells, map_width, map_height,
        builder, options)
    local records = {}
    local entry, exits, occupied = draw_map(vault, cells, builder,
        left, top, records, overridden)
    local intents = locate_records(source_records, cells, left, top, entry,
        width_before, height_before, turns, builder, vault, depth, player)

    for _, record in ipairs(intents) do
        records[#records + 1] = record
    end

    local explicit = {}

    for _, record in ipairs(intents) do
        if (record.kind == effects.ITEM or record.kind == effects.MONSTER or
            record.kind == effects.FEATURE) and
            record.targets and record.targets ~= "" then
            explicit[record.kind .. ":" .. record.x .. ":" .. record.y] = true
        end
    end

    local filtered = {}

    for _, record in ipairs(records) do
        local key = record.kind .. ":" .. record.x .. ":" .. record.y

        if not record.implicit or not explicit[key] then
            if record.implicit and (record.kind == effects.ITEM or
                record.kind == effects.MONSTER) then
                append_entities(filtered,
                    select_entities(record, vault, builder, depth, player))
            else
                filtered[#filtered + 1] = record
            end
        end
    end

    return {
        id = vault.id,
        family = vault.family,
        path = vault.path,
        tags = vault.tags,
        entry = entry,
        exits = exits,
        occupied = occupied,
        records = filtered,
        bounds = {
            x = left,
            y = top,
            width = map_width,
            height = map_height,
        },
    }
end

return placement
