-- Treasure Trove maps are committed as individually replaceable DES files.
-- Compare their MAP corpus with the pinned source without reading C++ at
-- runtime, so one missing room or altered row fails before a rare draw.
local des = require("policy.generation.vaults.des")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")

local test = {}

-- Name-sorted rows make the digest independent of VFS enumeration order.
local function map_digest(paths)
    local maps = {}

    for _, path in ipairs(paths) do
        local map = des.parse(path, mod.read(path))

        maps[#maps + 1] = map.id .. ":" ..
            table.concat(map.rows, "\n")
    end

    table.sort(maps)

    local hash = 0

    for byte in table.concat(maps, "\n"):gmatch(".") do
        hash = (hash * 31 + string.byte(byte)) % 4294967296
    end

    return hash
end

-- Every source NAME must be loadable by the same hook validator used by
-- play; destination maps remain whole-floor vaults with authored loot.
function test.run()
    local entries = mod.paths("vaults/trove_entry", ".des")
    local destinations = mod.paths("vaults/trove", ".des")
    local paths = {}

    harness.equal(#entries, 14, "source Trove entrances")
    harness.equal(#destinations, 21, "source Trove rooms")

    for _, path in ipairs(entries) do
        local map = des.parse(path, mod.read(path))

        harness.truthy(map.tags.uniq_trove and
            map.tags.chance_trove, map.id .. " lacks Trove tags")
        harness.equal(map.chances[1].chance, 500,
            map.id .. " source entry chance")
        hooks.validate(map)
        paths[#paths + 1] = path
    end

    for _, path in ipairs(destinations) do
        local map = des.parse(path, mod.read(path))

        harness.equal(map.orientation, "encompass",
            map.id .. " whole-floor orientation")
        hooks.validate(map)
        paths[#paths + 1] = path
    end

    harness.equal(map_digest(paths), 3870832095,
        "authored Trove MAP corpus")
end

return test
