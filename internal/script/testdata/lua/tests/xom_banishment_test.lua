-- Real and pseudo banishment use the same Abyss travel owner. A pseudo
-- event must enter first, then return through the saved outside origin.
local abyss = require("policy.world.abyss")
local component = require("constants.component")
local events = require("policy.religion.xom.events")
local harness = require("tests.harness")
local ids = require("ids.xom_events")
local streams = require("constants.rng_streams")

local test = {}

-- Only the travel boundary is observed here; a game test will verify
-- that the real owner moves and restores the player and world state.
function test.run(ctx)
    local player = ctx:create()
    local original_banish = abyss.banish
    local original_escape = abyss.escape
    local calls = {}

    ctx:add(player, component.PROGRESSION, {
        level = 9,
    })

    abyss.banish = function(_, actor, options)
        harness.equal(actor, player)
        harness.equal(options.stream, streams.RELIGION)
        harness.equal(options.power, 9)
        calls[#calls + 1] = "banish"
    end

    abyss.escape = function(_, actor)
        harness.equal(actor, player)
        calls[#calls + 1] = "escape"
    end

    events.apply(ctx, player, ids.BAD_BANISHMENT, 20, {
        stream = streams.RELIGION,
    })
    events.apply(ctx, player, ids.BAD_PSEUDO_BANISHMENT, 20, {
        stream = streams.RELIGION,
    })

    abyss.banish = original_banish
    abyss.escape = original_escape

    harness.equal(table.concat(calls, ","),
        "banish,banish,escape")
end

return test
