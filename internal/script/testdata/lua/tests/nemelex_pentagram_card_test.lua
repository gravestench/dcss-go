-- Pentagram exercises the production demon tier catalog and summon owner.
-- The fixture controls only card RNG; ECS summon state is real.
local attitudes = require("constants.attitude")
local cards = require("ids.cards")
local component = require("constants.component")
local demon_tiers = require("data.demon_tiers")
local effects = require("policy.religion.cards.effects.dispatch")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")

local test = {}

-- Tier two uses a tier-two demon and a friendly Pandemonium lord. A zero
-- hostility roll makes only the first creature hostile.
function test.run(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)
    local bounds = {}

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 10,
        y = 10,
    })

    function owner:random(stream, bound)
        if stream == streams.CARDS then
            bounds[#bounds + 1] = bound

            return 0
        end

        return ctx:random(stream, bound)
    end

    effects.apply(owner, player, cards.SUMMON_DEMON, {
        tier = 2,
        power = 500,
    })

    local created = ctx:query({ component.SUMMON })

    harness.equal(#created, 2)
    harness.equal(ctx:get(created[1], component.ACTOR).kind_id,
        demon_tiers[2][1])
    harness.equal(ctx:get(created[2], component.ACTOR).kind_id,
        monsters.MONS_PANDEMONIUM_LORD)
    harness.equal(ctx:get(created[1], component.SUMMON).attitude,
        attitudes.HOSTILE)
    harness.equal(ctx:get(created[2], component.SUMMON).attitude,
        attitudes.FRIENDLY)
    harness.equal(bounds[1], #demon_tiers[2])
    harness.equal(bounds[2], 6)
end

return test
