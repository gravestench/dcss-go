-- Theory of operation: a sampled card is a saved fact, while its effect is
-- a Lua module named by the effective catalog. Deal Four advances through
-- those facts in order; a target prompt pauses the loop without rerolling.
local card_operations = require("constants.card_operations")
local card_phases = require("constants.card_phases")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local effects = require("policy.religion.cards.effects.dispatch")
local draw = require("policy.religion.cards.draw")
local cards = require("ids.cards")
local power = require("policy.religion.cards.power")
local state = require("policy.religion.cards.state")
local targeted_effect = require("policy.religion.cards.effects.targeted")

local play = {}

-- The current slot is the only card that may run. Save a source tier before
-- a target prompt, so restoring the prompt cannot consume new tier RNG.
local function current_request(ctx, player, owned, response)
    local card_id = owned.pending_cards[owned.pending_selected]

    if not card_id then
        error("pending card action has no selected card")
    end

    local module = effects.module(card_id)
    local strength = power.value(ctx, player, false)

    if module.uses_tier and owned.pending_tier < 0 then
        owned.pending_tier = power.level(ctx, strength)
        state.set(ctx, player, owned)
    end

    return card_id, {
        power = strength,
        tier = owned.pending_tier,
        dealt = owned.pending_kind == card_operations.DEAL_FOUR,
        punishment = false,
        target_id = response.target_id,
        dx = response.dx,
        dy = response.dy,
        confirmed_friendly = response.confirmed_friendly,
        target_phase = owned.pending_phase == card_phases.TARGET_CARD,
    }
end

-- Deal Four samples its next card only after the previous effect finishes.
-- Effects can consume RNG themselves, so presampling would change source
-- card IDs and every later roll in the same deal.
local function advance(ctx, player, owned)
    if owned.pending_kind == card_operations.DEAL_FOUR and
        owned.pending_selected < owned.pending_target_count then
        local deck_id = owned.pending_deck

        ctx:emit("religion", "You deal a card...")

        owned.counts[deck_id] = owned.counts[deck_id] - 1
        owned.pending_cards[#owned.pending_cards + 1] =
            draw.sample(ctx, deck_id)
        owned.pending_selected = owned.pending_selected + 1
        owned.pending_phase = card_phases.RESOLVE_CARD
        owned.pending_tier = -1
        state.set(ctx, player, owned)

        return false
    end

    owned.pending_phase = card_phases.READY
    owned.pending_tier = -1
    state.set(ctx, player, owned)

    return true
end

-- A postcommit target cancellation asks before wasting that sampled card.
-- Declining the waste prompt resumes aim with the same saved power tier.
local function target_response(ctx, player, owned, response)
    if owned.pending_phase == card_phases.TARGET_CARD and
        response.cancelled then
        owned.pending_phase = card_phases.CONFIRM_WASTE
        state.set(ctx, player, owned)

        return {
            confirmation = "Really abort and waste the card?",
        }
    end

    if owned.pending_phase == card_phases.CONFIRM_WASTE then
        if response.forced then
            return nil, true
        end

        owned.pending_phase = card_phases.TARGET_CARD
        state.set(ctx, player, owned)

        return nil, false
    end

    return nil, false
end

-- Apply each available effect before the ability ends its turn, matching
-- source _do_ability's uncancelled card prompts and final cost payment.
function play.run(ctx, player, response)
    response = response or {}

    while true do
        local owned = state.get(ctx, player)

        if owned.pending_phase == card_phases.READY then
            return { ready = true }
        end

        if owned.pending_phase == card_phases.CONFIRM_FRIENDLY then
            -- Yes replays the saved aim; no returns to the same card's aim
            -- prompt. Both answers preserve the already sampled card/tier.
            if not response.forced and not response.cancelled then
                return {
                    confirmation = targeted_effect.FRIENDLY_CONFIRMATION,
                }
            end

            local accepted = response.forced
            local dx, dy = owned.pending_dx, owned.pending_dy

            owned.pending_phase = card_phases.TARGET_CARD
            owned.pending_dx = 0
            owned.pending_dy = 0
            state.set(ctx, player, owned)
            response = accepted and {
                dx = dx,
                dy = dy,
                confirmed_friendly = true,
            } or {}
        end

        local prompt, wasted = target_response(ctx, player, owned, response)

        if prompt then
            return prompt
        end

        if wasted then
            if advance(ctx, player, owned) then
                return { ready = true }
            end

            response = {}
        else
            local card_id, request = current_request(ctx, player,
                owned, response)
            local targeted = card_id == cards.VITRIOL or
                card_id == cards.PAIN or card_id == cards.ORB

            if owned.pending_phase == card_phases.RESOLVE_CARD and
                not targeted then
                local verb = request.dealt and "dealt" or "drawn"
                local definition = catalog.get(categories.CARDS, card_id)

                ctx:emit("religion", "You have " .. verb .. " " ..
                    definition.name .. ".")
            end

            local result = effects.apply(ctx, player, card_id, request)

            if result and result.selection then
                owned.pending_phase = card_phases.TARGET_CARD
                state.set(ctx, player, owned)

                return result
            end

            if result and result.friendly_confirmation then
                owned.pending_phase = card_phases.CONFIRM_FRIENDLY
                owned.pending_dx = request.dx
                owned.pending_dy = request.dy
                state.set(ctx, player, owned)

                return { confirmation = result.friendly_confirmation }
            end

            if result and result.confirmation then
                owned.pending_phase = card_phases.CONFIRM_WASTE
                state.set(ctx, player, owned)

                return result
            end

            if advance(ctx, player, owned) then
                return { ready = true }
            end

            response = {}
        end
    end
end

return play
