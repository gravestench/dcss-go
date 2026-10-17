local glyphs = require("constants.vault_glyphs")
local effects = require("constants.vault_effects")
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

local function protected_stair(builder, left, top, map_width, map_height)
    for y = top, top + map_height - 1 do
        for x = left, left + map_width - 1 do
            local present = builder:cell(x, y)

            if present == "<" or present == ">" then
                return true
            end
        end
    end

    return false
end

local function preferred_origin(vault, map_width, map_height, random)
    if map_width > width - 4 or map_height > height - 4 then
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

local function protected_cell(builder, cells, left, top, protected)
    for local_y, row in ipairs(cells) do
        for local_x, source in ipairs(row) do
            if source ~= " " then
                local x = left + local_x - 1
                local y = top + local_y - 1
                local key = x .. ":" .. y
                local present = builder:cell(x, y)

                if present == "<" or present == ">" or
                    protected[key] then
                    return true
                end
            end
        end
    end

    return false
end

local function origin(vault, cells, map_width, map_height, builder, options)
    local left, top = preferred_origin(vault, map_width, map_height, builder)
    local protected = options and options.protected

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

local function add_source_record(records, vault, source, x, y)
    local feature = glyphs.terrain[source]

    if feature and source ~= "." then
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

    if kind then
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

local function draw_map(vault, cells, builder, left, top, records)
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

                builder:set(x, y, rendered_glyph(source))
                occupied[#occupied + 1] = point
                add_source_record(records, vault, source, x, y)

                if source == "{" then
                    source_stair = source_stair or point
                elseif source == "@" then
                    entry = entry or point
                end

                local boundary = local_x == 1 or local_x == #row or
                    local_y == 1 or local_y == #cells
                local doorway = boundary and (source == "+" or source == "=")

                if source == "@" or doorway or glyphs.up[source] or
                    glyphs.down[source] then
                    exits[#exits + 1] = {
                        x = x,
                        y = y,
                        source = source,
                    }
                end

                if not floor and rendered_glyph(source) == "." then
                    floor = point
                end
            end
        end
    end

    entry = source_stair or entry or floor

    if not entry then
        error(string.format("%s: vault %s: MAP has no traversable entry",
            vault.path, vault.id))
    end

    if #exits == 0 then
        exits[1] = {
            x = entry.x,
            y = entry.y,
            source = "@",
        }
    end

    return entry, exits, occupied
end

local function choice_context(random)
    local context = {}

    function context:random(_, bound)
        return random:roll(bound)
    end

    return context
end

local function select_entity(record, vault, random)
    local parser = record.kind == effects.MONSTER and monster_specs or item_specs
    local resolver = record.kind == effects.MONSTER and resolve.monster or resolve.item
    local site = {
        path = record.path or vault.path,
        vault_id = record.vault_id or vault.id,
        line = record.line,
        directive = record.directive,
        glyph = record.source,
    }
    local expression = record.identity
    local slots = parser.parse(expression, site)

    if #slots ~= 1 then
        choice.fail(site, expression, "one cell has multiple entity slots")
    end

    local selected = choice.pick(random, slots[1])
    local resolved = resolver(choice_context(random), selected, 1, site)
    local arguments = record.arguments or {}

    arguments.expression = expression
    arguments.path = site.path
    arguments.selected_expression = selected.source
    arguments.no_spawn = resolved.no_spawn or false
    arguments.kind_id = resolved.kind_id or ""
    arguments.base_id = resolved.base_id or ""
    arguments.variant = resolved.variant or ""
    arguments.colour = resolved.colour or ""
    arguments.attitude = resolved.attitude or ""
    arguments.spells = resolved.spells and table.concat(resolved.spells, "|") or ""
    arguments.quantity = resolved.quantity or 1
    arguments.quality = resolved.quality or ""
    arguments.request = resolved.request or ""
    arguments.generation_depth = resolved.generation_depth or 1

    record.identity = selected.name
    record.arguments = arguments
    record.pending = not resolved.no_spawn

    return record
end

local function copy_record(source, x, y)
    local copy = {}

    for key, value in pairs(source) do
        copy[key] = value
    end

    copy.x = x
    copy.y = y

    return copy
end

local function matching_targets(record)
    if record.targets and record.targets ~= "" then
        return record.targets
    end

    if record.arguments and record.arguments.glyph then
        return record.arguments.glyph
    end

    return nil
end

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

local function locate_records(source_records, cells, left, top, entry,
    width_before, height_before, turns, random, vault)
    local located = {}
    local shared_local = {}

    for _, record in ipairs(source_records) do
        local targets = matching_targets(record)
        local count = 0
        local shared_selection

        if record.local_x and record.local_y then
            local x, y = rotated_point(record, width_before, height_before, turns)
            local placed = copy_record(record, left + x - 1, top + y - 1)

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
                    local prior = shared_local[key]

                    placed.identity = prior.identity
                    placed.arguments = prior.arguments
                    placed.pending = prior.pending
                else
                    select_entity(placed, vault, random)

                    if record.assignment_mode == ":" then
                        shared_local[key] = placed
                    end
                end
            end

            located[#located + 1] = placed
            count = 1
        elseif targets then
            for local_y, row in ipairs(cells) do
                for local_x, glyph in ipairs(row) do
                    if glyph ~= " " and targets:find(glyph, 1, true) then
                        local placed = copy_record(record,
                            left + local_x - 1, top + local_y - 1)

                        placed.source = glyph

                        if placed.kind == effects.ITEM or
                            placed.kind == effects.MONSTER then
                            if record.assignment_mode == ":" then
                                if not shared_selection then
                                    shared_selection = select_entity(placed, vault, random)
                                end

                                placed.identity = shared_selection.identity
                                placed.arguments = shared_selection.arguments
                                placed.pending = shared_selection.pending
                            else
                                select_entity(placed, vault, random)
                            end
                        end

                        located[#located + 1] = placed
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

function placement.place(_, builder, vault, player, options)
    local cells, map_width, map_height = matrix(vault.rows)
    local width_before = map_width
    local height_before = map_height
    local source_records = operations.apply(vault, cells, builder, 0, player)
    local turns = 0

    if vault.orientation == "float" and
        not (vault.tags and vault.tags.no_rotate) then
        turns = builder:roll(4)
        cells = transforms.rotate(cells, turns)
        map_width = #cells[1]
        map_height = #cells
    end

    local left, top = origin(vault, cells, map_width, map_height,
        builder, options)
    local records = {}
    local entry, exits, occupied = draw_map(vault, cells, builder, left, top, records)
    local intents = locate_records(source_records, cells, left, top, entry,
        width_before, height_before, turns, builder, vault)

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
                select_entity(record, vault, builder)
            end

            filtered[#filtered + 1] = record
        end
    end

    return {
        id = vault.id,
        family = vault.family,
        path = vault.path,
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
