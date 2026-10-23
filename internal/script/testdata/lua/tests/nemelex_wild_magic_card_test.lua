-- Card selection and MP recovery use production ECS state while a miscast
-- spy isolates the nine-school effect owner tested in its own scenario.
local cards = require("ids.cards")
local component = require("constants.component")
local effects = require("policy.religion.cards.effects.dispatch")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local miscast = require("policy.magic.miscast")
local monster_stats = require("policy.combat.monster_stats")
local monsters = require("ids.monsters")
local schools = require("constants.spell_schools")
local streams = require("constants.rng_streams")

local test = {}

-- Each tier increases miscast level by three. Two affected enemies yield
-- two independent MP draws, capped by the saved magic maximum.
function test.run(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)
    local first = fixture.actor(ctx, monsters.MONS_RAT, 8, 7, 100)
    local second = fixture.actor(ctx, monsters.MONS_RAT, 9, 7, 100)
    local original = miscast.apply
    local hit_dice = monster_stats.hit_dice
    local calls = {}
    local draws = {}
    local index = 0

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })
    ctx:add(player, component.MAGIC, {
        current = 2,
        max = 5,
    })

    function owner:random(stream, bound)
        harness.equal(stream, streams.CARDS)
        index = index + 1
        local next_draw = draws[index]

        harness.truthy(next_draw, "unexpected Wild Magic draw")
        harness.equal(bound, next_draw.bound)

        return next_draw.value
    end

    miscast.apply = function(_, target, source, school, level,
        fail, stream)
        harness.equal(source, player)
        harness.equal(school, schools.CONJURATION)
        harness.equal(fail, 0)
        harness.equal(stream, streams.CARDS)
        calls[#calls + 1] = { target = target, level = level }
    end

    local ok, message = pcall(function()
        for tier = 0, 2 do
            calls = {}
            draws = {
                { bound = 5, value = 0 },
                { bound = 9, value = 0 },
                { bound = 70, value = 0 },
                { bound = 5, value = 0 },
                { bound = 9, value = 0 },
                { bound = 70, value = 0 },
                { bound = 5, value = 4 },
                { bound = 5, value = 0 },
            }
            index = 0

            effects.apply(owner, player, cards.WILD_MAGIC, {
                tier = tier,
                power = 300,
            })

            harness.equal(index, #draws)
            harness.equal(#calls, 2)
            harness.equal(calls[1].target, first)
            harness.equal(calls[2].target, second)
            harness.equal(calls[1].level, 3 * (tier + 1))
            harness.equal(calls[2].level, 3 * (tier + 1))
            harness.equal(ctx:get(player, component.MAGIC).current, 5)
        end

        ctx:set(player, component.POSITION, {
            level_id = 1,
            x = 30,
            y = 30,
        })
        draws = {}
        index = 0

        effects.apply(owner, player, cards.WILD_MAGIC, {
            tier = 2,
            power = 500,
        })

        harness.equal(index, 0)
        harness.equal(ctx:get(player, component.MAGIC).current, 5)

        -- A high-HD monster can resist the source x_chance_in_y check.
        -- A failed card spends no school, fail, or MP restoration draws.
        ctx:set(player, component.POSITION, {
            level_id = 1,
            x = 7,
            y = 7,
        })
        ctx:set(second, component.POSITION, {
            level_id = 1,
            x = 30,
            y = 30,
        })
        monster_stats.hit_dice = function()
            return 30
        end
        draws = {
            { bound = 5, value = 0 },
            { bound = 30, value = 29 },
        }
        index = 0
        calls = {}

        effects.apply(owner, player, cards.WILD_MAGIC, {
            tier = 0,
            power = 300,
        })

        harness.equal(index, 2)
        harness.equal(#calls, 0)
        harness.equal(ctx:get(player, component.MAGIC).current, 5)
    end)

    miscast.apply = original
    monster_stats.hit_dice = hit_dice

    if not ok then
        error(message)
    end
end

return test
