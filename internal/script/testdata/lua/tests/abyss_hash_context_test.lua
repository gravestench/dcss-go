-- The source floor choice uses exact unsigned integer hashing. Exercise
-- the real Go context bridge so a Lua mock cannot hide numeric rounding.
local harness = require("tests.harness")

local test = {}

-- These are pinned source vectors from hash_with_seed's MurmurHash2 path.
-- A count of one must always select the only available borrowed floor.
function test.run(ctx)
    harness.equal(ctx:hash_with_seed(100, 42, 0), 11)
    harness.equal(ctx:hash_with_seed(3, 123, 0), 0)
    harness.equal(ctx:hash_with_seed(1, 123, 0), 0)

    local sample = ctx:worley(0, 0, 0)

    harness.equal(sample.id[1], 779667506)
    harness.equal(sample.id[2], 2226598506)
    harness.truthy(math.abs(sample.distance[1] -
        0.648015886234) < 1e-12)
    harness.equal(ctx:hash3_quotient_mod(1, 2, 3, 1, 9), 6)
    harness.equal(ctx:hash3_quotient_mod(-1, 5, 10, 1, 9), 0)
    harness.truthy(math.abs(ctx:fbm3(0, 0, 0, 5) -
        0.147090148663) < 1e-12)
    harness.equal(ctx:xor_u32(7, 2, 1), 4)
end

return test
