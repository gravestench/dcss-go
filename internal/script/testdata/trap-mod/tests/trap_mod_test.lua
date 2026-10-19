-- Mod-added trap is discovered.

local categories = require("constants.catalog")
local harness = require("tests.harness")
local ids = require("ids.custom_traps")
local trap_catalog = require("policy.traps.catalog")

local test = {}

-- Find the new trap through registration, validate it, and read its content
-- to prove discovery and schema checks accept the same mod definition.
function test.run()
    local definitions = register.ids(categories.TRAPS)
    local found = false

    for _, id in ipairs(definitions) do
        found = found or id == ids.TRAP_TEST_CUSTOM
    end

    harness.truthy(found, "mod-added trap is discovered")
    trap_catalog.validate()

    local definition = register.get(categories.TRAPS, ids.TRAP_TEST_CUSTOM)

    harness.equal(definition.name, "custom echo trap", "mod trap content")
end

return test
