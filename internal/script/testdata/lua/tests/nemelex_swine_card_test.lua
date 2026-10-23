-- Swine uses the existing player form owner. The card supplies its source
-- duration directly and makes Pig Form uncancellable until that timer ends.
local cards = require("ids.cards")
local component = require("constants.component")
local effects = require("policy.religion.cards.effects.dispatch")
local fixture = require("tests.fixtures.jewellery")
local forms = require("constants.form_ids")
local harness = require("tests.harness")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")

local test = {}

-- At power 100 and a zero duration roll, source Swine lasts fifteen turns.
-- Existing form rules own the resulting HP and equipment adjustments.
function test.run(ctx)
    local owner, player = fixture.player(ctx)

    ctx:add(player, component.PROGRESSION, {
        level = 5,
    })
    ctx:add(player, component.HEALTH, {
        current = 50,
        max = 50,
    })
    ctx:add(player, component.REGENERATION, {
        hp_progress = 0,
        mp_progress = 0,
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })

    function owner:cell()
        return terrain.DNGN_FLOOR
    end

    function owner:random(stream, bound)
        harness.equal(stream, streams.CARDS)
        harness.equal(bound, 10)

        return 0
    end

    effects.apply(owner, player, cards.SWINE, {
        power = 100,
        tier = 0,
    })

    local form = ctx:get(player, component.PLAYER_FORM)

    harness.equal(form.form_id, forms.PIG)
    harness.equal(form.remaining_aut, 150)
    harness.truthy(form.uncancellable)
end

return test
