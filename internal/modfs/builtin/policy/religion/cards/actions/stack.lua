-- Stack Five protects the old stack through its two precommit questions.
-- After commitment, every selected deck spends one card into a saved list;
-- the player swaps slots, then the final list becomes a top-first stack.
local card_operations = require("constants.card_operations")
local card_phases = require("constants.card_phases")
local draw = require("policy.religion.cards.draw")
local shared = require("policy.religion.cards.actions.shared")
local state = require("policy.religion.cards.state")

local stack = {}

-- Keep source's replacement question before its short-deck question so a
-- declined replacement never touches the existing ordered cards.
local function confirmation(phase)
    if phase == card_phases.REPLACE_STACK then
        return { confirmation = "Replace your current stack?" }
    end

    return {
        confirmation = "You have fewer than five cards. Stack them anyway?",
    }
end

-- Stack ordering is expressed as pairs of numbered slots plus a distinct
-- Done choice. A saved first slot can resume after an interrupted menu.
local function ordering_prompt(owned)
    local prompt = shared.card_prompt(owned)

    prompt.selection.title = "Select two cards to swap, then finish"
    prompt.selection.options[#prompt.selection.options + 1] = {
        id = "done",
        label = "Finish stack",
    }

    return prompt
end

-- This is the one-way commitment: replace the old stack and save the
-- target card count before asking for any deck draw.
local function begin(ctx, player, owned)
    owned.stack = {}
    owned.pending_cards = {}
    owned.pending_selected = 0
    owned.pending_target_count = math.min(shared.total_cards(owned), 5)
    owned.pending_phase = card_phases.DRAW_STACK
    state.set(ctx, player, owned)

    return shared.deck_prompt(owned)
end

-- Ask the next source precommit question, or begin immediately when five
-- cards are available and there is no old stack to replace.
function stack.prepare(ctx, player, owned)
    if #owned.stack > 0 then
        owned.pending_kind = card_operations.STACK_FIVE
        owned.pending_phase = card_phases.REPLACE_STACK
        state.set(ctx, player, owned)

        return confirmation(owned.pending_phase)
    end

    local total = shared.total_cards(owned)

    if total == 0 then
        return { message = "You are out of cards." }
    end

    owned.pending_kind = card_operations.STACK_FIVE

    if total < 5 then
        owned.pending_phase = card_phases.SHORT_STACK
        state.set(ctx, player, owned)

        return confirmation(owned.pending_phase)
    end

    return begin(ctx, player, owned)
end

-- Rebuild the saved prompt without deciding a new deck or sampling a card.
function stack.resume(owned)
    local phase = owned.pending_phase

    if phase == card_phases.REPLACE_STACK or
        phase == card_phases.SHORT_STACK then
        return confirmation(phase)
    end

    if phase == card_phases.DRAW_STACK then
        return shared.deck_prompt(owned)
    end

    if phase == card_phases.READY then
        return { ready = true }
    end

    return ordering_prompt(owned)
end

-- Confirmation checks current card supply again, preserving the old stack
-- if the player declines or no available deck remains.
local function answer_confirmation(ctx, player, owned, response)
    local phase = owned.pending_phase

    if response.cancelled then
        shared.clear_pending(owned)
        state.set(ctx, player, owned)

        return { message = "Okay." }
    end

    if not response.confirmed then
        return confirmation(phase)
    end

    if phase == card_phases.REPLACE_STACK then
        local total = shared.total_cards(owned)

        if total == 0 then
            shared.clear_pending(owned)
            state.set(ctx, player, owned)

            return { message = "You are out of cards." }
        end

        if total < 5 then
            owned.pending_phase = card_phases.SHORT_STACK
            state.set(ctx, player, owned)

            return confirmation(owned.pending_phase)
        end
    end

    return begin(ctx, player, owned)
end

-- Each deck answer consumes one count and samples one card. This allows a
-- mixed stack without adding another deck-specific dispatch path.
local function choose_deck(ctx, player, owned, response)
    local deck_id = response.selected_id

    if not shared.deck_names[deck_id] or
        (owned.counts[deck_id] or 0) == 0 then
        return shared.deck_prompt(owned)
    end

    owned.counts[deck_id] = owned.counts[deck_id] - 1
    owned.pending_cards[#owned.pending_cards + 1] =
        draw.sample(ctx, deck_id)

    if #owned.pending_cards == owned.pending_target_count then
        owned.pending_phase = card_phases.ORDER_STACK
        state.set(ctx, player, owned)

        return ordering_prompt(owned)
    end

    state.set(ctx, player, owned)

    return shared.deck_prompt(owned)
end

-- Swapping two displayed slots changes only their saved order. Source
-- reverses that order at acceptance because draws later pop the last ID.
local function choose_order(ctx, player, owned, response)
    local selected = response.selected_id

    if selected == "done" then
        for index = #owned.pending_cards, 1, -1 do
            owned.stack[#owned.stack + 1] = owned.pending_cards[index]
        end

        owned.pending_phase = card_phases.READY
        owned.pending_selected = 0
        state.set(ctx, player, owned)

        return { ready = true }
    end

    local slot = tonumber(selected)

    if not slot or slot % 1 ~= 0 or
        slot < 1 or slot > #owned.pending_cards then
        return ordering_prompt(owned)
    end

    if owned.pending_selected == 0 then
        owned.pending_selected = slot
    else
        local previous = owned.pending_selected

        owned.pending_cards[previous], owned.pending_cards[slot] =
            owned.pending_cards[slot], owned.pending_cards[previous]
        owned.pending_selected = 0
    end

    state.set(ctx, player, owned)

    return ordering_prompt(owned)
end

-- Delegate each saved Stack Five phase to its small named operation.
function stack.continue(ctx, player, owned, response)
    local phase = owned.pending_phase

    if phase == card_phases.REPLACE_STACK or
        phase == card_phases.SHORT_STACK then
        return answer_confirmation(ctx, player, owned, response)
    end

    if phase == card_phases.DRAW_STACK then
        return choose_deck(ctx, player, owned, response)
    end

    if phase == card_phases.READY then
        return { ready = true }
    end

    return choose_order(ctx, player, owned, response)
end

return stack
