local component = require("constants.component")
local levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

function test.run(ctx)
    local player = ctx:create()

    records.grant_acquired(ctx, player,
        mutations.MUT_RUGGED_BROWN_SCALES, 1)
    records.grant_acquired(ctx, player,
        mutations.MUT_PHYSICAL_VULNERABILITY, 1)
    records.grant_acquired(ctx, player,
        mutations.MUT_TOUGH_SKIN, 1)

    ctx:add(player, component.PLAYER_FORM, {
        form_id = "statue",
        remaining_aut = 30,
        power = 40,
    })

    harness.equal(levels.effective(ctx, player,
        mutations.MUT_RUGGED_BROWN_SCALES), 1,
        "statue keeps partial Rugged Brown Scales benefits")
    harness.equal(levels.full(ctx, player,
        mutations.MUT_RUGGED_BROWN_SCALES), 0,
        "statue suppresses full Rugged Brown Scales AC")
    harness.equal(levels.effective(ctx, player,
        mutations.MUT_PHYSICAL_VULNERABILITY), 1,
        "physical vulnerability remains active in statue form")
    harness.equal(levels.effective(ctx, player,
        mutations.MUT_TOUGH_SKIN), 0,
        "statue suppresses Tough Skin AC")
end

return test
