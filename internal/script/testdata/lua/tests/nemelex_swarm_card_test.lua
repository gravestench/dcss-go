-- Swarm uses the common summon owner, so its bees carry real allegiance,
-- expiry, source card identity, and positions for save/restore and AI.
local attitudes = require("constants.attitude")
local cards = require("ids.cards")
local categories = require("constants.catalog")
local component = require("constants.component")
local effects = require("policy.religion.cards.effects.dispatch")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")

local test = {}

-- Tier zero summons one killer bee when the count roll is zero. The card
-- stream also chooses the first legal adjacent cell; monster HP uses its
-- separate production stream and need not be copied into this fixture.
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
                harness.equal(bound, 3)
            else
                harness.equal(bound, 8)
            end

            return 0
        end

        return ctx:random(stream, bound)
    end

    effects.apply(owner, player, cards.SUMMON_BEE, {
        tier = 0,
        power = 100,
    })

    local summoned = ctx:query({ component.SUMMON })

    harness.equal(#summoned, 1)
    harness.equal(ctx:get(summoned[1], component.ACTOR).kind_id,
        monsters.MONS_KILLER_BEE)

    local record = ctx:get(summoned[1], component.SUMMON)

    harness.equal(record.attitude, attitudes.FRIENDLY)
    harness.equal(record.source_category, categories.CARDS)
    harness.equal(record.source_id, cards.SUMMON_BEE)
    harness.equal(card_draws, 2)
end

return test
