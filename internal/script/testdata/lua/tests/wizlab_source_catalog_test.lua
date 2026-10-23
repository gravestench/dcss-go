-- The committed DES corpus is the runtime source of Wizard Lab geometry.
-- This checks every source NAME and every MAP byte against the pinned
-- crawl-ref corpus without reading C++ files during normal builds.
local des = require("policy.generation.vaults.des")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local weights = require("policy.generation.vaults.weight")

local test = {}

-- A corpus digest catches dropped or edited rows even when the map still
-- parses and has a reachable entrance. Sort by NAME, never file path.
local function map_digest(maps)
    local authored = {}

    for _, map in ipairs(maps) do
        authored[#authored + 1] = map.id .. ":" ..
            table.concat(map.rows, "\n")
    end

    table.sort(authored)

    local hash = 0

    for byte in (table.concat(authored, "\n")):gmatch(".") do
        hash = (hash * 31 + string.byte(byte)) % 4294967296
    end

    return hash
end

-- Both groups are discovered through the effective VFS, so an overlay
-- changes the map that the game and this test actually consume.
local function maps_in(directory)
    local maps = {}

    for _, path in ipairs(mod.paths(directory, ".des")) do
        local map = des.parse(path, mod.read(path))

        hooks.validate(map)
        maps[#maps + 1] = map
    end

    return maps
end

-- Source Lua was left at named hook positions. A map that keeps its MAP
-- but drops its hooks would render correctly while losing its behavior.
local function assert_hook_sites(maps)
    for _, map in ipairs(maps) do
        local found = false

        for _, operation in ipairs(map.operations) do
            if operation.kind == directives.HOOK_RUN then
                found = true
            end
        end

        harness.truthy(found, map.id .. " lost its source-position hook")
    end
end

-- The source contains eleven arches and fifteen complete rooms. The
-- one zero-weight Vaults room remains available elsewhere by ID.
function test.run()
    local entrances = maps_in("vaults/wizlab_entry")
    local destinations = maps_in("vaults/wizlab")
    local all = {}

    harness.equal(#entrances, 11, "Wizard Lab source entrances")
    harness.equal(#destinations, 15, "Wizard Lab source rooms")
    assert_hook_sites(entrances)
    assert_hook_sites(destinations)

    for _, map in ipairs(entrances) do
        all[#all + 1] = map
    end

    for _, map in ipairs(destinations) do
        all[#all + 1] = map
    end

    harness.equal(map_digest(all), 2830982570,
        "all 26 Wizard Lab source MAP layouts")

    for _, map in ipairs(entrances) do
        local vaults_weight = weights.for_branch(map,
            branches.BRANCH_VAULTS, 1, 5, 20)

        if map.id == "mu_enter_wizlab_7" then
            harness.equal(vaults_weight, 0,
                "source seventh arch has no Vaults weight")
        else
            harness.truthy(vaults_weight > 0,
                map.id .. " remains a Vaults room candidate")
        end
    end
end

return test
