-- Crypt uses the same source-backed entry and mandatory-end selectors as
-- neighboring branches. Filesystem order must not decide either draw.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local families = require("constants.vault_families")
local features = require("constants.vault_features")
local harness = require("tests.harness")
local entry = require("policy.generation.vaults.branch_entry")
local primary = require("policy.generation.vaults.primary")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- The scheduled Vaults floor draws from all thirteen source entrances.
-- The dummy map is deliberately retained as a weighted plain-stair option.
local function entry_pool()
    harness.truthy(
        entry.supports(branches.BRANCH_CRYPT),
        "Crypt needs an authored Vaults-side entrance"
    )

    local floor = {
        branch_id = branches.BRANCH_VAULTS,
        depth = 3,
        branch_bottom = 5,
        absolute_depth = 16,
    }
    local candidates = entry.candidates(branches.BRANCH_CRYPT, floor)

    harness.equal(#candidates, 13, "complete Crypt entry pool")

    local dummy

    for _, candidate in ipairs(candidates) do
        harness.equal(candidate.definition.family, families.CRYPT_ENTRY)

        if candidate.definition.id == "dummy_crypt_entry" then
            dummy = candidate
        end
    end

    harness.truthy(dummy, "plain source Crypt stair is a valid candidate")
    harness.equal(dummy.weight, 50, "plain stair keeps its source weight")
end

-- Crypt:3 must select exactly one authored ending. The Tomb gate identity
-- is named here because the link binder must distinguish it from stairs.
local function ending_pool()
    local branch = register.get(categories.BRANCHES, branches.BRANCH_CRYPT)
    local specification = primary.specification(branch, 3)

    harness.truthy(specification, "Crypt:3 has no mandatory ending")
    harness.equal(specification.family, families.CRYPT_END)
    harness.truthy(
        features.ENTER_TOMB,
        "Crypt endings need the keyed Tomb gate identity"
    )

    local candidates = primary.candidates({
        branch_id = branches.BRANCH_CRYPT,
        depth = 3,
        branch_bottom = 3,
        absolute_depth = 21,
        primary_vault_family = families.CRYPT_END,
    })

    harness.equal(#candidates, 8, "complete Crypt end pool")
end

-- Load the actual DES registry before testing either public selector.
function test.run()
    vaults.load()
    entry_pool()
    ending_pool()
end

return test
