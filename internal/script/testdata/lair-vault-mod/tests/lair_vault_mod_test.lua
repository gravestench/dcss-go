-- Sparse additions to all three Lair stages use the effective DES catalog.
-- No Go roster, generated Lua index, or same-path override is necessary.
local branches = require("ids.branches")
local entry = require("policy.generation.vaults.branch_entry")
local endings = require("policy.generation.vaults.end")
local families = require("constants.vault_families")
local harness = require("tests.harness")
local regular = require("policy.generation.vaults.regular")

local test = {}

-- Check source and added map counts through the selectors used by gameplay.
function test.run()
    local found_entry = false

    for _, candidate in ipairs(entry.candidates(branches.BRANCH_LAIR)) do
        if candidate.definition.id == "modded_lair_gate" then
            found_entry = true
            harness.equal(candidate.weight, 7, "modded gate weight")
        end
    end

    harness.truthy(found_entry, "new Lair gate is selectable")

    local context = {
        branch_id = branches.BRANCH_LAIR,
        depth = 2,
        branch_bottom = 5,
        absolute_depth = 11,
        branch_vault_family = families.LAIR,
    }
    local found_room = false

    for _, candidate in ipairs(regular.candidates(context)) do
        if candidate.definition.id == "modded_lair_grove" then
            found_room = true
            harness.equal(candidate.weight, 7, "modded grove weight")
        end
    end

    harness.truthy(found_room, "new ordinary Lair map is selectable")

    context.depth = 5
    context.absolute_depth = 14
    context.end_vault_family = families.LAIR_END

    local found_end = false

    for _, candidate in ipairs(endings.candidates(context)) do
        if candidate.definition.id == "zz_lair_sanctuary" then
            found_end = true
            harness.equal(candidate.weight, 1, "modded end weight")
        end
    end

    harness.truthy(found_end, "new Lair:5 ending is selectable")
end

return test
