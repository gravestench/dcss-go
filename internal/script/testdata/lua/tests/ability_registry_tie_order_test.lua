local harness = require("tests.harness")
local registry = require("policy.abilities.registry")

local test = {}

-- Listing never invokes these hooks; registry validation still requires a callable ability definition.
local function unused()
    return nil
end

-- Register equal display names backward so a name-only sort exposes insertion order.
function test.run(ctx)
    local later_id = "test.ability.zzz"
    local earlier_id = "test.ability.aaa"

    registry.add(later_id, {
        name = "Test ability tie",
        prepare = unused,
        resolve = unused,
    })
    registry.add(earlier_id, {
        name = "Test ability tie",
        prepare = unused,
        resolve = unused,
    })

    local listed = registry.available(ctx, ctx:create())
    local tied = {}

    for _, ability in ipairs(listed) do
        if ability.name == "Test ability tie" then
            tied[#tied + 1] = ability.id
        end
    end

    harness.equal(#tied, 2, "both tied abilities remain available")
    harness.equal(tied[1], earlier_id,
        "equal names break ties by stable ability ID")
    harness.equal(tied[2], later_id,
        "the second tied ability follows its ID order")
end

return test
