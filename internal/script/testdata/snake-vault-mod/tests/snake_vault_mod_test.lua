-- A sparse mod can extend both Snake source pools with only DES files.
local branches = require("ids.branches")
local entry = require("policy.generation.vaults.branch_entry")
local families = require("constants.vault_families")
local harness = require("tests.harness")
local regular = require("policy.generation.vaults.regular")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Effective catalog discovery must include the new files in the same
-- weighted selectors used by scheduled entry and ordinary generation.
function test.run()
    local entrances = entry.candidates(branches.BRANCH_SNAKE)
    local found_entry = false
    local found_chamber = false

    harness.equal(#entrances, 9, "mod extends source entrance pool")

    for _, candidate in ipairs(entrances) do
        if candidate.definition.id == "modded_snake_gate" then
            found_entry = true
            harness.equal(candidate.weight, 7,
                "modded entrance keeps its source weight")
            harness.equal(vaults.get(candidate.definition.id).rows[2],
                "..O..", "modded entrance keeps its MAP")
        end
    end

    local context = {
        branch_id = branches.BRANCH_SNAKE,
        depth = 2,
        branch_bottom = 4,
        absolute_depth = 16,
        branch_vault_family = families.SNAKE,
    }

    for _, candidate in ipairs(regular.candidates(context)) do
        if candidate.definition.id == "modded_snake_chamber" then
            found_chamber = true
            harness.equal(candidate.weight, 7,
                "modded ordinary map keeps its source weight")
        end
    end

    harness.truthy(found_entry, "new effective entrance is selectable")
    harness.truthy(found_chamber, "new ordinary map is selectable")
end

return test
