-- The committed DES corpus is the runtime source of Gauntlet geometry.
-- This test catches a missing or edited source map without requiring the
-- C++ checkout during normal builds. The digest uses stable NAME order.
local des = require("policy.generation.vaults.des")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")

local test = {}

-- Parse through the production DES loader, so malformed source hooks
-- fail here before a rare Gauntlet layout is selected during play.
local function maps_in(directory)
    local maps = {}

    for _, path in ipairs(mod.paths(directory, ".des")) do
        local map = des.parse(path, mod.read(path))

        hooks.validate(map)
        maps[#maps + 1] = map
    end

    return maps
end

-- A simple fixed-width rolling digest is reproducible in this Lua VM and
-- can be calculated independently from the pinned source MAP blocks.
local function digest(maps)
    local parts = {}

    for _, map in ipairs(maps) do
        parts[#parts + 1] = map.id .. ":" ..
            table.concat(map.rows, "\n")
    end

    table.sort(parts)

    local hash = 0

    for byte in table.concat(parts, "\n"):gmatch(".") do
        hash = (hash * 31 + string.byte(byte)) % 4294967296
    end

    return hash
end

-- The four directories reflect source roles, not a loader ordering rule.
-- Arena and exit maps join the parent only through their source tags.
function test.run()
    local groups = {
        { directory = "vaults/gauntlet_entry", count = 1 },
        { directory = "vaults/gauntlet_arena", count = 43 },
        { directory = "vaults/gauntlet_exit", count = 6 },
        { directory = "vaults/gauntlet", count = 10 },
    }
    local maps = {}

    for _, group in ipairs(groups) do
        local definitions = maps_in(group.directory)

        harness.equal(#definitions, group.count,
            group.directory .. " source count")

        for _, definition in ipairs(definitions) do
            maps[#maps + 1] = definition
        end
    end

    harness.equal(#maps, 60, "complete Gauntlet source corpus")
    harness.equal(digest(maps), 199505225,
        "all 60 Gauntlet source MAP layouts")
end

return test
