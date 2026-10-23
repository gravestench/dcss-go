-- Punishment cards use their named Lua effect and live ECS health. Wraith
-- shares temporary drain with combat, so later XP can recover the loss.
local component = require("constants.component")
local cards = require("ids.cards")
local effects = require("policy.religion.cards.effects.dispatch")
local harness = require("tests.harness")
local streams = require("constants.rng_streams")

local test = {}

-- Source Wraith passes one quarter of card power to ordinary player drain.
-- Pin the fractional rounding draw while using the production component.
function test.run(ctx)
    local player = ctx:create()
    local owner = setmetatable({}, { __index = ctx })

    ctx:add(player, component.HEALTH, {
        current = 100,
        max = 100,
    })

    function owner:random(stream, bound)
        harness.equal(stream, streams.CARDS)
        harness.equal(bound, 750)

        return 0
    end

    effects.apply(owner, player, cards.WRAITH, {
        power = 400,
        punishment = true,
    })

    harness.equal(ctx:get(player, component.HEALTH).max, 85)
    harness.equal(ctx:get(player, "status.drain").amount, 15)
end

return test
