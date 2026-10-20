-- Theory of operation: the source cross layout carves a broad horizontal
-- passage and a broad vertical passage inside a rock field. Rarely the
-- surrounding field becomes deep water or lava, with clear wall windows
-- between it and the safe cross. Spotty growth roughens ordinary rock maps.
-- Source KFEAT/KMASK/KPROP choices are retained as typed level records.
local grid = require("policy.generation.grid")
local spotty = require("policy.generation.layouts.spotty")
local effects = require("constants.vault_effects")

local layout = {}

-- Source fill_area uses inclusive coordinates; clamping permits the same
-- helper to paint the outer border and the playable interior.
local function fill(builder, x1, y1, x2, y2, glyph)
    for y = math.max(0, math.floor(y1)), math.min(grid.height - 1, math.floor(y2)) do
        for x = math.max(0, math.floor(x1)), math.min(grid.width - 1, math.floor(x2)) do
            builder:set(x, y, glyph)
        end
    end
end

-- The rare window variant preserves source endless-sea terrain through a
-- KFEAT-equivalent record. Its base glyph stays rock until record application.
local function window_records(builder, feature)
    local records = {}

    for y = 0, grid.height - 1 do
        for x = 0, grid.width - 1 do
            local glyph = builder:cell(x, y)

            if glyph == "L" then
                records[#records + 1] = {
                    kind = effects.SOURCE_FEATURE,
                    identity = feature,
                    source = glyph,
                    x = x,
                    y = y,
                    vault_id = "layout_cross",
                }
            elseif glyph == "w" or glyph == "l" then
                records[#records + 1] = {
                    kind = effects.MASK,
                    identity = "no_monster_gen",
                    source = glyph,
                    x = x,
                    y = y,
                    vault_id = "layout_cross",
                }

                if glyph == "l" then
                    records[#records + 1] = {
                        kind = effects.PROPERTY,
                        identity = "no_cloud_gen",
                        source = glyph,
                        x = x,
                        y = y,
                        vault_id = "layout_cross",
                    }
                end
            end
        end
    end

    return records
end

-- The source level-material rarity swaps ordinary rock for stone or metal
-- after carving. This is a real feature change rather than a tile-only tint.
local function level_material(builder, api)
    if api.depth < 4 or api.branch == "Lair" or
        api.branch == "Zot" or api.branch == "Dis" or
        not builder:one_in(20) then
        return
    end

    for y = 0, grid.height - 1 do
        for x = 0, grid.width - 1 do
            if builder:cell(x, y) == "#" then
                builder:set(x, y, builder:roll(3) == 2 and "v" or "c")
            end
        end
    end
end

-- Run the named DES hook. Return both the map and source feature records so
-- later generation can place stairs before decoding terrain into the level.
function layout.layout_cross(api)
    local builder = grid.new(api.ctx)
    local center_x = math.floor(grid.width / 2)
    local center_y = math.floor(grid.height / 2)
    local half_width = 5 - builder:roll(5)
    local half_height = 5 - builder:roll(5)
    local window = api.branch ~= "Lair" and builder:one_in(20)
    local wall = "#"
    local border = "#"
    local feature

    if window then
        if builder:roll(2) == 0 then
            wall = "l"
            feature = "DNGN_LAVA_SEA"
        else
            wall = "w"
            feature = "DNGN_OPEN_SEA"
        end

        border = "L"
    end

    fill(builder, 0, 0, grid.width - 1, grid.height - 1, border)
    fill(builder, 1, 1, grid.width - 2, grid.height - 2, wall)

    if window then
        fill(builder, 10, center_y - half_height - 1,
            grid.width - 10, center_y - half_height - 1, "m")
        fill(builder, 10, center_y + half_height + 1,
            grid.width - 10, center_y + half_height + 1, "m")
        fill(builder, center_x - half_width - 1, 10,
            center_x - half_width - 1, grid.height - 10, "m")
        fill(builder, center_x + half_width + 1, 10,
            center_x + half_width + 1, grid.height - 10, "m")
    end

    fill(builder, 10, center_y - half_height,
        grid.width - 10, center_y + half_height, ".")
    fill(builder, center_x - half_width, 10,
        center_x + half_width, grid.height - 10, ".")

    if not builder:one_in(4) then
        local boxy = builder:roll(2) == 0
        local iterations = builder:roll(boxy and 750 or 1500)

        spotty.carve(builder, boxy, iterations)
    end

    level_material(builder, api)

    if builder.bad_random then
        error("cross layout random source failed to provide a bounded draw")
    end

    return {
        rows = builder:rows(),
        builder = builder,
        records = feature and window_records(builder, feature) or {},
    }
end

return layout
