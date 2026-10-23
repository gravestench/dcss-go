-- Shared deck mechanics know card names, source deck counts, and prompts.
-- They do not decide which action may spend a card or when it completes.
local card_operations = require("constants.card_operations")
local card_phases = require("constants.card_phases")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local decks = require("ids.decks")
local draw = require("policy.religion.cards.draw")
local selection_kinds = require("constants.selection_kinds")

local shared = {}

shared.player_decks = {
    decks.ESCAPE,
    decks.DESTRUCTION,
    decks.SUMMONING,
}

shared.deck_names = {
    [decks.ESCAPE] = "Deck of Escape",
    [decks.DESTRUCTION] = "Deck of Destruction",
    [decks.SUMMONING] = "Deck of Summoning",
}

-- Cancel or finish an operation without disturbing an existing stack or
-- deck counts. Callers save the resulting player component afterward.
function shared.clear_pending(owned)
    owned.pending_kind = card_operations.NONE
    owned.pending_phase = card_phases.NONE
    owned.pending_deck = ""
    owned.pending_cards = {}
    owned.pending_target_count = 0
    owned.pending_selected = 0
    owned.pending_failed = false
    owned.pending_tier = -1
end

-- Only the three owned decks count toward Stack Five. Punishment is never
-- player-owned, and an old stack is a collection of concrete cards.
function shared.total_cards(owned)
    local total = 0

    for _, deck_id in ipairs(shared.player_decks) do
        total = total + (owned.counts[deck_id] or 0)
    end

    return total
end

-- The terminal receives stable deck IDs and visible labels, while the
-- saved component remains the authority for available card counts.
function shared.deck_prompt(owned)
    local options = {}

    for _, deck_id in ipairs(shared.player_decks) do
        if (owned.counts[deck_id] or 0) > 0 then
            local count = owned.counts[deck_id]
            local noun = count == 1 and " card)" or " cards)"

            options[#options + 1] = {
                id = deck_id,
                label = shared.deck_names[deck_id] .. " (" ..
                    count .. noun,
            }
        end
    end

    if #options == 0 then
        return { message = "You have no cards to draw." }
    end

    return {
        selection = {
            kind = selection_kinds.CARD,
            title = "Draw from which deck?",
            options = options,
        },
    }
end

-- Slot IDs remain unique even when a deck samples the same card twice.
-- Visible names come from the effective mod catalog at prompt time.
function shared.card_prompt(owned)
    local options = {}

    for slot, card_id in ipairs(owned.pending_cards) do
        local definition = catalog.get(categories.CARDS, card_id)

        options[#options + 1] = {
            id = tostring(slot),
            label = definition.name,
        }
    end

    return {
        selection = {
            kind = selection_kinds.CARD,
            title = "Choose a card to play",
            options = options,
        },
    }
end

-- The selected ID is read from saved samples, never from a terminal label.
function shared.selected_card(owned)
    return { card_id = owned.pending_cards[owned.pending_selected] }
end

-- One call consumes at most the requested number of cards, sampling each
-- concrete ID in order. The action owner chooses the next pending phase.
function shared.take_cards(ctx, owned, deck_id, count)
    local available = owned.counts[deck_id] or 0

    if available <= 0 then
        return nil, { message = "That deck is empty." }
    end

    local taken = math.min(available, count)

    owned.counts[deck_id] = available - taken
    owned.pending_deck = deck_id
    owned.pending_cards = {}
    owned.pending_target_count = taken

    for _ = 1, taken do
        owned.pending_cards[#owned.pending_cards + 1] =
            draw.sample(ctx, deck_id)
    end

    return taken
end

return shared
