-- An authored end layout opens only its explicit floor. The branch catalog
-- owns the requirement, while the effective DES catalog supplies the map.
local availability = require("policy.generation.floor_availability")
local branches = require("ids.branches")
local harness = require("tests.harness")
local layouts = require("policy.generation.layouts.catalog")

local test = {}

function test.run()
    local vaults = branches.BRANCH_VAULTS

    harness.truthy(layouts.has_explicit(vaults, 5),
        "effective end map is explicit")
    harness.falsy(layouts.has_explicit(vaults, 4),
        "ordinary Vaults floor has no end map")
    harness.truthy(availability.can_build(vaults, 4),
        "ordinary Vaults floor stays open")
    harness.truthy(availability.can_build(vaults, 5),
        "source end map opens Vaults:5")
    harness.falsy(availability.can_build(vaults, 6),
        "branch cannot exceed its source depth")
end

return test
