-- Illusion uses the existing player-ghost snapshot and summon lifetime.
-- Its card tier changes the abjuration degree rather than the copied stats.
local cards = require("ids.cards")
local component = require("constants.component")
local effects = require("policy.religion.cards.effects.dispatch")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local jewellery = require("tests.fixtures.jewellery")
local streams = require("constants.rng_streams")

local test = {}

-- Use real player components so this catches a card-specific shadow ghost
-- implementation drifting from the ordinary illusion combat owner.
function test.run(ctx)
    local _, player = jewellery.player(ctx)
    local game = fixture.context(ctx, player)

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 10,
        y = 10,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 1,
        total_xp = 0,
    })
    ctx:add(player, component.HEALTH, {
        current = 20,
        max = 20,
    })
    ctx:add(player, component.DURATIONS, {
        haste_aut = 0,
        might_aut = 0,
    })

    local card_draws = 0

    function game:random(stream, bound)
        if stream == streams.CARDS then
            card_draws = card_draws + 1

            if card_draws == 1 then
                harness.equal(bound, 2)
            else
                harness.equal(bound, 8)
            end

            return 1
        end

        return ctx:random(stream, bound)
    end

    effects.apply(game, player, cards.ILLUSION, {
        tier = 2,
        power = 500,
    })

    local ghosts = ctx:query({ component.PLAYER_ILLUSION })

    harness.equal(#ghosts, 1)
    harness.equal(card_draws, 2)
    harness.equal(ctx:get(ghosts[1], component.SUMMON).source_id,
        cards.ILLUSION)
    harness.equal(ctx:get(ghosts[1], component.PLAYER_ILLUSION).name,
        "Jewellery test")
end

return test
