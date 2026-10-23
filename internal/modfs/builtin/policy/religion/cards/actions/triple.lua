-- Triple Draw selects a deck before committing, then reveals up to three
-- concrete cards and stores the player's one chosen slot for resolution.
local card_operations = require("constants.card_operations")
local card_phases = require("constants.card_phases")
local shared = require("policy.religion.cards.actions.shared")
local state = require("policy.religion.cards.state")

local triple = {}

-- Source permits a short deck only after a separate confirmation. This
-- prompt is saved so refusing or restoring cannot reroll a card.
local function short_prompt()
    return {
        confirmation = "There are fewer than three cards. Draw anyway?",
    }
end

-- Spend up to three counts once. A one-card deck needs no choice menu;
-- two or three cards ask for a stable numbered slot.
local function commit(ctx, player, owned, deck_id)
    local taken, rejection = shared.take_cards(ctx, owned, deck_id, 3)

    if not taken then
        return rejection
    end

    if taken == 1 then
        owned.pending_phase = card_phases.RESOLVE_CARD
        owned.pending_selected = 1
        state.set(ctx, player, owned)

        return shared.selected_card(owned)
    end

    owned.pending_phase = card_phases.CHOOSE_CARD
    state.set(ctx, player, owned)

    return shared.card_prompt(owned)
end

-- Asking for the deck is free. The operation becomes pending so a save at
-- this prompt resumes the same action rather than permitting movement.
function triple.prepare(ctx, player, owned)
    local prompt = shared.deck_prompt(owned)

    if prompt.selection then
        owned.pending_kind = card_operations.TRIPLE_DRAW
        owned.pending_phase = card_phases.CHOOSE_DECK
        state.set(ctx, player, owned)
    end

    return prompt
end

-- Reconstruct a prompt from saved state without changing card counts.
function triple.resume(owned)
    if owned.pending_phase == card_phases.CHOOSE_DECK then
        return shared.deck_prompt(owned)
    end

    if owned.pending_phase == card_phases.SHORT_TRIPLE then
        return short_prompt()
    end

    if owned.pending_phase == card_phases.CHOOSE_CARD then
        return shared.card_prompt(owned)
    end

    return shared.selected_card(owned)
end

-- Cancellation is free until sampling; afterward the numbered choice is
-- uncancelled because its cards were already consumed.
function triple.continue(ctx, player, owned, response)
    local phase = owned.pending_phase

    if response.cancelled and
        (phase == card_phases.CHOOSE_DECK or
            phase == card_phases.SHORT_TRIPLE) then
        shared.clear_pending(owned)
        state.set(ctx, player, owned)

        return { message = "Okay." }
    end

    if phase == card_phases.CHOOSE_DECK then
        local deck_id = response.selected_id

        if not shared.deck_names[deck_id] then
            return shared.deck_prompt(owned)
        end

        if owned.counts[deck_id] < 3 then
            owned.pending_deck = deck_id
            owned.pending_phase = card_phases.SHORT_TRIPLE
            state.set(ctx, player, owned)

            return short_prompt()
        end

        return commit(ctx, player, owned, deck_id)
    end

    if phase == card_phases.SHORT_TRIPLE then
        if not response.confirmed then
            return short_prompt()
        end

        return commit(ctx, player, owned, owned.pending_deck)
    end

    if phase == card_phases.CHOOSE_CARD then
        local slot = tonumber(response.selected_id)

        if not slot or slot % 1 ~= 0 or
            slot < 1 or slot > #owned.pending_cards then
            return shared.card_prompt(owned)
        end

        owned.pending_selected = slot
        owned.pending_phase = card_phases.RESOLVE_CARD
        state.set(ctx, player, owned)
    end

    return shared.selected_card(owned)
end

return triple
