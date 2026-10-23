-- The committed Crypt DES files are the runtime source of map geometry.
-- A stable digest catches geometry drift without requiring a C++ checkout.
local des = require("policy.generation.vaults.des")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")

local test = {}

-- Read every effective file through the production parser and hook loader.
-- This also proves that a sparse mod could replace any one named file.
local function maps_in(directory)
    local maps = {}

    for _, path in ipairs(mod.paths(directory, ".des")) do
        local map = des.parse(path, mod.read(path))

        hooks.validate(map)
        maps[#maps + 1] = map
    end

    return maps
end

-- NAME sorting makes the result independent of filesystem discovery order.
local function digest(maps)
    local parts = {}

    for _, map in ipairs(maps) do
        parts[#parts + 1] = map.id .. ":" .. table.concat(map.rows, "\n")
    end

    table.sort(parts)

    local hash = 0

    for byte in table.concat(parts, "\n"):gmatch(".") do
        hash = (hash * 31 + string.byte(byte)) % 4294967296
    end

    return hash
end

-- The three directories encode entry, ordinary, and required end roles.
-- Arrival vaults live with ordinary Crypt maps because they are optional.
function test.run()
    local groups = {
        {
            directory = "vaults/crypt_entry",
            count = 13,
        },
        {
            directory = "vaults/crypt",
            count = 38,
        },
        {
            directory = "vaults/crypt_end",
            count = 8,
        },
    }
    local maps = {}

    for _, group in ipairs(groups) do
        local definitions = maps_in(group.directory)

        harness.equal(
            #definitions,
            group.count,
            group.directory .. " source count"
        )

        for _, definition in ipairs(definitions) do
            maps[#maps + 1] = definition
        end
    end

    harness.equal(#maps, 59, "complete Crypt source corpus")
    harness.equal(digest(maps), 2312645629, "all 59 Crypt source MAP layouts")
end

return test
