-- Deck draws read the effective card catalog. The scripted card stream
-- exposes weighted order and catches an accidental file-order traversal.
local cards = require("ids.cards")
local card_operations = require("constants.card_operations")
local card_phases = require("constants.card_phases")
local component = require("constants.component")
local decks = require("ids.decks")
local draw = require("policy.religion.cards.draw")
local effects = require("policy.religion.cards.effects.dispatch")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local operations = require("policy.religion.cards.operations")
local play = require("policy.religion.cards.play")
local species = require("ids.species")
local state = require("policy.religion.cards.state")
local streams = require("constants.rng_streams")
local selection_kinds = require("constants.selection_kinds")

local test = {}

-- Use real catalog definitions and pin only the bounded random draws.
local function random_owner(ctx, choices)
    local owner = setmetatable({}, { __index = ctx })
    local index = 0

    function owner:random(stream, bound)
        harness.equal(stream, streams.CARDS)

        index = index + 1

        local choice = choices[index]

        harness.truthy(choice, "unexpected card selection draw")
        harness.equal(bound, choice.bound)

        return choice.value
    end

    function owner:draws_used()
        return index
    end

    return owner
end

-- Escape's five source weights total 23. Alphabetic stable IDs put Cloud
-- before Elixir and Exile, independent of module discovery order.
local function weighted_escape(ctx)
    local owner = random_owner(ctx, {
        {
            bound = 23,
            value = 0,
        },
        {
            bound = 23,
            value = 9,
        },
        {
            bound = 23,
            value = 10,
        },
    })

    harness.equal(draw.sample(owner, decks.ESCAPE), cards.CLOUD)
    harness.equal(draw.sample(owner, decks.ESCAPE), cards.ELIXIR)
    harness.equal(draw.sample(owner, decks.ESCAPE), cards.EXILE)
    harness.equal(owner:draws_used(), 3)
end

-- Punishment is a valid source pool, while the concrete stack is never
-- sampled as a random deck.
local function distinct_pools(ctx)
    local owner = random_owner(ctx, {
        {
            bound = 28,
            value = 0,
        },
        {
            bound = 30,
            value = 0,
        },
        {
            bound = 20,
            value = 0,
        },
    })

    harness.equal(draw.sample(owner, decks.DESTRUCTION), cards.DEGEN)
    harness.equal(draw.sample(owner, decks.SUMMONING), cards.ELEMENTS)
    harness.equal(draw.sample(owner, decks.PUNISHMENT), cards.SWINE)
    harness.falsy(pcall(draw.sample, owner, decks.STACK))
end

-- Use the live player and worship schemas. The proxy only controls which
-- card the source-weighted sampler reveals after a deck count is spent.
local function worshipper(ctx, draws)
    local player = ctx:create()
    local game = random_owner(ctx, draws)

    function game:player()
        return player
    end

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Deck action tester",
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.NEMELEX_XOBEH,
        piety = 200,
    })

    return game, player
end

-- A normal draw consumes exactly one count and saves its sampled ID until
-- an effect resolves. Reentering a pending operation cannot redraw it.
local function single_draw(ctx)
    local game, player = worshipper(ctx, {
        {
            bound = 23,
            value = 0,
        },
    })
    local owned = state.get(game, player)

    owned.counts[decks.ESCAPE] = 1
    state.set(game, player, owned)

    local result = operations.prepare(game, player, {
        kind = card_operations.DRAW,
        deck_id = decks.ESCAPE,
    })

    harness.equal(result.card_id, cards.CLOUD)
    harness.equal(state.get(game, player).counts[decks.ESCAPE], 0)
    harness.equal(state.get(game, player).pending_cards[1], cards.CLOUD)
    harness.equal(state.get(game, player).pending_phase,
        card_phases.RESOLVE_CARD)
    harness.equal(game:draws_used(), 1)

    local again = operations.prepare(game, player, {
        kind = card_operations.DRAW,
        deck_id = decks.ESCAPE,
    })

    harness.equal(again.card_id, cards.CLOUD)
    harness.equal(game:draws_used(), 1)
end

-- Triple Draw first asks for a deck without spending time or counts, then
-- spends up to three cards and persists the real choices for the menu.
local function triple_draw(ctx)
    local game, player = worshipper(ctx, {
        {
            bound = 23,
            value = 0,
        },
        {
            bound = 23,
            value = 9,
        },
        {
            bound = 23,
            value = 10,
        },
    })
    local owned = state.get(game, player)

    owned.counts[decks.ESCAPE] = 3
    state.set(game, player, owned)

    local prompt = operations.prepare(game, player, {
        kind = card_operations.TRIPLE_DRAW,
    })

    harness.equal(prompt.selection.kind, selection_kinds.CARD)
    harness.equal(state.get(game, player).counts[decks.ESCAPE], 3)
    harness.truthy(prompt.selection.options[1].label:find("3 cards", 1, true))

    local cards_prompt = operations.continue(game, player, {
        selected_id = decks.ESCAPE,
    })

    harness.equal(#cards_prompt.selection.options, 3)
    harness.equal(state.get(game, player).counts[decks.ESCAPE], 0)
    harness.equal(state.get(game, player).pending_cards[2], cards.ELIXIR)

    local chosen = operations.continue(game, player, {
        selected_id = "2",
    })

    harness.equal(chosen.card_id, cards.ELIXIR)
    harness.equal(state.get(game, player).pending_selected, 2)
    harness.equal(state.get(game, player).pending_phase,
        card_phases.RESOLVE_CARD)
    harness.equal(game:draws_used(), 3)
end

-- Deal Four samples only its first card at commitment. Effect RNG must run
-- before the next ID is selected, so the player component retains the
-- total count while the unresolved cards remain in their deck.
local function deal_four(ctx)
    local game, player = worshipper(ctx, {
        {
            bound = 28,
            value = 0,
        },
        {
            bound = 28,
            value = 1,
        },
        {
            bound = 28,
            value = 2,
        },
        {
            bound = 28,
            value = 3,
        },
    })
    local owned = state.get(game, player)

    owned.counts[decks.DESTRUCTION] = 4
    state.set(game, player, owned)

    local prompt = operations.prepare(game, player, {
        kind = card_operations.DEAL_FOUR,
    })

    harness.equal(prompt.selection.kind, selection_kinds.CARD)
    harness.equal(state.get(game, player).counts[decks.DESTRUCTION], 4)

    local ready = operations.continue(game, player, {
        selected_id = decks.DESTRUCTION,
    })

    harness.equal(ready.card_id, cards.DEGEN)
    harness.equal(state.get(game, player).counts[decks.DESTRUCTION], 3)
    harness.equal(#state.get(game, player).pending_cards, 1)
    harness.equal(state.get(game, player).pending_target_count, 4)
    harness.equal(game:draws_used(), 1)
end

-- The second deal sample follows the first effect's tier and effect rolls.
-- Sampling both IDs up front would fail this exact stream sequence.
local function deal_rng_order(ctx)
    local game, player = worshipper(ctx, {
        {
            bound = 28,
            value = 0,
        },

        {
            bound = 900,
            value = 899,
        },

        {
            bound = 2700,
            value = 2699,
        },

        {
            bound = 7,
            value = 0,
        },

        {
            bound = 28,
            value = 1,
        },

        {
            bound = 900,
            value = 899,
        },

        {
            bound = 2700,
            value = 2699,
        },

        {
            bound = 7,
            value = 0,
        },
    })

    ctx:add(player, component.SKILLS, { entries = {} })

    local owned = state.get(game, player)

    owned.counts[decks.DESTRUCTION] = 2
    state.set(game, player, owned)

    operations.prepare(game, player, {
        kind = card_operations.DEAL_FOUR,
    })
    operations.continue(game, player, {
        selected_id = decks.DESTRUCTION,
    })

    local original = effects.apply

    effects.apply = function(owner)
        owner:random(streams.CARDS, 7)
    end

    local ok, message = pcall(function()
        local result = play.run(game, player, {})

        harness.truthy(result.ready)
        harness.equal(game:draws_used(), 8)
        harness.equal(#state.get(game, player).pending_cards, 2)
    end)

    effects.apply = original

    if not ok then
        error(message)
    end
end

-- Fewer than three cards asks before the source action commits. Refusing
-- this question leaves the deck unchanged and clears the saved prompt.
local function short_triple(ctx)
    local game, player = worshipper(ctx, {})
    local owned = state.get(game, player)

    owned.counts[decks.ESCAPE] = 2
    state.set(game, player, owned)

    operations.prepare(game, player, {
        kind = card_operations.TRIPLE_DRAW,
    })

    local prompt = operations.continue(game, player, {
        selected_id = decks.ESCAPE,
    })

    harness.truthy(prompt.confirmation)
    harness.equal(state.get(game, player).counts[decks.ESCAPE], 2)

    operations.continue(game, player, {
        cancelled = true,
    })

    harness.equal(state.get(game, player).counts[decks.ESCAPE], 2)
    harness.equal(state.get(game, player).pending_kind,
        card_operations.NONE)
end

-- A cancelled replacement retains both the old stack and all deck counts.
-- The commit point is after the replacement and short-stack questions.
local function stack_precommit(ctx)
    local game, player = worshipper(ctx, {})
    local owned = state.get(game, player)

    owned.stack = { cards.CLOUD }
    owned.counts[decks.ESCAPE] = 2
    state.set(game, player, owned)

    local replacement = operations.prepare(game, player, {
        kind = card_operations.STACK_FIVE,
    })

    harness.truthy(replacement.confirmation)
    harness.equal(state.get(game, player).stack[1], cards.CLOUD)

    local cancelled = operations.continue(game, player, {
        cancelled = true,
    })

    harness.truthy(cancelled.message)
    harness.equal(state.get(game, player).stack[1], cards.CLOUD)
    harness.equal(state.get(game, player).counts[decks.ESCAPE], 2)
    harness.equal(state.get(game, player).pending_kind,
        card_operations.NONE)
end

-- Each Stack Five choice consumes one card. Swaps affect the final top
-- card, whose source stack ordering is reversed before later drawing.
local function stack_order(ctx)
    local game, player = worshipper(ctx, {
        {
            bound = 23,
            value = 0,
        },
        {
            bound = 23,
            value = 9,
        },
    })
    local owned = state.get(game, player)

    owned.counts[decks.ESCAPE] = 2
    state.set(game, player, owned)

    local short = operations.prepare(game, player, {
        kind = card_operations.STACK_FIVE,
    })

    harness.truthy(short.confirmation)

    local choose = operations.continue(game, player, {
        confirmed = true,
    })

    harness.equal(choose.selection.kind, selection_kinds.CARD)

    local second = operations.continue(game, player, {
        selected_id = decks.ESCAPE,
    })

    harness.equal(second.selection.kind, selection_kinds.CARD)

    local ordering = operations.continue(game, player, {
        selected_id = decks.ESCAPE,
    })

    harness.equal(#ordering.selection.options, 3)
    harness.equal(state.get(game, player).counts[decks.ESCAPE], 0)
    harness.equal(state.get(game, player).pending_cards[1], cards.CLOUD)
    harness.equal(state.get(game, player).pending_cards[2], cards.ELIXIR)

    operations.continue(game, player, { selected_id = "1" })
    operations.continue(game, player, { selected_id = "2" })

    local done = operations.continue(game, player, {
        selected_id = "done",
    })

    harness.truthy(done.ready)
    harness.equal(state.get(game, player).stack[1], cards.CLOUD)
    harness.equal(state.get(game, player).stack[2], cards.ELIXIR)
    harness.equal(state.get(game, player).pending_kind,
        card_operations.STACK_FIVE)
    harness.equal(state.get(game, player).pending_phase,
        card_phases.READY)
end

-- The test reuses production IDs and definitions without a copied pool.
function test.run(ctx)
    weighted_escape(ctx)
    distinct_pools(ctx)
    single_draw(ctx)
    triple_draw(ctx)
    deal_four(ctx)
    deal_rng_order(ctx)
    short_triple(ctx)
    stack_precommit(ctx)
    stack_order(ctx)
end

return test
