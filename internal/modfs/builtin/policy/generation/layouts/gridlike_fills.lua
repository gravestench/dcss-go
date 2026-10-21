-- Theory of operation: some Gridlike rooms contain a second pair of
-- materials. The first rectangle forms an outer band; a smaller nested
-- rectangle supplies its core. The source's keyed L/y/z terrain and
-- no-teleport/opaque flags become typed effects at their final coordinates.
-- A source 1 cell is walkable floor occupied by the MONS: plant slot.
local catalog = require("policy.catalog")
local effects = require("constants.vault_effects")
local masks = require("constants.vault_masks")
local properties = require("constants.vault_properties")
local monsters = require("ids.monsters")
local subdivision = require("policy.generation.layouts.subdivision")
local material_pairs = require("policy.generation.layouts.gridlike_materials")

local fills = {}

local keyed_terrain = {
    L = "l",
    y = "W",
    z = "w",
    ["1"] = ".",
}

-- One source weighted draw chooses the entire room's outer/inner pair.
local function choose_pair(builder)
    local total = 0

    for _, pair in ipairs(material_pairs) do
        total = total + pair.weight
    end

    local draw = builder:roll(total)

    for _, pair in ipairs(material_pairs) do
        if draw < pair.weight then
            return pair
        end

        draw = draw - pair.weight
    end
end

-- Source area_in_bounds keeps at least one cell of room padding and a
-- minimum area based on sixty percent of its shorter dimension.
local function nested_area(builder, bounds, minimum)
    local available_width = bounds.x2 - bounds.x1 - 1
    local available_height = bounds.y2 - bounds.y1 - 1

    if available_width < minimum or available_height < minimum then
        return nil
    end

    local width = subdivision.range(builder, minimum, available_width)
    local height = subdivision.range(builder, minimum, available_height)
    local x1 = subdivision.range(builder, bounds.x1 + 1,
        bounds.x2 - width)
    local y1 = subdivision.range(builder, bounds.y1 + 1,
        bounds.y2 - height)

    return {
        x1 = x1,
        y1 = y1,
        x2 = x1 + width - 1,
        y2 = y1 + height - 1,
    }
end

-- A cell's later inner fill replaces any earlier outer effect at that
-- coordinate. Keep the source glyph separately from its final terrain.
local function paint_area(builder, bounds, source, marks)
    local terrain = keyed_terrain[source] or source

    for y = bounds.y1, bounds.y2 do
        for x = bounds.x1, bounds.x2 do
            builder:set(x, y, terrain)
            marks[y * builder.width + x] = {
                x = x,
                y = y,
                source = source,
            }
        end
    end
end

-- Preserve a keyed no-teleport property, and the source opaque flag for
-- shallow water, as ordinary saved vault records.
local function terrain_records(mark, vault_id)
    local records = {}

    if mark.source == "L" or mark.source == "y" or
        mark.source == "z" then
        records[#records + 1] = {
            kind = effects.PROPERTY,
            identity = properties.NO_TELE_INTO,
            source = mark.source,
            x = mark.x,
            y = mark.y,
            vault_id = vault_id,
        }
    end

    if mark.source == "y" then
        records[#records + 1] = {
            kind = effects.MASK,
            identity = masks.OPAQUE,
            source = mark.source,
            x = mark.x,
            y = mark.y,
            vault_id = vault_id,
        }
    end

    return records
end

-- Source mons("plant") binds digit 1 to a plant. A selected monster
-- record lets the existing vault population owner spawn it and save its
-- origin, instead of embedding special monster creation in the layout.
local function plant_record(mark, api)
    local definition = catalog.get("monsters", monsters.MONS_PLANT)

    return {
        kind = effects.MONSTER,
        identity = definition.name,
        source = mark.source,
        x = mark.x,
        y = mark.y,
        vault_id = api.definition.id,
        pending = true,
        arguments = {
            path = api.definition.path,
            kind_id = definition.id,
            selected_expression = definition.name,
            monster_slots = 1,
        },
    }
end

-- Emit records in coordinate order after all nested fills have painted.
-- This prevents an overwritten plant or keyed cell from surviving on top
-- of a different final terrain feature.
local function collect_records(builder, marks, api)
    local records = {}

    for y = 0, builder.height - 1 do
        for x = 0, builder.width - 1 do
            local mark = marks[y * builder.width + x]

            if mark then
                if mark.source == "1" then
                    records[#records + 1] = plant_record(mark, api)
                else
                    for _, record in ipairs(terrain_records(mark,
                        api.definition.id)) do
                        records[#records + 1] = record
                    end
                end
            end
        end
    end

    return records
end

-- Rooms without the corner style and without an owned door have a
-- one-in-five source chance to contain the material-pair decoration.
function fills.paint(builder, cells, choices, api)
    local marks = {}

    if choices.corners then
        return {}
    end

    for _, cell in ipairs(cells) do
        if cell.tile == "room" and not cell.has_doors and
            builder:cell(math.floor((cell.x1 + cell.x2) / 2),
                math.floor((cell.y1 + cell.y2) / 2)) == "." and
            builder:one_in(5) then
            local width = cell.x2 - cell.x1 + 1
            local height = cell.y2 - cell.y1 + 1
            local minimum = math.max(3,
                math.ceil(math.min(width, height) * 0.6))
            local pair = choose_pair(builder)
            local outer = nested_area(builder, cell, minimum)

            if outer then
                paint_area(builder, outer, pair.outer, marks)
            end

            local inner = nested_area(builder, outer or cell,
                math.max(1, minimum - 2))

            if inner then
                paint_area(builder, inner,
                    outer and pair.inner or pair.outer, marks)
            end
        end
    end

    return collect_records(builder, marks, api)
end

return fills
