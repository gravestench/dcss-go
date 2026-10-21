-- The nine pinned Snake:$ maps are committed runtime content. This test
-- catches accidental MAP edits without reading the C++ tree at build time.
local categories = require("constants.catalog")
local harness = require("tests.harness")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

local source_maps = {
    snake_hunt = {
        height = 37,
        width = 44,
        checksum = 848184257,
    },
    snake_pit = {
        height = 34,
        width = 40,
        checksum = 3392428605,
    },
    minmay_snake_end_coiled = {
        height = 43,
        width = 42,
        checksum = 995418759,
    },
    snake_pit_salamanders_mu = {
        height = 37,
        width = 34,
        checksum = 935719075,
    },
    grunt_snake_rune_spirals = {
        height = 22,
        width = 48,
        checksum = 2132067800,
    },
    grunt_snake_rune_pools = {
        height = 29,
        width = 29,
        checksum = 2092576307,
    },
    grunt_snake_rune_serpentine_throne = {
        height = 35,
        width = 17,
        checksum = 4195426505,
    },
    johnstein_snake_rune_scales = {
        height = 25,
        width = 40,
        checksum = 3050671166,
    },
    hellmonk_snake_rune_quicksilver_temple = {
        height = 31,
        width = 33,
        checksum = 1627861365,
    },
}

-- A small rolling checksum is sufficient to detect drift in short MAP rows.
-- The largest intermediate product fits exactly in Lua's number precision.
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

-- Each source name should resolve through the production DES catalog.
function test.run()
    vaults.load()

    local count = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if definition.family == "snake_end" then
            local expected = source_maps[id]
            local width = 0

            harness.truthy(expected, "unexpected Snake end map " .. id)
            harness.equal(#definition.rows, expected.height, id .. " height")

            for _, row in ipairs(definition.rows) do
                width = math.max(width, #row)
            end

            harness.equal(width, expected.width, id .. " width")
            harness.equal(map_checksum(definition.rows), expected.checksum,
                id .. " source MAP checksum")
            harness.equal(#definition.places, 1, id .. " explicit PLACE")
            count = count + 1
        end
    end

    harness.equal(count, 9, "all nine source Snake end maps")
end

return test
