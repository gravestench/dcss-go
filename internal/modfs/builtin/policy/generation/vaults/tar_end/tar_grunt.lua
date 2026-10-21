-- Grunt's Tartarus controller is mapless in the source. It paints a 70x70
-- base, places Ereshkigal near the center, then draws the tagged details.
local effects = require("constants.vault_effects")

local handler = {}
local SIZE = 70
local neighbors = {
    { 1, 0 },
    { -1, 0 },
    { 0, 1 },
    { 0, -1 },
}

local function original_glyph(x, y)
    if x == 0 or y == 0 or x == SIZE - 1 or y == SIZE - 1 then
        return "x"
    end

    if x >= 4 and x <= 65 and y >= 4 and y <= 65 then
        return "."
    end

    if x >= 2 and x <= 67 and y >= 2 and y <= 67 then
        if x == 2 or x == 67 or y == 2 or y == 67 then
            return "-"
        end

        return "_"
    end

    return "X"
end

local function substitute(api, cells, source, choices)
    for y = 1, SIZE do
        for x = 1, SIZE do
            if cells[y][x] == source then
                local choice = api:roll(#choices) + 1

                cells[y][x] = choices:sub(choice, choice)
            end
        end
    end
end

-- Source remove_isolated_glyphs replaces single floor cells with no
-- cardinal floor neighbor. Its C_POINTY radius-one iterator excludes diagonals.
local function remove_isolated_floor(cells)
    -- The C++ helper leaves the outermost border untouched.
    for y = 2, SIZE - 1 do
        for x = 2, SIZE - 1 do
            if cells[y][x] == "." then
                local isolated = true

                for _, delta in ipairs(neighbors) do
                    if cells[y + delta[2]][x + delta[1]] == "." then
                        isolated = false
                        break
                    end
                end

                if isolated then
                    cells[y][x] = "x"
                end
            end
        end
    end
end

local function paint_base(api)
    local builder = api.builder

    if builder.width < SIZE or builder.height < SIZE then
        error("tar_grunt needs a 70x70 end floor")
    end

    local left = math.floor((builder.width - SIZE) / 2)
    local top = math.floor((builder.height - SIZE) / 2)
    local cells = {}
    local properties = {}

    for y = 0, SIZE - 1 do
        cells[y + 1] = {}

        for x = 0, SIZE - 1 do
            local glyph = original_glyph(x, y)
            cells[y + 1][x + 1] = glyph

            if glyph == "X" or glyph == "-" or glyph == "_" then
                properties[#properties + 1] = {
                    kind = effects.PROPERTY,
                    identity = "no_tele_into",
                    source = glyph,
                    x = left + x,
                    y = top + y,
                    vault_id = "tar_grunt",
                }
            end
        end
    end

    -- Preserve the source's three separate substitution passes and their
    -- different floor odds before the isolated-pocket cleanup.
    substitute(api, cells, "X", "xx.")
    substitute(api, cells, "-", "x.")
    substitute(api, cells, "_", "x..")
    remove_isolated_floor(cells)

    for y = 0, SIZE - 1 do
        for x = 0, SIZE - 1 do
            builder:set(left + x, top + y, cells[y + 1][x + 1])
        end
    end

    return properties
end

-- This runs after the source's mapless controller has claimed the primary
-- choice. Child requests stay in the exact post_place script order.
function handler.compose(api)
    local properties = paint_base(api)
    local builder = api.builder
    local x = math.floor(builder.width / 2) - 5 + api:roll(11)
    local y = math.floor(builder.height / 2) - 5 + api:roll(11)
    local chamber = api:place_tag_at("tar_grunt_ereshkigal", x, y)

    for _, record in ipairs(properties) do
        chamber.records[#chamber.records + 1] = record
    end

    local big_loot = api:place_maps("tar_grunt_big_loot", 1)

    if big_loot ~= 1 then
        error("Failed to place Tartarus big loot chamber")
    end

    api:place_maps("tar_grunt_small_loot", 3)
    api:place_maps("tar_grunt_decor", 15)
    api:place_maps("tar_grunt_mons1", 10)
    api:place_maps("tar_grunt_mons2", 10)
end

return handler
