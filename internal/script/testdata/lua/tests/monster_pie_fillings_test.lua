
local cherry = require("policy.combat.pies.cherry")
local component = require("constants.component")
local harness = require("tests.harness")
local fixture = require("tests.monster_ally_support_fixture")

local test = {}

-- Proxy the production context while pinning every pie roll to its minimum.
local function lowest_roll(ctx)
    local proxy = setmetatable({}, { __index = ctx })

    -- Require the monster-spell stream and return zero for the low-duration case.
    function proxy:random(stream)
        harness.equal(stream, "monster_spell",
            "pie uses the monster spell RNG stream")

        return 0
    end

    return proxy
end

-- Cherry pie gives the player 15 turns at the low source roll.
function test.run(ctx)
    local monster = ctx:create()
    local game = fixture.observed_context(ctx)
    local draws = lowest_roll(game)

    cherry.apply(draws, nil, monster)

    harness.equal(ctx:get(monster,
        component.FIRE_VULNERABILITY).remaining_aut, 15,
        "cherry pie gives a monster 15 aut at the low source roll")

    local player = ctx:create()

    ctx:add(player, component.PLAYER, {})

    local player_draws = lowest_roll(game)

    cherry.apply(player_draws, nil, player)

    harness.equal(ctx:get(player,
        component.FIRE_VULNERABILITY).remaining_aut, 150,
        "cherry pie gives the player 15 turns at the low source roll")
end

return test
