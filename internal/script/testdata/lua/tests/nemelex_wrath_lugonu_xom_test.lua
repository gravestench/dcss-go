-- Lugonu's no-translocation route exercises the ordinary saved summon
-- owner. Xom's separate event engine still fails clearly.
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

-- Xom wrath must eventually call xom_acts. A placeholder punishment
-- would skew card behavior, so its missing event engine is explicit.
local function xom_gap()
    local ok, message = pcall(xom.apply)

    harness.falsy(ok)
    harness.truthy(string.find(message,
        "Xom action engine", 1, true))
end

-- Keep the summon route and Xom gap under one source-backed Lua scenario.
function test.run(ctx)
    minor_minion(ctx)
    xom_gap()
end

return test
