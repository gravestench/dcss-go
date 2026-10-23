-- Velocity routes both sides through live status owners. Its player Slow
-- reduction and monster timers therefore use production saved components.
local cards = require("ids.cards")
local component = require("constants.component")
local effects = require("policy.religion.cards.effects.dispatch")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")

local test = {}

-- Tier zero can Slow a hostile but cannot improve an ally or the player.
-- Tier one still rolls its chances; tier two makes all three effects certain.
function test.run(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    ctx:add(player, component.PLAYER_SLOW, {
        remaining_aut = 70,
    })

    local hostile = fixture.actor(ctx, monsters.MONS_RAT, 8, 7)
    local ally = fixture.actor(ctx, monsters.MONS_RAT, 6, 7)

    ctx:add(ally, component.SUMMON, {
        owner = player,
    })

    -- All source card chances and generic status durations use the card stream.
    function owner:random(stream, _)
        harness.equal(stream, "cards")

        return 0
    end

    effects.apply(owner, player, cards.VELOCITY, {
        tier = 0,
        power = 0,
    })

    harness.equal(ctx:get(player, component.PLAYER_SLOW).remaining_aut, 70)
    harness.truthy(ctx:get(hostile, component.PROJECTILE_SLOW))
    harness.falsy(ctx:get(ally, component.MONSTER_BOONS))

    -- Highest rolls fail both one-in-two chances and the two-in-three Slow.
    function owner:random(stream, bound)
        harness.equal(stream, "cards")

        return bound - 1
    end

    effects.apply(owner, player, cards.VELOCITY, {
        tier = 1,
        power = 400,
    })

    harness.equal(ctx:get(player, component.PLAYER_SLOW).remaining_aut, 70)
    harness.falsy(ctx:get(ally, component.MONSTER_BOONS))

    -- Certain tier-two outcomes need RNG only for their status durations.
    function owner:random(stream, _)
        harness.equal(stream, "cards")

        return 0
    end

    effects.apply(owner, player, cards.VELOCITY, {
        tier = 2,
        power = 900,
    })

    harness.equal(ctx:get(player, component.PLAYER_SLOW).remaining_aut, 1)
    harness.truthy(ctx:get(hostile, component.PROJECTILE_SLOW))
    harness.truthy(ctx:get(ally, component.MONSTER_BOONS).haste_aut > 0)
end

return test
