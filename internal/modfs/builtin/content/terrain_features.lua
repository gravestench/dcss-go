-- Source dungeon_feature_type names are the runtime terrain vocabulary.
-- Glyphs are only fixed/generated map source syntax, decoded before the Go
-- grid is built. See dungeon-feature-type.h at e60ba356.
local features = {}
local effects = require("constants.vault_effects")

features.from_source_glyph = {
    ["#"] = "DNGN_ROCK_WALL",
    ["."] = "DNGN_FLOOR",
    ["+"] = "DNGN_CLOSED_DOOR",
    ["'"] = "DNGN_OPEN_DOOR",
    ["<"] = "DNGN_STONE_STAIRS_UP_I",
    [">"] = "DNGN_STONE_STAIRS_DOWN_I",
}

-- Some source stair and hatch variants share the current kernel's travel
-- behavior. Their original identity remains in the saved vault record.
features.vault_terrain = {
    DNGN_FLOOR = "DNGN_FLOOR",
    DNGN_ROCK_WALL = "DNGN_ROCK_WALL",
    DNGN_PERMAROCK_WALL = "DNGN_PERMAROCK_WALL",
    DNGN_STONE_WALL = "DNGN_STONE_WALL",
    DNGN_CLEAR_ROCK_WALL = "DNGN_CLEAR_ROCK_WALL",
    DNGN_CLEAR_STONE_WALL = "DNGN_CLEAR_STONE_WALL",
    DNGN_CLEAR_PERMAROCK_WALL = "DNGN_CLEAR_PERMAROCK_WALL",
    DNGN_METAL_WALL = "DNGN_METAL_WALL",
    DNGN_CRYSTAL_WALL = "DNGN_CRYSTAL_WALL",
    DNGN_TREE = "DNGN_TREE",
    DNGN_CLOSED_DOOR = "DNGN_CLOSED_DOOR",
    DNGN_RUNED_DOOR = "DNGN_CLOSED_DOOR",
    DNGN_SHALLOW_WATER = "DNGN_SHALLOW_WATER",
    DNGN_DEEP_WATER = "DNGN_DEEP_WATER",
    DNGN_LAVA = "DNGN_LAVA",
    DNGN_STONE_STAIRS_UP_I = "DNGN_STONE_STAIRS_UP_I",
    DNGN_STONE_STAIRS_UP_II = "DNGN_STONE_STAIRS_UP_I",
    DNGN_STONE_STAIRS_UP_III = "DNGN_STONE_STAIRS_UP_I",
    DNGN_STONE_STAIRS_DOWN_I = "DNGN_STONE_STAIRS_DOWN_I",
    DNGN_STONE_STAIRS_DOWN_II = "DNGN_STONE_STAIRS_DOWN_I",
    DNGN_STONE_STAIRS_DOWN_III = "DNGN_STONE_STAIRS_DOWN_I",
    DNGN_ESCAPE_HATCH_UP = "DNGN_STONE_STAIRS_UP_I",
    DNGN_ESCAPE_HATCH_DOWN = "DNGN_STONE_STAIRS_DOWN_I",
    DNGN_GRANITE_STATUE = "DNGN_GRANITE_STATUE",
    DNGN_ORCISH_IDOL = "DNGN_ORCISH_IDOL",
}

features.named_vault_terrain = {
    floor = "DNGN_FLOOR",
    rock_wall = "DNGN_ROCK_WALL",
    stone_wall = "DNGN_STONE_WALL",
    perma_rock_wall = "DNGN_PERMAROCK_WALL",
    clear_rock_wall = "DNGN_CLEAR_ROCK_WALL",
    clear_stone_wall = "DNGN_CLEAR_STONE_WALL",
    metal_wall = "DNGN_METAL_WALL",
    crystal_wall = "DNGN_CRYSTAL_WALL",
    tree = "DNGN_TREE",
    petrified_tree = "DNGN_PETRIFIED_TREE",
    granite_statue = "DNGN_GRANITE_STATUE",
    closed_door = "DNGN_CLOSED_DOOR",
    open_door = "DNGN_OPEN_DOOR",
    shallow_water = "DNGN_SHALLOW_WATER",
    deep_water = "DNGN_DEEP_WATER",
    lava = "DNGN_LAVA",
}

function features.apply_vault_terrain(cells, records)
    local retained = {}

    for _, record in ipairs(records or {}) do
        local keep = true

        if record.kind == effects.SOURCE_FEATURE and record.overridden then
            keep = false
        elseif record.kind == effects.SOURCE_FEATURE then
            local feature = features.vault_terrain[record.identity]

            if feature then
                cells[record.y + 1][record.x + 1] = feature

                if feature == record.identity then
                    keep = false
                end
            end
        elseif record.kind == effects.FEATURE and not record.overridden then
            local feature = features.named_vault_terrain[record.identity]

            if feature then
                cells[record.y + 1][record.x + 1] = feature
                record.pending = false
                keep = false
            end
        end

        if keep then
            retained[#retained + 1] = record
        end
    end

    return retained
end

function features.decode_source_rows(rows)
    local cells = {}

    for y, row in ipairs(rows) do
        local cell_row = {}

        for x = 1, #row do
            local glyph = row:sub(x, x)
            local feature = features.from_source_glyph[glyph]

            if not feature then
                error(string.format("unknown source terrain glyph %q at (%d,%d)", glyph, x - 1, y - 1))
            end

            cell_row[x] = feature
        end

        cells[y] = cell_row
    end

    return cells
end

return features
