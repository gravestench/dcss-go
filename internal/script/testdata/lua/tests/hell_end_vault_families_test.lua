-- Every Hell ending remains a selectable source family after layered VFS
-- discovery. Helpers are present for composition but never compete with
-- their controller's mandatory PLACE selection.
local categories = require("constants.catalog")
local families = require("constants.vault_families")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

local expected = {
    [families.DIS_END] = 15,
    [families.GEH_END] = 7,
    [families.COC_END] = 8,
    [families.TAR_END] = 21,
}

-- The catalog has already chosen the winning file from each mod layer.
-- Validate its hook contract and primary/helper split on that effective
-- definition, not on a separate list of bundled filenames.
function test.run()
    local counts = {}
    local primaries = {}

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if expected[definition.family] then
            counts[definition.family] = (counts[definition.family] or 0) + 1
            hooks.validate(definition)

            if #definition.places > 0 then
                primaries[definition.family] =
                    (primaries[definition.family] or 0) + 1
            end
        end
    end

    for family, count in pairs(expected) do
        harness.equal(counts[family], count,
            family .. " source definition count")
        harness.truthy((primaries[family] or 0) > 0,
            family .. " has no primary controller")
        if family ~= families.GEH_END then
            harness.truthy(primaries[family] < count,
                family .. " helpers entered primary selection")
        end
    end
end

return test
