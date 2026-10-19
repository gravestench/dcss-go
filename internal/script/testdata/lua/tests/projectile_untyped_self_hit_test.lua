-- Untyped self-hit damage has no elemental resistance check.

local damage = require("policy.magic.damage")
local harness = require("tests.harness")

local test = {}

-- Compare untyped self-hit damage with an element-free player so resistance
-- logic cannot accidentally reduce a projectile that has no element.
function test.run(ctx)
    local player = ctx:create()

    harness.equal(damage.player_elemental(ctx, player, 18, nil), 18,
        "untyped self-hit damage has no elemental resistance check")
end

return test
