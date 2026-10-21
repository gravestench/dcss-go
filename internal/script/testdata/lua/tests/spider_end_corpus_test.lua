-- Spider:4 uses nine committed source MAPs. These expectations catch
-- accidental geometry edits without reading the C++ source during builds.
local categories = require("constants.catalog")
local harness = require("tests.harness")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

local source_maps = {
    floodkiller_spider_rune_tomb = {
        height = 33,
        width = 39,
        checksum = 910815953,
    },
    grunt_spider_rune_circles = {
        height = 19,
        width = 38,
        checksum = 57014978,
    },
    grunt_spider_rune_island = {
        height = 27,
        width = 34,
        checksum = 2649253632,
    },
    grunt_spider_rune_parallel = {
        height = 30,
        width = 50,
        checksum = 140170388,
    },
    guppyfry_spider_rune = {
        height = 26,
        width = 46,
        checksum = 1249229046,
    },
    hellmonk_spider_rune_bug_friends = {
        height = 24,
        width = 30,
        checksum = 847700869,
    },
    hellmonk_spider_rune_endless_swarm = {
        height = 41,
        width = 36,
        checksum = 1293404057,
    },
    johnstein_spider_rune_arachne_lair = {
        height = 36,
        width = 27,
        checksum = 2556929903,
    },
    spider_rune_water = {
        height = 26,
        width = 47,
        checksum = 1526094351,
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

        if definition.family == "spider_end" then
            local expected = source_maps[id]
            local width = 0

            harness.truthy(expected, "unexpected Spider end map " .. id)
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

    harness.equal(count, 9, "all nine source Spider end maps")
end

return test
