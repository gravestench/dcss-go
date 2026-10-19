-- Source div_rand_round keeps exact summon quotients.

local summons = require("policy.magic.effects.summons.common")
local harness = require("tests.harness")

local test = {}

-- Check exact-bound summon arithmetic before random cases, isolating the
-- shared helper's rounding behavior from any particular spell.
function test.run(ctx)
    harness.equal(summons.roll(ctx, 1), 0,
        "a one-sided summon roll has no random offset")
    harness.equal(summons.divide(ctx, 12, 3), 4,
        "source div_rand_round keeps exact summon quotients")
    harness.equal(summons.divide(ctx, 0, 3), 0,
        "zero summon power has no random increment")
end

return test
