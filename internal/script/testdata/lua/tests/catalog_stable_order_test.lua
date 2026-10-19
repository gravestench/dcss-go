-- Catalog traversal uses stable IDs so renaming a file does not reshuffle
-- weighted choices. Multiple rows within one definition retain their local
-- order without adding a position shared with other content files.
local categories = require("constants.catalog")
local harness = require("tests.harness")
local catalog = require("policy.catalog")

local test = {}

-- Compare catalog traversal with stable registered IDs, so filesystem load
-- order cannot alter seeded consumers that iterate definitions.
local function check_category(category)
    local definitions = catalog.all(category)
    local sorted = register.ids(category)

    harness.equal(#definitions, #sorted, category .. " definition count")

    for index, id in ipairs(sorted) do
        harness.equal(definitions[index].id, id,
            category .. " traverses IDs in stable order")

        local definition = register.get(category, id)

        harness.falsy(definition.source_order,
            category .. " definition does not need a catalog index")
    end
end

-- Check representative content categories with many files, where a new mod
-- path could otherwise reorder definitions without changing their IDs.
function test.run()
    check_category(categories.MONSTERS)
    check_category(categories.ITEMS)
    check_category(categories.SPELLS)
    check_category(categories.BRANCHES)
    check_category(categories.MUTATIONS)
end

return test
