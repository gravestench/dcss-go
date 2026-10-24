-- Theory of operation: Nemelex owns card counts, an ordered stack, and
-- postcommit choices on the player's ECS entity. Rules never infer cards
-- from a seed after a save because draws have already spent their RNG.
local card_operations = require("constants.card_operations")
local card_phases = require("constants.card_phases")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local decks = require("ids.decks")

local state = {}

local maxima = {
    [decks.ESCAPE] = 13,
    [decks.DESTRUCTION] = 26,
    [decks.SUMMONING] = 13,
}

local operations = {
    [card_operations.DRAW] = true,
    [card_operations.TRIPLE_DRAW] = true,
    [card_operations.DEAL_FOUR] = true,
    [card_operations.STACK_FIVE] = true,
}

local phases = {}

for _, phase in pairs(card_phases) do
    if phase ~= card_phases.NONE then
        phases[phase] = true
    end
end

-- Build a fresh empty value for a new worshipper or a departed one. Map
-- omissions mean zero, letting mods add deck IDs without a schema change.
local function empty()
    return {
        counts = {},
        stack = {},
        pending_kind = card_operations.NONE,
        pending_phase = card_phases.NONE,
        pending_deck = "",
        pending_cards = {},
        pending_target_count = 0,
        pending_selected = 0,
        pending_failed = false,
        pending_tier = -1,
        pending_dx = 0,
        pending_dy = 0,
    }
end

-- Reject card IDs missing from the effective mod catalog before an action
-- can silently replace them with a different random draw.
local function known_card(card_id)
    catalog.get(categories.CARDS, card_id)
end

-- The three player decks have source limits. Punishment has no owned count,
-- and the stack stores concrete card IDs instead of a fourth random pool.
local function validate_counts(counts)
    for deck_id, count in pairs(counts) do
        local maximum = maxima[deck_id]

        if not maximum then
            error("unknown player deck " .. tostring(deck_id))
        end

        if type(count) ~= "number" or count % 1 ~= 0 or
            count < 0 or count > maximum then
            error("invalid card count for " .. deck_id)
        end
    end
end

-- Check saved stack and pending samples against mod content. Validation
-- happens on read too, so a changed mod fails at the first deck access.
local function validate_cards(cards)
    for _, card_id in ipairs(cards) do
        known_card(card_id)
    end
end

-- Keep an interrupted action's phase explicit, including the difference
-- between no pending prompt and an uncancelled postcommit choice.
local function validate_pending(value)
    local kind = value.pending_kind
    local phase = value.pending_phase

    if kind == card_operations.NONE then
        if phase ~= card_phases.NONE or value.pending_deck ~= "" or
            #value.pending_cards > 0 or
            value.pending_target_count ~= 0 or
            value.pending_selected ~= 0 or
            value.pending_failed or
            value.pending_tier ~= -1 or
            value.pending_dx ~= 0 or value.pending_dy ~= 0 then
            error("inactive card operation has pending values")
        end

        return
    end

    if not operations[kind] or not phases[phase] then
        error("unknown pending card operation " .. tostring(kind) ..
            "/" .. tostring(phase))
    end

    if value.pending_deck ~= "" and
        not maxima[value.pending_deck] and
        value.pending_deck ~= decks.STACK then
        error("unknown pending card deck " .. tostring(value.pending_deck))
    end

    if value.pending_target_count < 0 or
        value.pending_target_count > 5 or
        value.pending_selected < 0 or
        value.pending_selected > 5 then
        error("invalid pending card choice")
    end

    if value.pending_tier < -1 or value.pending_tier > 2 then
        error("invalid pending card power tier")
    end

    if phase == card_phases.CONFIRM_FRIENDLY then
        local dx = value.pending_dx
        local dy = value.pending_dy

        if dx % 1 ~= 0 or dy % 1 ~= 0 or
            (dx == 0 and dy == 0) or
            math.max(math.abs(dx), math.abs(dy)) > 7 then
            error("invalid pending friendly-fire ray")
        end
    elseif value.pending_dx ~= 0 or value.pending_dy ~= 0 then
        error("card aim saved outside friendly-fire confirmation")
    end
end

-- Example: a restored Triple Draw retains both sampled IDs even if a
-- later mod changes their weights. The source action must finish first.
local function validate(value)
    validate_counts(value.counts)

    if #value.stack > 5 then
        error("Nemelex stack exceeds five cards")
    end

    if #value.pending_cards > 5 then
        error("pending card draw exceeds five cards")
    end

    validate_cards(value.stack)
    validate_cards(value.pending_cards)
    validate_pending(value)

    return value
end

-- Read saved ownership or provide a fresh zero state without consuming
-- RNG. The caller must write it through `state.set` to make it durable.
function state.get(ctx, player)
    local value = ctx:get(player, component.RELIGION_NEMELEX_DECKS)

    return validate(value or empty())
end

-- Validate before writing so gameplay and mod calls share one boundary.
function state.set(ctx, player, value)
    validate(value)

    if ctx:has(player, component.RELIGION_NEMELEX_DECKS) then
        ctx:set(player, component.RELIGION_NEMELEX_DECKS, value)
    else
        ctx:add(player, component.RELIGION_NEMELEX_DECKS, value)
    end
end

-- Renunciation revokes cards and pending prompts in the same owner that
-- creates them. Lifetime gift history stays with `religion.worship`.
function state.clear(ctx, player)
    state.set(ctx, player, empty())
end

-- Restore runs this read-only policy after loading dynamic components.
-- It names missing mod cards before normal play can redraw or discard them.
function state.validate_save(ctx)
    state.get(ctx, ctx:player())

    return {}
end

register.policy({
    id = "save.validate_nemelex_decks",
    run = state.validate_save,
})

return state
