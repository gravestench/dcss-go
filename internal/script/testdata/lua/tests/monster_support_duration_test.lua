local component = require("constants.component")
local duration = require("policy.combat.monster_support.duration")
local harness = require("tests.harness")
local monsters = require("ids.monsters")

local test = {}

-- With zeroed named draws, source mon-ench.cc's asymmetric fuzz chooses
-- the lower boundary. A speed-zero stationary actor uses baseline speed
-- for duration arithmetic rather than a hundred-aut action duration.
function test.run(ctx)
    local caster = ctx:create()

    ctx:add(caster, component.ACTOR, {
        kind_id = monsters.MONS_RAT,
        speed = 10,
    })

    harness.equal(duration.beneficial(ctx, caster), 160,
        "ordinary speed uses the source beneficial duration floor")
    harness.equal(duration.protection(ctx, caster), 48,
        "protection uses the shorter source duration class")

    local actor = ctx:get(caster, component.ACTOR)

    actor.speed = 0
    ctx:set(caster, component.ACTOR, actor)

    harness.equal(duration.beneficial(ctx, caster), 160,
        "stationary speed falls back to the source baseline")
end

return test
