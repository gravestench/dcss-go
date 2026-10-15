local branches = require("ids.branches")
local component = require("constants.component")
local harness = require("tests.harness")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local zot = require("policy.world.zot_clock")

local test = {}

function test.run(ctx)
    local ordinary = ctx:create()
    local short = ctx:create()
    local dungeon = branches.BRANCH_DUNGEON
    local lair = branches.BRANCH_LAIR

    records.grant_acquired(ctx, short, mutations.MUT_SHORT_LIFESPAN, 1)

    zot.advance(ctx, ordinary, dungeon, 1, 0)
    zot.advance(ctx, short, dungeon, 1, 0)

    harness.equal(zot.clock(ctx, ordinary, dungeon), 210000,
        "ordinary Dungeon entry grants 6000 turns")
    harness.equal(zot.clock(ctx, short, dungeon), 264000,
        "Short Lifespan entry grants 600 turns")

    zot.advance(ctx, ordinary, dungeon, 1, 10)
    zot.advance(ctx, short, dungeon, 1, 10)

    harness.equal(zot.clock(ctx, ordinary, dungeon), 210010,
        "ordinary action spends its exact aut")
    harness.equal(zot.clock(ctx, short, dungeon), 264010,
        "Short Lifespan action spends its exact aut")

    zot.advance(ctx, ordinary, dungeon, 2, 0)
    zot.advance(ctx, short, dungeon, 2, 0)

    harness.equal(zot.clock(ctx, ordinary, dungeon), 150010,
        "new ordinary floor adds 6000 turns")
    harness.equal(zot.clock(ctx, short, dungeon), 258010,
        "new short-lived floor adds 600 turns")

    zot.advance(ctx, short, dungeon, 1, 0)

    harness.equal(zot.clock(ctx, short, dungeon), 258010,
        "returning to a visited floor grants no time")

    zot.advance(ctx, short, lair, 3, 0)

    harness.equal(zot.clock(ctx, short, lair), 264000,
        "a new branch owns an independent clock")
    harness.equal(zot.clock(ctx, short, dungeon), 258010,
        "leaving a branch preserves its clock")

    local warning = ctx:create()

    records.grant_acquired(ctx, warning, mutations.MUT_SHORT_LIFESPAN, 1)
    zot.advance(ctx, warning, dungeon, 1, 0)
    zot.advance(ctx, warning, dungeon, 1, 5000)

    harness.equal(zot.warning_level(ctx, warning, dungeon), 0,
        "warning boundary is strict")

    zot.advance(ctx, warning, dungeon, 1, 10)

    harness.equal(zot.warning_level(ctx, warning, dungeon), 1,
        "warnings scale with the short lifespan")

    local touched = ctx:create()

    ctx:add(touched, component.HEALTH, {
        current = 100,
        max = 100,
    })

    records.grant_acquired(ctx, touched, mutations.MUT_SHORT_LIFESPAN, 1)
    zot.advance(ctx, touched, dungeon, 1, 0)
    zot.advance(ctx, touched, dungeon, 1, 6000)

    harness.equal(ctx:get(touched, component.HEALTH).max, 63,
        "Zot touch drains source-shaped max HP")
    harness.equal(ctx:get(touched, "status.drain").amount, 37,
        "Zot drain is saved on the player")
    harness.equal(zot.clock(ctx, touched, dungeon), 268000,
        "short-lived clock resets to 200 turns")

    zot.advance(ctx, touched, dungeon, 1, 2000)
    zot.advance(ctx, touched, dungeon, 1, 2000)
    zot.advance(ctx, touched, dungeon, 1, 2000)

    harness.equal(ctx:get(touched, component.HEALTH).current, 0,
        "Zot kills after drain leaves a tenth of real max HP")
end

return test
