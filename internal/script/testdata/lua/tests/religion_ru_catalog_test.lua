-- Every source sacrifice is a discoverable definition. Adding another
-- Lua file should not require a central Go switch or affect source IDs.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local harness = require("tests.harness")
local ids = require("ids.ru_sacrifices")

local test = {}

-- Compare the committed source set with the effective catalog by ID.
-- This also catches a missing file before offers try to select it.
function test.run()
    local registered = catalog.all(categories.RU_SACRIFICES)
    local expected = {
        [ids.PURITY] = true,
        [ids.WORDS] = true,
        [ids.DRINK] = true,
        [ids.ESSENCE] = true,
        [ids.HEALTH] = true,
        [ids.STEALTH] = true,
        [ids.ARTIFICE] = true,
        [ids.LOVE] = true,
        [ids.COURAGE] = true,
        [ids.ARCANA] = true,
        [ids.NIMBLENESS] = true,
        [ids.DURABILITY] = true,
        [ids.HAND] = true,
        [ids.EXPERIENCE] = true,
        [ids.SKILL] = true,
        [ids.EYE] = true,
        [ids.RESISTANCE] = true,
    }

    harness.equal(#registered, 17)

    for _, definition in ipairs(registered) do
        harness.truthy(expected[definition.id],
            "unexpected Ru sacrifice " .. definition.id)
        harness.truthy(definition.name ~= "")
        harness.truthy(definition.base_piety >= 0)
    end
end

return test
