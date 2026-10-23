-- A sparse mod cannot replace a feature owner by adding a second path.
local harness = require("tests.harness")
local handlers = require("policy.world.portals.catalog")
local terrain = require("constants.terrain")

local test = {}

-- Only exact-path replacement may change an existing portal handler.
function test.run()
    local okay, reason = pcall(handlers.owner,
        terrain.DNGN_ENTER_BAZAAR)

    harness.falsy(okay, "duplicate feature owner rejected")
    harness.truthy(tostring(reason):find(
        "duplicate or invalid temporary portal feature", 1, true),
        "duplicate rejection identifies the feature contract")
end

return test
