-- The Horn summons one beast at low Evocations and can reach four at the
-- source power threshold, with each extra beast rolled independently.
local harness = require("tests.harness")
local horn = require("policy.inventory.evokers.horn")

local test = {}

-- Exercise the source three-threshold roll without reimplementing the
-- summon policy or using a duplicate monster schema in the fixture.
function test.run()
    local ctx = {}

    function ctx:random(_, bound)
        harness.equal(bound, 90)

        return 89
    end

    harness.equal(horn.count(ctx, 0), 1)
    harness.equal(horn.count(ctx, 50), 2)
    harness.equal(horn.count(ctx, 100), 3)
    harness.equal(horn.count(ctx, 150), 4)
end

return test
