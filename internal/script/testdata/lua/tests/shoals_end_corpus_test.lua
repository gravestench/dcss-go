-- Pin all 26 committed Shoals finale definitions, including the four
-- mapless source controllers. These checksums protect authored MAP bytes;
-- generation and mods read the same effective DES catalog as this test.
local categories = require("constants.catalog")
local harness = require("tests.harness")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

local source_maps = {
    shoal_ilsuiw = { height = 7, width = 7, checksum = 2704565625 },
    shoalhut = { height = 7, width = 7, checksum = 666574314 },
    shoalhut_rune = { height = 7, width = 7, checksum = 1788816389 },
    shoals_end_grunt_garden = { height = 0, width = 0, checksum = 0 },
    shoals_end_grunt_ice = { height = 0, width = 0, checksum = 0 },
    shoals_end_hangedman = { height = 0, width = 0, checksum = 0 },
    shoals_end_hellmonk_lost_city = {
        height = 49,
        width = 62,
        checksum = 1376716694,
    },
    shoals_end_hellmonk_storm_palace = {
        height = 48,
        width = 48,
        checksum = 3138249121,
    },
    shoals_end_simple = { height = 0, width = 0, checksum = 0 },
    shoals_garden = { height = 11, width = 11, checksum = 48944778 },
    shoals_garden_rune = { height = 11, width = 11, checksum = 4092671895 },
    shoals_iceberg = { height = 13, width = 13, checksum = 3559823150 },
    shoals_iceberg_rune = { height = 13, width = 13, checksum = 1556872367 },
    shoals_ilsuiw_alternative = {
        height = 11,
        width = 11,
        checksum = 941704051,
    },
    shoals_ilsuiw_ice = { height = 13, width = 13, checksum = 3538498829 },
    shoals_rune_alternative = {
        height = 11,
        width = 11,
        checksum = 1063774042,
    },
    shoals_rune_alternative_decoy = {
        height = 11,
        width = 11,
        checksum = 2984958071,
    },
    storm_palace_center_circular = {
        height = 22,
        width = 22,
        checksum = 1113839284,
    },
    storm_palace_center_ruins = {
        height = 22,
        width = 22,
        checksum = 1229722702,
    },
    storm_palace_center_square = {
        height = 22,
        width = 22,
        checksum = 1070162779,
    },
    storm_palace_corner_altar = {
        height = 11,
        width = 11,
        checksum = 7100894,
    },
    storm_palace_corner_blocked = {
        height = 11,
        width = 11,
        checksum = 958331837,
    },
    storm_palace_corner_grid = {
        height = 11,
        width = 11,
        checksum = 1453420829,
    },
    storm_palace_corner_narrow = {
        height = 11,
        width = 11,
        checksum = 2571547169,
    },
    storm_palace_corner_pillars = {
        height = 11,
        width = 11,
        checksum = 1041239993,
    },
    storm_palace_corner_reverse_hut = {
        height = 11,
        width = 11,
        checksum = 1659458549,
    },
}

-- Short arithmetic checksum makes accidental whitespace changes visible
-- without duplicating any MAP or DES schema inside the test fixture.
local function map_checksum(rows)
    local checksum = 0

    for _, row in ipairs(rows) do
        for index = 1, #row do
            checksum = (checksum * 31 + row:byte(index)) % 4294967296
        end

        checksum = (checksum * 31 + 10) % 4294967296
    end

    return checksum
end

-- Every source definition must exist exactly once under the Shoals family.
function test.run()
    vaults.load()

    local count = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if definition.family == "shoals_end" then
            local expected = source_maps[id]
            local width = 0

            harness.truthy(expected, "unexpected Shoals finale " .. id)
            harness.equal(#definition.rows, expected.height, id .. " height")

            for _, row in ipairs(definition.rows) do
                width = math.max(width, #row)
            end

            harness.equal(width, expected.width, id .. " width")
            harness.equal(map_checksum(definition.rows), expected.checksum,
                id .. " source MAP checksum")

            count = count + 1
        end
    end

    harness.equal(count, 26, "all source Shoals finale definitions")
end

return test
