-- Generation metadata covers every base item and unique artefact; the dummy
-- stays excluded, and a non-plus amulet rejects an added plus property.

local catalog = require("policy.catalog")
local harness = require("tests.harness")
local artefact_ids = require("ids.artefacts")
local validation = require("policy.item_generation.validate")

local test = {}

-- Walk the committed item and artefact catalogs so unsupported generation
-- modes are reported before one is encountered during a live floor build.
function test.run()
    local items = catalog.all("items")
    local artefacts = catalog.all("artefacts")
    local modes = {
        random = true,
        forced = true,
        none = true,
    }

    harness.equal(#items, 368, "base item count")
    harness.equal(#artefacts, 127, "unique artefact count")

    for _, definition in ipairs(items) do
        harness.truthy(definition.generation, definition.id .. " generation")
        harness.truthy(modes[definition.generation.mode],
            definition.id .. " generation mode")
    end

    -- The dummy is looked up by ID because catalog traversal now sorts IDs.
    local dummy = catalog.get("artefacts", artefact_ids.UNRAND_DUMMY1)

    harness.equal(dummy.generation.mode, "none", "dummy excluded")

    for _, definition in ipairs(artefacts) do
        harness.truthy(definition.generation,
            definition.id .. " generation")
        harness.truthy(modes[definition.generation.mode],
            definition.id .. " generation mode")
    end

    local original = catalog.get("artefacts", artefact_ids.UNRAND_CEKUGOB)
    local changed = {}

    for key, value in pairs(original) do
        changed[key] = value
    end

    changed.properties = {
        plus = 3,
    }

    local okay, detail = pcall(validation.artefact, changed)

    harness.falsy(okay, "amulet cannot define a plus")
    harness.truthy(tostring(detail):find("non-plus jewellery", 1, true),
        "artefact property failure explains the base mismatch")
end

return test
