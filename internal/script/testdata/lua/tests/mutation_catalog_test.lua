local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local mutations = require("ids.mutations")
local harness = require("tests.harness")

local test = {}

function test.run()
    local ids = register.ids(categories.MUTATIONS)

    harness.equal(#ids, 196, "pinned mutation definitions")

    local robust = catalog.get(categories.MUTATIONS, mutations.MUT_ROBUST)
    local carnivorous = register.get(categories.MUTATIONS,
        mutations.MUT_CARNIVOROUS)

    harness.equal(robust.status, "active", "Robust status")
    harness.equal(robust.weight, 5, "Robust source weight")
    harness.equal(robust.max_level, 3, "Robust source levels")
    harness.equal(carnivorous.status, "removed", "old save mutation")

    local legacy_torment = register.get(categories.MUTATIONS,
        mutations.MUT_STOCHASTIC_TORMENT_RESISTANCE)

    harness.equal(legacy_torment.status, "removed",
        "legacy stochastic torment mutation is unavailable in new saves")

    local active = pcall(catalog.get, categories.MUTATIONS,
        mutations.MUT_CARNIVOROUS)

    harness.equal(active, false, "removed mutation is unavailable")

    local legacy_active = pcall(catalog.get, categories.MUTATIONS,
        mutations.MUT_STOCHASTIC_TORMENT_RESISTANCE)

    harness.equal(legacy_active, false,
        "historical torment mutation cannot enter a new Go save")

    local origin = register.origin(categories.MUTATIONS,
        mutations.MUT_ROBUST)

    harness.truthy(origin:match("^content/mutations/"),
        "mutation origin")
end

return test
