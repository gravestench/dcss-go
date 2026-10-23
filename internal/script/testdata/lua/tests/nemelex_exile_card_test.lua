-- Exile's card policy selects victims; the ordinary Abyss owner already
-- has its own relocation and save tests. This fixture observes the handoff
-- without copying the destination world generator into a card rule test.
local abyss = require("policy.world.abyss")
local cards = require("ids.cards")
local component = require("constants.component")
local effects = require("policy.religion.cards.effects.dispatch")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")

local test = {}

-- A tier-one draw gets two attempts. Once the first victim leaves its cell,
-- the second reservoir contains only the remaining monster.
function test.run(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)
    local first = fixture.actor(ctx, monsters.MONS_RAT, 8, 7)
    local second = fixture.actor(ctx, monsters.MONS_RAT, 9, 7)
    local chosen = {}
    local bounds = {}

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    function owner:random(stream, bound)
        harness.equal(stream, streams.CARDS)
        bounds[#bounds + 1] = bound

        return 0
    end

    local original = abyss.banish_monster

    abyss.banish_monster = function(_, monster, definition, attacker)
        harness.equal(definition.id, monsters.MONS_RAT)
        harness.equal(attacker, player)
        chosen[#chosen + 1] = monster
        ctx:remove(monster, component.POSITION)

        return true
    end

    local success, message = pcall(function()
        effects.apply(owner, player, cards.EXILE, {
            tier = 1,
            power = 400,
        })
    end)

    abyss.banish_monster = original

    if not success then
        error(message)
    end

    harness.equal(#chosen, 2)
    harness.equal(chosen[1], second)
    harness.equal(chosen[2], first)
    harness.equal(#bounds, 4)
    harness.equal(bounds[1], 2)
    harness.equal(bounds[2], 2)
    harness.equal(bounds[3], 3)
    harness.equal(bounds[4], 2)
end

return test
