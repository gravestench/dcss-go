-- Draw one spends a count immediately after the deck is chosen, then keeps
-- that sampled card until its effect finishes. Stack draws pop its top ID.
local card_operations = require("constants.card_operations")
local card_phases = require("constants.card_phases")
local decks = require("ids.decks")
local shared = require("policy.religion.cards.actions.shared")
local state = require("policy.religion.cards.state")

local single = {}

-- A normal deck samples one card; the ordered stack already knows its top
-- card, so drawing it consumes no additional card-selection RNG.
function single.prepare(ctx, player, owned, request)
    local deck_id = request.deck_id

    if deck_id == decks.STACK then
        if #owned.stack == 0 then
            return { message = "That deck is empty." }
        end

        ctx:emit("religion", "You draw a card...")

        local card_id = table.remove(owned.stack)

        owned.pending_cards = { card_id }
        owned.pending_deck = deck_id
        owned.pending_target_count = 1
    else
        if not shared.deck_names[deck_id] then
            return { message = "Choose a player deck." }
        end

        if (owned.counts[deck_id] or 0) > 0 then
            ctx:emit("religion", "You draw a card...")
        end

        local taken, rejection = shared.take_cards(ctx, owned,
            deck_id, 1)

        if not taken then
            return rejection
        end
    end

    owned.pending_kind = card_operations.DRAW
    owned.pending_phase = card_phases.RESOLVE_CARD
    owned.pending_selected = 1
    state.set(ctx, player, owned)

    return shared.selected_card(owned)
end

-- Reopening an interrupted draw returns the exact saved card, with no
-- second count change or random sample.
function single.resume(owned)
    return shared.selected_card(owned)
end

-- No source choice follows a single draw. The effect owner completes it.
function single.continue(_, _, owned)
    return single.resume(owned)
end

return single
