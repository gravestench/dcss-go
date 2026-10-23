-- Deal Four chooses one player deck, then samples and plays each card in
-- draw order. The next ID is unknown until the previous effect finishes.
local card_operations = require("constants.card_operations")
local card_phases = require("constants.card_phases")
local draw = require("policy.religion.cards.draw")
local shared = require("policy.religion.cards.actions.shared")
local state = require("policy.religion.cards.state")

local deal = {}

-- The deck question precedes source failure and card consumption.
function deal.prepare(ctx, player, owned)
    local prompt = shared.deck_prompt(owned)

    if prompt.selection then
        owned.pending_kind = card_operations.DEAL_FOUR
        owned.pending_phase = card_phases.CHOOSE_DECK
        state.set(ctx, player, owned)
    end

    return prompt
end

-- Restoring the action asks for the deck or resumes the current dealt
-- card; it never reselects already sampled cards.
function deal.resume(owned)
    if owned.pending_phase == card_phases.CHOOSE_DECK then
        return shared.deck_prompt(owned)
    end

    return shared.selected_card(owned)
end

-- Before a deck is selected the player may back out for free. The selected
-- deck fixes the deal count, but only its first card is sampled now. Source
-- `_evoke_deck` resolves that card before sampling the second one.
function deal.continue(ctx, player, owned, response)
    if owned.pending_phase ~= card_phases.CHOOSE_DECK then
        return shared.selected_card(owned)
    end

    if response.cancelled then
        shared.clear_pending(owned)
        state.set(ctx, player, owned)

        return { message = "Okay." }
    end

    local deck_id = response.selected_id

    if not shared.deck_names[deck_id] then
        return shared.deck_prompt(owned)
    end

    local available = owned.counts[deck_id] or 0

    if available == 0 then
        return { message = "That deck is empty." }
    end

    ctx:emit("religion", "You deal a card...")

    owned.counts[deck_id] = available - 1
    owned.pending_deck = deck_id
    owned.pending_cards = { draw.sample(ctx, deck_id) }
    owned.pending_target_count = math.min(available, 4)
    owned.pending_phase = card_phases.RESOLVE_CARD
    owned.pending_selected = 1
    state.set(ctx, player, owned)

    return shared.selected_card(owned)
end

return deal
