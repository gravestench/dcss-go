-- The committed overflow family must include every source NAME as an
-- effective DES file. The ordinary extra-vault catalog excludes this family
-- until its scheduled god assignment chooses a specific map.
local catalog = require("policy.generation.altar.catalog")
local harness = require("tests.harness")
local ordinary = require("policy.generation.vaults.catalog")

local test = {}

-- Parsing the full family catches broken directives and missing named hooks
-- at startup rather than only when a rare altar map is selected.
function test.run()
    local ids = catalog.ids()

    harness.equal(#ids, 232,
        "all source overflow altar definitions are committed")

    local previous = ""

    for _, id in ipairs(ids) do
        harness.truthy(id > previous,
            "overflow IDs are unique and sorted")
        harness.equal(catalog.get(id).id, id,
            "the catalog returns its parsed source definition")
        previous = id
    end

    local ashenzari = catalog.get("ashenzari_altar_1")

    harness.truthy(ashenzari.tags.temple_overflow_ashenzari,
        "specialized god tags survive the source import")
    harness.truthy(#ashenzari.rows > 0,
        "source altar geometry remains in DES MAP rows")

    local selectable = pcall(ordinary.get, ashenzari.id)

    harness.falsy(selectable,
        "unported overflow maps cannot enter ordinary vault selection")
end

return test
