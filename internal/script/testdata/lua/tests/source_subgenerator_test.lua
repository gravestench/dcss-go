-- A private source RNG must follow the pinned PCG vectors without spending
-- the session's named stream or sharing its cursor with another name.
local harness = require("tests.harness")

local test = {}

-- The Go test runtime provides game seed zero; these sequence-54 draws are
-- independently fixed by the source PCG initialization and bound method.
function test.run(ctx)
    local first = ctx:subgenerator(54)

    harness.equal(first:random(1), 0)
    harness.equal(first:random(5), 1)
    harness.equal(first:random(151), 109)

    local second = ctx:subgenerator(54)

    harness.equal(second:random(5), 1,
        "separate local streams share a cursor")
end

return test
