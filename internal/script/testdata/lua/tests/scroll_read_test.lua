local component = require("constants.component")
local harness = require("tests.harness")
local restrictions = require("constants.safety_restrictions")
local reading = require("policy.scrolls.restrictions")

local test = {}

function test.run(ctx)
    local player = ctx:create()

    harness.equal(reading.reason(ctx, player), nil,
        "an unrestricted player can read")

    ctx:add(player, component.DAMAGE_SAFETY, {
        [restrictions.SCROLLS] = 30,
    })
    harness.equal(reading.reason(ctx, player),
        "You cannot read scrolls in your current state!",
        "read-safety blocks scrolls without spending time")
    ctx:remove(player, component.DAMAGE_SAFETY)

    ctx:add(player, "zap.player_confusion", {
        remaining_aut = 30,
    })
    harness.equal(reading.reason(ctx, player),
        "You are too confused!", "confusion prevents reading")
    ctx:remove(player, "zap.player_confusion")

    ctx:add(player, component.PLAYER_STATUS, {
        silence_aut = 100,
    })
    harness.equal(reading.reason(ctx, player),
        "Magic scrolls do not work when you're silenced!",
        "silence prevents reading")
end

return test
