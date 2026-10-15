-- Source dungeon_feature_type names are the runtime terrain vocabulary.
-- Glyphs are only fixed/generated map source syntax, decoded before the Go
-- grid is built. See dungeon-feature-type.h at e60ba356.
local features = {}

features.from_source_glyph = {
    ["#"] = "DNGN_ROCK_WALL",
    ["."] = "DNGN_FLOOR",
    ["+"] = "DNGN_CLOSED_DOOR",
    ["'"] = "DNGN_OPEN_DOOR",
    ["<"] = "DNGN_STONE_STAIRS_UP_I",
    [">"] = "DNGN_STONE_STAIRS_DOWN_I",
}

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
