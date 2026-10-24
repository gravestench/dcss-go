-- Lugonu's no-translocation route exercises the ordinary saved summon
-- owner. Xom's card wrath enters the same action owner as worship.
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local lugonu = require("policy.religion.wrath.lugonu")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")
local xom = require("policy.religion.wrath.xom")

local test = {}

-- Zero card draws skip both translocation coinflips and choose the last
-- minor via the source's three reservoir rolls. Placement stays in ECS.
local function minor_minion(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 10, 10)
    local game = fixture.context(ctx, player)

    ctx:add(player, component.PLAYER, {})
    ctx:add(player, component.PROGRESSION, { level = 1 })

    -- Other streams retain their production RNG; the card draw order is
    -- fixed only for this one branch scenario.
    function game:random(stream, bound)
        if stream == streams.CARDS then
            return 0
        end

        return ctx:random(stream, bound)
    end

    harness.truthy(lugonu.apply(game, player))

    local summoned = ctx:query({ component.SUMMON })
    local creature = summoned[#summoned]

    harness.equal(#summoned, 1)
    harness.equal(ctx:get(creature, component.ACTOR).kind_id,
        monsters.MONS_ANCIENT_ZYME)
    harness.equal(ctx:get(creature, component.SUMMON).source_id,
        gods.LUGONU)
end

-- An interested but zero-piety worshipper suppresses the chosen nice
-- action. The card still spends its niceness draw and returns cleanly.
local function xom_wrath(ctx)
    local player = ctx:create()
    local game = fixture.context(ctx, player)
    local card_draws = 0

    ctx:add(player, component.PLAYER, {})
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.XOM,
        piety = 0,
        gift_timeout = 10,
    })

    -- Other streams stay in the real context; only the card's source
    -- one-in-ten nice draw is fixed for this path.
    function game:random(stream, bound)
        if stream == streams.CARDS then
            card_draws = card_draws + 1
            harness.equal(bound, 10)

            return 0
        end

        return ctx:random(stream, bound)
    end

    harness.truthy(xom.apply(game, player))
    harness.equal(card_draws, 1)
end

-- Keep both card wrath routes under one source-backed Lua scenario.
function test.run(ctx)
    minor_minion(ctx)
    xom_wrath(ctx)
end

return test
