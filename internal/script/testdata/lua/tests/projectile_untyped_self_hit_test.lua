local damage = require("policy.magic.damage")
local harness = require("tests.harness")

local test = {}

function test.run(ctx)
    local player = ctx:create()

    harness.equal(damage.player_elemental(ctx, player, 18, nil), 18,
        "untyped self-hit damage has no elemental resistance check")
end

return test
