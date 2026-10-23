-- Degen routes a living enemy through weaker polymorph plus malmutation,
-- while a nonpolymorphable undead enemy receives the ordinary daze status.
local cards = require("ids.cards")
local component = require("constants.component")
local effects = require("policy.religion.cards.effects.dispatch")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local malmutation = require("policy.monsters.malmutation")
local monsters = require("ids.monsters")
local polymorph = require("policy.magic.effects.statuses.polymorph")
local streams = require("constants.rng_streams")

local test = {}

-- Observe the two existing monster owners without copying their schemas.
-- Their individual rule tests cover form selection and Wretched duration.
function test.run(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)
    local undead = fixture.actor(ctx, monsters.MONS_WRAITH,
        8, 7, 50)
    local living = fixture.actor(ctx, monsters.MONS_RAT,
        9, 7, 20)
    local weaker_calls = 0
    local mutation_calls = 0

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    function owner:random(stream)
        if stream == streams.CARDS then
            return 0
        end

        error("unexpected RNG stream")
    end

    local old_less = polymorph.less
    local old_mutate = malmutation.apply

    polymorph.less = function(_, target, definition, stream)
        harness.equal(target, living)
        harness.equal(definition.id, monsters.MONS_RAT)
        harness.equal(stream, streams.CARDS)
        weaker_calls = weaker_calls + 1

        return true
    end

    malmutation.apply = function(_, target, definition, stream)
        harness.equal(target, living)
        harness.equal(definition.id, monsters.MONS_RAT)
        harness.equal(stream, streams.CARDS)
        mutation_calls = mutation_calls + 1

        return true
    end

    local success, message = pcall(function()
        effects.apply(owner, player, cards.DEGEN, {
            tier = 2,
            power = 500,
        })
    end)

    polymorph.less = old_less
    malmutation.apply = old_mutate

    if not success then
        error(message)
    end

    harness.equal(weaker_calls, 1)
    harness.equal(mutation_calls, 1)
    harness.equal(ctx:get(undead,
        component.MONSTER_ENFEEBLE).dazed_aut, 150)
end

return test
