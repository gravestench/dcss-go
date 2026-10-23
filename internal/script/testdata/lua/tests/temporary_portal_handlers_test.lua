-- The effective Lua catalog owns temporary portal routing. This test reads
-- production terrain IDs and the real layered module paths, so a new portal
-- handler need not be added to a second test-side registry.
local harness = require("tests.harness")
local handlers = require("policy.world.portals.catalog")
local terrain = require("constants.terrain")
local effects = require("constants.vault_effects")
local des = require("policy.generation.vaults.des")

local test = {}

-- Every live temporary feature has exactly one handler; ordinary terrain
-- stays with the normal stair and movement owners.
function test.run()
    local owners = {
        [terrain.DNGN_ENTER_BAZAAR] = "bazaar",
        [terrain.DNGN_EXIT_BAZAAR] = "bazaar",
        [terrain.DNGN_ENTER_SEWER] = "sewer",
        [terrain.DNGN_EXIT_SEWER] = "sewer",
        [terrain.DNGN_ENTER_OSSUARY] = "ossuary",
        [terrain.DNGN_EXIT_OSSUARY] = "ossuary",
        [terrain.DNGN_ENTER_BAILEY] = "bailey",
        [terrain.DNGN_EXIT_BAILEY] = "bailey",
        [terrain.DNGN_ENTER_ICE_CAVE] = "ice_cave",
        [terrain.DNGN_EXIT_ICE_CAVE] = "ice_cave",
        [terrain.DNGN_ENTER_VOLCANO] = "volcano",
        [terrain.DNGN_EXIT_VOLCANO] = "volcano",
        [terrain.DNGN_ENTER_TROVE] = "trove",
        [terrain.DNGN_EXIT_TROVE] = "trove",
    }

    for feature, owner in pairs(owners) do
        harness.equal(handlers.owner(feature), owner,
            "feature belongs to one temporary portal")
    end

    harness.equal(handlers.owner(terrain.DNGN_FLOOR), nil,
        "ordinary floor has no temporary portal owner")

    local path = mod.paths("vaults/bzr_entry", ".des")[1]
    local source = des.parse(path, mod.read(path))
    local marker = {
        kind = effects.MARKER,
        identity = "lua:one_way_stair",
        source_id = source.id,
    }
    local owner = handlers.for_marker(marker)

    harness.equal(owner.id, "bazaar",
        "marker owner is resolved before any gate is created")
end

return test
