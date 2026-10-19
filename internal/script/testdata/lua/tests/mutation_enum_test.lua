
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local enum = require("data.mutation_enum")
local mutations = require("ids.mutations")
local harness = require("tests.harness")

local test = {}

-- Committed mutation definition appears in the source enum.
function test.run()
    harness.equal(#enum, 196, "pinned tag-34 mutation enum size")
    harness.equal(enum[1], mutations.MUT_ANTENNAE,
        "mutation enum begins with Antennae")
    harness.equal(enum[#enum], mutations.MUT_EXPLORE_REGEN,
        "mutation enum ends with Explore Regen")

    local seen = {}

    for _, mutation_id in ipairs(enum) do
        harness.falsy(seen[mutation_id],
            "mutation enum IDs are unique")

        seen[mutation_id] = true
        harness.truthy(register.get(categories.MUTATIONS, mutation_id),
            "mutation enum ID has a committed definition")
    end

    for _, definition in ipairs(catalog.all(categories.MUTATIONS)) do
        harness.truthy(seen[definition.id],
            "committed mutation definition appears in the source enum")
    end
end

return test
