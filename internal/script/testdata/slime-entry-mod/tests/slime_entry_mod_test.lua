-- Effective DES discovery includes a mod-added branch entry without a
-- Go switch, Lua ID roster, or copied source-catalog implementation.
local branches = require("ids.branches")
local catalog = require("policy.generation.vaults.catalog")
local entry = require("policy.generation.vaults.branch_entry")
local harness = require("tests.harness")

local test = {}

-- Confirm the mod's declaration joins the same weighted pool used by
-- scheduled Lair generation while all bundled source choices remain.
function test.run()
    local candidates = entry.candidates(branches.BRANCH_SLIME)
    local found = false

    harness.equal(#candidates, 11, "mod extends source entry pool")

    for _, candidate in ipairs(candidates) do
        if candidate.definition.id == "modded_slime_gate" then
            found = true

            harness.equal(candidate.weight, 7,
                "modded source weight remains effective")
            harness.equal(catalog.get(candidate.definition.id).rows[2],
                "..O..", "modded MAP bytes remain authored")
        end
    end

    harness.truthy(found, "new effective entry is selectable")
end

return test
