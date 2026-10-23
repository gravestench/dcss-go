-- Tomb's effective DES files are the only production source of its geometry.
-- Count and parse every active map so a forgotten helper cannot silently
-- remove one of the source's possible routes through the branch.
local des = require("policy.generation.vaults.des")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")

local test = {}

-- Use the production VFS and parser; tests never redeclare map schemas.
local function count_maps(directory)
    local count = 0
    local maps = {}

    for _, path in ipairs(mod.paths(directory, ".des")) do
        local map = des.parse(path, mod.read(path))

        hooks.validate(map)
        count = count + 1
        maps[#maps + 1] = map
    end

    return count, maps
end

-- This digest covers map NAME and every MAP row, not extracted importer
-- metadata. It catches geometry drift without requiring the C++ checkout.
local function geometry_digest(maps)
    local parts = {}

    for _, map in ipairs(maps) do
        parts[#parts + 1] = map.id .. ":" ..
            table.concat(map.rows, "\n")
    end

    table.sort(parts)

    local digest = 0

    for byte in table.concat(parts, "\n"):gmatch(".") do
        digest = (digest * 31 + string.byte(byte)) % 4294967296
    end

    return digest
end

-- Each family corresponds to one source role, including the Crypt-side
-- entrance pool and four independent Tomb helper pools.
function test.run()
    local groups = {
        {
            directory = "vaults/tomb_entry",
            count = 10,
        },
        {
            directory = "vaults/tomb_1",
            count = 1,
        },
        {
            directory = "vaults/tomb_1_centre",
            count = 4,
        },
        {
            directory = "vaults/tomb_1_hall_stairs",
            count = 5,
        },
        {
            directory = "vaults/tomb_2",
            count = 1,
        },
        {
            directory = "vaults/tomb_2_ambush",
            count = 4,
        },
        {
            directory = "vaults/tomb_3",
            count = 1,
        },
        {
            directory = "vaults/tomb_3_rune",
            count = 5,
        },
    }
    local total = 0
    local maps = {}

    for _, group in ipairs(groups) do
        local count, definitions = count_maps(group.directory)

        harness.equal(count, group.count, group.directory .. " source count")
        total = total + count

        for _, definition in ipairs(definitions) do
            maps[#maps + 1] = definition
        end
    end

    harness.equal(total, 31, "complete active Tomb corpus")
    harness.equal(geometry_digest(maps), 220260090,
        "all 31 active Tomb source MAP layouts")
end

return test
