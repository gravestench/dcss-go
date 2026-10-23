-- Elements cycles through three different elemental families, creating
-- source-duration allies through the ordinary summon component owner.
local attitudes = require("constants.attitude")
local cards = require("ids.cards")
local component = require("constants.component")
local effects = require("policy.religion.cards.effects.dispatch")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")

local test = {}

-- The first row at tier one yields a wind drake, catoblepas, and molten
-- gargoyle. The fourth family wraps if the starting row is later.
function test.run(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)
    local card_draws = 0

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 10,
        y = 10,
    })

    function owner:random(stream, bound)
        if stream == streams.CARDS then
            card_draws = card_draws + 1

            if card_draws == 1 then
                harness.equal(bound, 4)
            else
                harness.equal(bound, 8)
            end

            return 0
        end

        return ctx:random(stream, bound)
    end

    effects.apply(owner, player, cards.ELEMENTS, {
        tier = 1,
        power = 400,
    })

    local summoned = ctx:query({ component.SUMMON })
    local expected = {
        monsters.MONS_WIND_DRAKE,
        monsters.MONS_CATOBLEPAS,
        monsters.MONS_MOLTEN_GARGOYLE,
    }

    harness.equal(#summoned, 3)

    for index, entity in ipairs(summoned) do
        harness.equal(ctx:get(entity, component.ACTOR).kind_id,
            expected[index])
        harness.equal(ctx:get(entity, component.SUMMON).attitude,
            attitudes.FRIENDLY)
    end

    harness.equal(card_draws, 4)
end

return test
