-- Xom's source event list is a closed baseline. Mods may add events, but
-- every built-in event must remain resolvable through the effective catalog.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local events = require("ids.xom_events")
local harness = require("tests.harness")

local test = {}

-- Import the production IDs so this test cannot silently maintain a second
-- event list that drifts away from selection and effect dispatch.
local function check_source_events()
    local seen = {}
    local count = 0

    for key, id in pairs(events) do
        if key ~= "DID_NOTHING" then
            local definition = catalog.get(categories.XOM_EVENTS, id)
            local effect = require(definition.effect_module)

            harness.equal(definition.id, id)
            harness.truthy(definition.side == "good" or
                definition.side == "bad", "invalid Xom action side")
            harness.truthy(type(effect.apply) == "function",
                "Xom action lacks its effect")
            harness.truthy(not seen[id], "duplicate Xom event ID")

            seen[id] = true
            count = count + 1
        end
    end

    harness.equal(count, 42)
end

-- The test invokes the same catalog and modules used by live Xom actions.
function test.run()
    check_source_events()
end

return test
