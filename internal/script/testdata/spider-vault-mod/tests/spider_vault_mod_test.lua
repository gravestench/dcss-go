-- A sparse mod adds Spider definitions through ordinary layered paths.
-- Neither a Go roster nor a second selection policy lists these names.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local entry = require("policy.generation.vaults.branch_entry")
local families = require("constants.vault_families")
local harness = require("tests.harness")
local regular = require("policy.generation.vaults.regular")
local tags = require("constants.vault_tags")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- New files enter the same effective pools as bundled definitions.
function test.run()
    local entrances = entry.candidates(branches.BRANCH_SPIDER)
    local found_entry = false
    local found_chamber = false

    harness.equal(#entrances, 12, "mod extends Spider entrance pool")

    for _, candidate in ipairs(entrances) do
        if candidate.definition.id == "modded_spider_gate" then
            found_entry = true
            harness.equal(candidate.weight, 7,
                "new Spider entrance keeps its weight")
        end
    end

    local context = {
        branch_id = branches.BRANCH_SPIDER,
        depth = 2,
        branch_bottom = 4,
        absolute_depth = 16,
        branch_vault_family = families.SPIDER,
    }

    for _, candidate in ipairs(regular.candidates(context)) do
        if candidate.definition.id == "modded_spider_chamber" then
            found_chamber = true
            harness.equal(candidate.weight, 7,
                "new ordinary Spider map keeps its weight")
        end
    end

    local helper = register.get(categories.VAULTS,
        "modded_spider_jumping_child")

    harness.truthy(found_entry, "new effective entrance is selectable")
    harness.truthy(found_chamber, "new ordinary map is selectable")
    harness.truthy(helper.tags[tags.SPIDER_JUMPING_CHILD],
        "new jumping helper joins the source parent tag")
    harness.equal(vaults.get(helper.id).rows[2], ".1...",
        "helper retains its source-style MAP")
end

return test
