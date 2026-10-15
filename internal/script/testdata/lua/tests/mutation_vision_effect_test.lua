local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local vision = require("policy.character.vision")
local harness = require("tests.harness")

local test = {}

function test.run(ctx)
    local player = ctx:create()

    harness.equal(vision.radius(ctx, player), 7,
        "ordinary sight spans seven cells")

    records.grant_acquired(ctx, player, mutations.MUT_DAYSTALKER, 1)

    harness.equal(vision.radius(ctx, player), 8,
        "Daystalker increases base sight by one")

    records.grant_acquired(ctx, player, mutations.MUT_NIGHTSTALKER, 2)

    harness.equal(vision.radius(ctx, player), 6,
        "Daystalker and Nightstalker combine")

    local night = ctx:create()

    records.grant_acquired(ctx, night, mutations.MUT_NIGHTSTALKER, 3)

    harness.equal(vision.radius(ctx, night), 4,
        "Nightstalker level three cuts sight to four cells")
end

return test
