-- Theory of operation: the base Shoals layout owns a dense elevation map,
-- then DES vaults paint over its terrain. Apply the painted cells and their
-- keyed FHEIGHT and no_tide declarations to that same map before Go stores
-- it. Otherwise the tide would read the old island height under a rune hut.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local heights = require("constants.shoals_heights")
local properties = require("constants.vault_properties")

local shoals_heights = {}

-- A vault floor starts at sea level; authored shallow and deep water keep
-- their water bands, and walls are above even the highest ordinary tide.
local function terrain_height(glyph)
    if glyph == "w" then
        return heights.DEEP
    end

    if glyph == "W" then
        return heights.SHALLOW
    end

    if glyph == "#" then
        return heights.ROCK
    end

    return heights.FLOOR
end

-- Map placement records already have transformed level coordinates. Set
-- explicit FHEIGHT after terrain defaults so the source directive wins.
local function apply_properties(heightmap, records)
    local immune = {}

    for _, record in ipairs(records) do
        if record.kind == effects.PROPERTY then
            local row = heightmap[record.y + 1]

            if not row or row[record.x + 1] == nil then
                error("Shoals height property lies outside its level")
            end

            if record.directive == directives.FHEIGHT then
                local height = tonumber(record.identity)

                if not height or height % 1 ~= 0 then
                    error("Shoals FHEIGHT must be an integer")
                end

                row[record.x + 1] = height
            elseif record.directive == directives.KPROP and
                record.identity == properties.NO_TIDE then
                immune[#immune + 1] = record
            end
        end
    end

    -- Immunity wins regardless of the order of the two DES declarations.
    for _, record in ipairs(immune) do
        heightmap[record.y + 1][record.x + 1] = heights.TIDE_IMMUNE
    end
end

-- The returned map is generation-local, so updating it in place cannot
-- change another floor or make module load order affect a game seed.
function shoals_heights.overlay(floor)
    if floor.branch_id ~= branches.BRANCH_SHOALS then
        return floor.layout.heightmap
    end

    local heightmap = floor.layout.heightmap

    -- An authored mod layout may supply terrain without a procedural
    -- height field. Derive its baseline before applying keyed vault rules.
    if not heightmap then
        heightmap = {}

        for y = 0, floor.layout.builder.height - 1 do
            local row = {}

            for x = 0, floor.layout.builder.width - 1 do
                row[x + 1] = terrain_height(
                    floor.layout.builder:cell(x, y))
            end

            heightmap[y + 1] = row
        end
    end

    for _, map in ipairs(floor.extra or {}) do
        for _, point in ipairs(map.occupied or {}) do
            local glyph = floor.layout.builder:cell(point.x, point.y)

            heightmap[point.y + 1][point.x + 1] = terrain_height(glyph)
        end
    end

    apply_properties(heightmap, floor.records or {})

    return heightmap
end

return shoals_heights
