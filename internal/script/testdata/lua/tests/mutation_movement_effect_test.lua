local movement = require("policy.character.movement")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

function test.run(ctx)
    local ordinary = ctx:create()
    local fast = ctx:create()
    local slow = ctx:create()

    records.grant_acquired(ctx, fast, mutations.MUT_FAST, 2)
    records.grant_acquired(ctx, slow, mutations.MUT_SLOW, 2)

    harness.equal(movement.base(ctx, ordinary), 10,
        "unmodified player movement delay")
    harness.equal(movement.base(ctx, fast), 7,
        "Fast level two reduces movement by three aut")
    harness.equal(movement.base(ctx, slow), 14,
        "Slow level two increases movement by forty percent")
end

return test
