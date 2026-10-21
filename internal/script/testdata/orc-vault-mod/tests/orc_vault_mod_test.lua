-- New gates, rooms, and endings use the same effective selectors as the
-- bundled Orc family; no Go or Lua registry list needs a new entry.
local branches = require("ids.branches")
local entry = require("policy.generation.vaults.branch_entry")
local endings = require("policy.generation.vaults.primary")
local families = require("constants.vault_families")
local harness = require("tests.harness")
local regular = require("policy.generation.vaults.regular")

local test = {}

-- The three sparse files each join their stage's effective weighted pool.
function test.run()
    local found_gate = false

    for _, candidate in ipairs(entry.candidates(branches.BRANCH_ORC)) do
        if candidate.definition.id == "modded_orc_gate" then
            found_gate = true
            harness.equal(candidate.weight, 7, "modded Orc gate weight")
        end
    end

    harness.truthy(found_gate, "new Orc gate is selectable")

    local context = {
        branch_id = branches.BRANCH_ORC,
        depth = 1,
        branch_bottom = 2,
        absolute_depth = 10,
        branch_vault_family = families.ORC,
    }
    local found_camp = false

    for _, candidate in ipairs(regular.candidates(context)) do
        if candidate.definition.id == "modded_orc_camp" then
            found_camp = true
            harness.equal(candidate.weight, 7, "modded camp weight")
        end
    end

    harness.truthy(found_camp, "new ordinary Orc room is selectable")

    context.depth = 2
    context.absolute_depth = 11
    context.primary_vault_family = families.ORC_END

    local found_end = false

    for _, candidate in ipairs(endings.candidates(context)) do
        if candidate.definition.id == "zz_orc_foundry" then
            found_end = true
            harness.equal(candidate.weight, 1, "modded Orc end weight")
        end
    end

    harness.truthy(found_end, "new Orc:2 ending is selectable")
end

return test
