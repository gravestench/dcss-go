-- Nemelex gifts use real worship and deck ECS schemas. Only the religion
-- stream is scripted, so a changed source draw order fails at its bound.
local component = require("constants.component")
local decks = require("ids.decks")
local gifts = require("policy.religion.gifts")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local species = require("ids.species")
local state = require("policy.religion.cards.state")
local streams = require("constants.rng_streams")

local test = {}

-- Fail on an extra draw or wrong bound; a reward's later seeded behavior
-- depends on using the same chance and deck sequence as the source.
local function owner(ctx, points, previous_gifts, draws)
    local player = ctx:create()
    local game = setmetatable({}, { __index = ctx })
    local index = 0
    local messages = {}

    function game:player()
        return player
    end

    function game:random(stream, bound)
        harness.equal(stream, streams.RELIGION)

        index = index + 1

        local next_draw = draws[index]

        harness.truthy(next_draw, "unexpected Nemelex religion draw")
        harness.equal(bound, next_draw.bound,
            "Nemelex changed a source RNG bound")

        return next_draw.value
    end

    function game:draws_used()
        return index
    end

    function game:emit(_, message)
        messages[#messages + 1] = message
    end

    function game:message(number)
        return messages[number]
    end

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Nemelex gift tester",
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.NEMELEX_XOBEH,
        piety = points,
        gift_total = {
            [gods.NEMELEX_XOBEH] = previous_gifts,
        },
    })

    return game, player
end

-- The first successful check deals four cards by source 3:1:1 deck
-- weights, then records even the minimum possible gift cooldown.
local function first_gift(ctx)
    local game, player = owner(ctx, 30, 0, {
        { bound = 50, value = 0 },
        { bound = 10, value = 0 },
        { bound = 5, value = 0 },
        { bound = 5, value = 3 },
        { bound = 5, value = 4 },
        { bound = 5, value = 0 },
        { bound = 9, value = 0 },
        { bound = 10, value = 0 },
    })

    harness.truthy(gifts.check(game, player))

    local owned = state.get(game, player)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    harness.equal(owned.counts[decks.DESTRUCTION], 2)
    harness.equal(owned.counts[decks.SUMMONING], 1)
    harness.equal(owned.counts[decks.ESCAPE], 1)
    harness.equal(worship.gift_timeout, 5)
    harness.equal(worship.gift_total[gods.NEMELEX_XOBEH], 1)
    harness.equal(game:draws_used(), 8)
    harness.equal(game:message(2),
        "You now have 1 escape card, 2 destruction cards and 1 summoning card.")
    harness.falsy(gifts.check(game, player))

    gifts.leave(game, player, gods.NEMELEX_XOBEH)

    harness.equal(state.get(game, player).counts[decks.ESCAPE] or 0, 0)
    harness.equal(ctx:get(player, component.RELIGION_WORSHIP)
        .gift_total[gods.NEMELEX_XOBEH], 1)
end

-- A successful chance spends the gift even when every deck is full.
-- Source still rolls the attempted card slots and the cooldown.
local function full_decks(ctx)
    local game, player = owner(ctx, 200, 1, {
        { bound = 3, value = 0 },
        { bound = 200, value = 0 },
        { bound = 10, value = 0 },
        { bound = 5, value = 0 },
        { bound = 5, value = 3 },
        { bound = 5, value = 4 },
        { bound = 5, value = 0 },
        { bound = 9, value = 0 },
        { bound = 10, value = 0 },
    })

    local owned = state.get(game, player)

    owned.counts[decks.ESCAPE] = 13
    owned.counts[decks.DESTRUCTION] = 26
    owned.counts[decks.SUMMONING] = 13
    state.set(game, player, owned)

    harness.truthy(gifts.check(game, player))

    local saved = state.get(game, player)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    harness.equal(saved.counts[decks.ESCAPE], 13)
    harness.equal(saved.counts[decks.DESTRUCTION], 26)
    harness.equal(saved.counts[decks.SUMMONING], 13)
    harness.equal(worship.gift_total[gods.NEMELEX_XOBEH], 2)
    harness.equal(worship.gift_timeout, 5)
end

-- Below one star, Nemelex does not consume any chance draw.
local function low_piety(ctx)
    local game, player = owner(ctx, 29, 0, {})

    harness.falsy(gifts.check(game, player))
    harness.equal(game:draws_used(), 0)
end

-- Keep all scenarios on the production god definition and gift router.
function test.run(ctx)
    first_gift(ctx)
    full_decks(ctx)
    low_piety(ctx)
end

return test
