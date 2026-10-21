-- Swamp:4 uses eleven committed source MAPs. These expectations catch
-- accidental geometry edits without reading the C++ source during builds.
local categories = require("constants.catalog")
local harness = require("tests.harness")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

local source_maps = {
    swamp = {
        height = 17,
        width = 17,
        checksum = 3738986905,
    },
    swamp_alternative = {
        height = 16,
        width = 22,
        checksum = 492820125,
    },
    swamp_old_school = {
        height = 28,
        width = 38,
        checksum = 1508034926,
    },
    swamp_fiery = {
        height = 17,
        width = 29,
        checksum = 4131124046,
    },
    swamp_icy = {
        height = 32,
        width = 26,
        checksum = 2535092709,
    },
    swamp_pestilence = {
        height = 28,
        width = 25,
        checksum = 4282511119,
    },
    swamp_vile = {
        height = 30,
        width = 33,
        checksum = 2920108655,
    },
    grunt_swamp_rune_castle = {
        height = 23,
        width = 23,
        checksum = 2747456352,
    },
    swamp_basic_johnstein = {
        height = 20,
        width = 28,
        checksum = 79502309,
    },
    byrel_swamp_growth_death_and_undeath = {
        height = 21,
        width = 28,
        checksum = 1517598489,
    },
    nzn_swamp_witches_coven = {
        height = 27,
        width = 27,
        checksum = 2573734693,
    },
}

-- A short rolling checksum pins source bytes while remaining readable Lua.
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

-- Read definitions through the same effective catalog generation uses.
function test.run()
    vaults.load()

    local count = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if definition.family == "swamp_end" then
            local expected = source_maps[id]
            local width = 0

            harness.truthy(expected, "unexpected Swamp end map " .. id)
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

    harness.equal(count, 11, "all eleven source Swamp end maps")
end

return test
