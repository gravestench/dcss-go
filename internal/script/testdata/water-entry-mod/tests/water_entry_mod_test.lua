-- New maps join the effective source pools by path, tag, and keyed
-- feature. No Go branch roster or copied bundled catalog is required.
local branches = require("ids.branches")
local entry = require("policy.generation.vaults.branch_entry")
local harness = require("tests.harness")

local test = {}

-- Both added gates retain their own source-style weights after the
-- embedded layer and sparse mod directory are combined.
local function check(branch, id, expected_count, expected_weight)
    local candidates = entry.candidates(branch)
    local found = false

    harness.equal(#candidates, expected_count,
        id .. " effective entrance count")

    for _, candidate in ipairs(candidates) do
        if candidate.definition.id == id then
            found = true
            harness.equal(candidate.weight, expected_weight,
                id .. " source weight")
        end
    end

    harness.truthy(found, id .. " was not discovered")
end

-- The same selector sees additions to two different families without
-- changing a shared index or the game's binary.
function test.run()
    check(branches.BRANCH_SWAMP, "modded_swamp_gate", 11, 7)
    check(branches.BRANCH_SHOALS, "modded_shoals_gate", 9, 9)
end

return test
