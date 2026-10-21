-- A mod contributes only its own maps; production discovers both effective
-- paths and selects them through the same ordinary and primary policies.
local branches = require("ids.branches")
local families = require("constants.vault_families")
local harness = require("tests.harness")
local primary = require("policy.generation.vaults.primary")
local regular = require("policy.generation.vaults.regular")

local test = {}

-- Check each stage's effective weighted pool, including the modded entry.
function test.run()
    local context = {
        branch_id = branches.BRANCH_ELF,
        depth = 2,
        branch_bottom = 3,
        absolute_depth = 16,
        branch_vault_family = families.ELF,
    }
    local found_room = false

    for _, candidate in ipairs(regular.candidates(context)) do
        if candidate.definition.id == "modded_elf_archive" then
            found_room = true
            harness.equal(candidate.weight, 7, "modded Elf room weight")
        end
    end

    harness.truthy(found_room, "new Elf room is selectable")

    context.depth = 3
    context.absolute_depth = 17
    context.primary_vault_family = families.ELF_END

    local found_end = false

    for _, candidate in ipairs(primary.candidates(context)) do
        if candidate.definition.id == "modded_elf_finale" then
            found_end = true
            harness.equal(candidate.weight, 3, "modded Elf end weight")
        end
    end

    harness.truthy(found_end, "new Elf ending is selectable")
end

return test
