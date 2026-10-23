-- The deck owner uses production card definitions and the real ECS schema.
-- These assertions protect saved IDs and deck limits before actions use them.
local cards = require("ids.cards")
local card_rules = require("policy.religion.cards.catalog")
local card_operations = require("constants.card_operations")
local card_phases = require("constants.card_phases")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local decks = require("ids.decks")
local harness = require("tests.harness")
local state = require("policy.religion.cards.state")

local test = {}

-- Every active source card is registered once under its stable ID. The
-- player sees a display name, which need not resemble that internal ID.
local function card_catalog()
    local definitions = catalog.all(categories.CARDS)

    harness.equal(#definitions, 21)
    harness.equal(catalog.get(categories.CARDS, cards.SUMMON_BEE).name,
        "the Swarm")
    harness.equal(catalog.get(categories.CARDS, cards.SUMMON_DEMON).name,
        "the Pentagram")
    harness.equal(catalog.get(categories.CARDS, cards.DEGEN).name,
        "Degeneration")
    harness.equal(catalog.get(categories.CARDS, cards.TOMB)
        .deck_weights[decks.ESCAPE], 5)
    harness.equal(catalog.get(categories.CARDS, cards.EXILE)
        .deck_weights[decks.ESCAPE], 3)
    harness.equal(catalog.get(categories.CARDS, cards.DEGEN)
        .deck_weights[decks.DESTRUCTION], 3)

    for index = 2, #definitions do
        harness.truthy(definitions[index - 1].id < definitions[index].id,
            "card traversal must be stable across mod file order")
    end
end

-- A modded weight must fail validation at boot instead of making a later
-- random selection depend on malformed or empty content.
local function invalid_definition()
    local original = catalog.get(categories.CARDS, cards.TOMB)
    local replacement = {
        id = original.id,
        name = original.name,
        effect_module = original.effect_module,
        deck_weights = {
            [decks.ESCAPE] = -1,
        },
    }

    local ok, message = pcall(card_rules.validate_definition,
        replacement)

    harness.falsy(ok)
    harness.truthy(string.find(message, cards.TOMB, 1, true))
end

-- A new worshipper owns no cards. Saving a stack preserves its order and
-- a pending Triple Draw choice instead of recomputing random cards later.
local function durable_state(ctx)
    local player = ctx:create()
    local initial = state.get(ctx, player)

    harness.equal(initial.counts[decks.ESCAPE] or 0, 0)
    harness.equal(initial.counts[decks.DESTRUCTION] or 0, 0)
    harness.equal(initial.counts[decks.SUMMONING] or 0, 0)

    initial.counts[decks.ESCAPE] = 13
    initial.counts[decks.DESTRUCTION] = 26
    initial.counts[decks.SUMMONING] = 13
    initial.stack = { cards.TOMB, cards.ELIXIR }
    initial.pending_kind = card_operations.TRIPLE_DRAW
    initial.pending_phase = card_phases.CHOOSE_CARD
    initial.pending_deck = decks.ESCAPE
    initial.pending_cards = { cards.EXILE, cards.CLOUD }
    initial.pending_target_count = 2

    state.set(ctx, player, initial)

    local saved = ctx:get(player, component.RELIGION_NEMELEX_DECKS)

    harness.equal(saved.stack[1], cards.TOMB)
    harness.equal(saved.stack[2], cards.ELIXIR)
    harness.equal(saved.pending_cards[2], cards.CLOUD)
    harness.equal(state.get(ctx, player).counts[decks.DESTRUCTION], 26)

    state.clear(ctx, player)

    harness.equal(#state.get(ctx, player).stack, 0)
    harness.equal(state.get(ctx, player).counts[decks.ESCAPE] or 0, 0)
end

-- Mod removal must be diagnosed rather than replacing or discarding a
-- previously saved card. The validator also rejects source-limit overflow.
local function invalid_state(ctx)
    local player = ctx:create()
    local saved = state.get(ctx, player)

    saved.stack = { "CARD_UNKNOWN_MOD" }

    local ok, message = pcall(state.set, ctx, player, saved)

    harness.falsy(ok)
    harness.truthy(string.find(message, "CARD_UNKNOWN_MOD", 1, true))

    saved.stack = {}
    saved.counts[decks.ESCAPE] = 14

    harness.falsy(pcall(state.set, ctx, player, saved))

    saved.counts[decks.ESCAPE] = 0
    saved.stack = {
        cards.TOMB,
        cards.TOMB,
        cards.TOMB,
        cards.TOMB,
        cards.TOMB,
        cards.TOMB,
    }

    harness.falsy(pcall(state.set, ctx, player, saved),
        "Stack Five must never save a sixth card")
end

-- The test imports the same schema and definitions as production gameplay.
function test.run(ctx)
    card_catalog()
    invalid_definition()
    durable_state(ctx)
    invalid_state(ctx)
end

return test
