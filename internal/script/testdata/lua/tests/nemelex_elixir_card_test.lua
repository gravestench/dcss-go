-- Elixir's saved duration heals HP and MP on each player action through a
-- real system. The effect file only starts the status; the system ages it.
local component = require("constants.component")
local cards = require("ids.cards")
local effects = require("policy.religion.cards.effects.dispatch")
local harness = require("tests.harness")
local system = require("systems.religion_card_elixir")
local streams = require("constants.rng_streams")

local test = {}

-- A tier-zero card with a one-turn bonus lasts two normal turns. Each tick
-- restores one tenth of maximum HP and MP before the status expires.
function test.run(ctx)
    local player = ctx:create()
    local owner = setmetatable({}, { __index = ctx })

    function owner:player()
        return player
    end

    function owner:random(stream, bound)
        harness.equal(stream, streams.CARDS)
        harness.equal(bound, 3)

        return 1
    end

    ctx:add(player, component.HEALTH, {
        current = 20,
        max = 50,
    })
    ctx:add(player, component.MAGIC, {
        current = 2,
        max = 10,
    })

    effects.apply(owner, player, cards.ELIXIR, {
        tier = 0,
    })

    harness.equal(ctx:get(player,
        component.RELIGION_CARD_ELIXIR).remaining_aut, 20)

    system.update(owner, player, 10)

    harness.equal(ctx:get(player, component.HEALTH).current, 25)
    harness.equal(ctx:get(player, component.MAGIC).current, 3)
    harness.equal(ctx:get(player,
        component.RELIGION_CARD_ELIXIR).remaining_aut, 10)

    system.update(owner, player, 10)

    harness.equal(ctx:get(player, component.HEALTH).current, 30)
    harness.equal(ctx:get(player, component.MAGIC).current, 4)
    harness.falsy(ctx:has(player, component.RELIGION_CARD_ELIXIR))
end

return test
