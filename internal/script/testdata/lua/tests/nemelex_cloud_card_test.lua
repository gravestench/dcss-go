-- Cloud creates saved black-smoke entities around a threatening enemy;
-- this test uses the production cloud schema and placement owner.
local cards = require("ids.cards")
local clouds = require("ids.clouds")
local component = require("constants.component")
local effects = require("policy.religion.cards.effects.dispatch")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")

local test = {}

-- Tier zero has five-turn smoke. Eight adjacent floor cells surround the
-- rat even when one of those cells is occupied by the player.
function test.run(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    fixture.actor(ctx, monsters.MONS_RAT, 8, 7)

    function owner:random(stream, bound)
        if stream == streams.CARDS then
            harness.equal(bound, 1)

            return 0
        end

        return ctx:random(stream, bound)
    end

    effects.apply(owner, player, cards.CLOUD, {
        tier = 0,
        power = 300,
    })

    local created = ctx:query({ component.WORLD_CLOUD })

    harness.equal(#created, 8)

    for _, entity in ipairs(created) do
        local state = ctx:get(entity, component.WORLD_CLOUD)

        harness.equal(state.kind_id, clouds.CLOUD_BLACK_SMOKE)
        harness.equal(state.decay_aut, 50)
    end
end

return test
