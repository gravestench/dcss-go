-- Theory of operation: Nemelex's menu entries are ordinary Lua abilities.
-- Their definitions supply rank, cost, and deck choice; the shared deck
-- owner saves all samples and prompts. Each menu entry remains small so a
-- new deck action does not add another command-dispatch branch in Go.
local abilities = require("ids.abilities")
local card_operations = require("constants.card_operations")
local card_phases = require("constants.card_phases")
local component = require("constants.component")
local decks = require("ids.decks")
local gods = require("constants.gods")
local magic_power = require("policy.magic.power")
local operations = require("policy.religion.cards.operations")
local piety = require("policy.religion.piety")
local registry = require("policy.abilities.registry")
local roll = require("policy.combat.roll")
local skill_ids = require("ids.skills")
local state = require("policy.religion.cards.state")
local streams = require("constants.rng_streams")
local shared = require("policy.religion.cards.actions.shared")

local nemelex = {}

local definitions = {
    {
        id = abilities.NEMELEX_DRAW_ESCAPE,
        name = "Draw Escape",
        kind = card_operations.DRAW,
        deck_id = decks.ESCAPE,
        rank = 0,
        mp_cost = 0,
        piety_cost = 0,
    },
    {
        id = abilities.NEMELEX_DRAW_DESTRUCTION,
        name = "Draw Destruction",
        kind = card_operations.DRAW,
        deck_id = decks.DESTRUCTION,
        rank = 0,
        mp_cost = 0,
        piety_cost = 0,
    },
    {
        id = abilities.NEMELEX_DRAW_SUMMONING,
        name = "Draw Summoning",
        kind = card_operations.DRAW,
        deck_id = decks.SUMMONING,
        rank = 0,
        mp_cost = 0,
        piety_cost = 0,
    },
    {
        id = abilities.NEMELEX_DRAW_STACK,
        name = "Draw Stack",
        kind = card_operations.DRAW,
        deck_id = decks.STACK,
        rank = 0,
        mp_cost = 0,
        piety_cost = 0,
    },
    {
        id = abilities.NEMELEX_TRIPLE_DRAW,
        name = "Triple Draw",
        kind = card_operations.TRIPLE_DRAW,
        rank = 3,
        mp_cost = 2,
        piety_cost = 6,
    },
    {
        id = abilities.NEMELEX_DEAL_FOUR,
        name = "Deal Four",
        kind = card_operations.DEAL_FOUR,
        rank = 4,
        mp_cost = 8,
        piety_cost = 4,
    },
    {
        id = abilities.NEMELEX_STACK_FIVE,
        name = "Stack Five",
        kind = card_operations.STACK_FIVE,
        rank = 5,
        mp_cost = 5,
        piety_cost = 10,
    },
}

local by_id = {}

for _, definition in ipairs(definitions) do
    by_id[definition.id] = definition
end

-- Source invocation failure is not a single shared percentage. Triple
-- and Stack use separate scales; Deal Four has its own special expression.
function nemelex.failure_chance(ctx, player, ability_id)
    local definition = by_id[ability_id]

    if not definition then
        error("unknown Nemelex ability " .. tostring(ability_id))
    end

    if definition.kind == card_operations.DRAW then
        return 0
    end

    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local points = worship.piety

    if definition.kind == card_operations.TRIPLE_DRAW then
        local skill = magic_power.training(ctx, player,
            skill_ids.SK_INVOCATIONS, 5)

        return math.max(0, 60 - skill - math.floor(points / 20))
    end

    if definition.kind == card_operations.DEAL_FOUR then
        local skill = magic_power.training(ctx, player,
            skill_ids.SK_INVOCATIONS, 9)

        return math.max(0, 70 - math.floor(points * 2 / 45) -
            math.floor(skill / 2))
    end

    local skill = magic_power.training(ctx, player,
        skill_ids.SK_INVOCATIONS, 4)

    return math.max(0, 80 - skill - math.floor(points / 25))
end

-- Only the ability that created the saved action may answer its prompt.
-- A move, renunciation, or another deck action cannot consume that choice.
function nemelex.pending_command(ctx, player, ability_id)
    local owned = state.get(ctx, player)

    if owned.pending_kind == card_operations.NONE then
        return true
    end

    for _, definition in ipairs(definitions) do
        if definition.id == ability_id and
            definition.kind == owned.pending_kind and
            (definition.kind ~= card_operations.DRAW or
                definition.deck_id == owned.pending_deck) then
            return true
        end
    end

    return false
end

-- Source ability gates use the live worship rank and available card supply.
-- Pending work stays available even when the chosen deck is now empty.
function nemelex.available(ctx, player, definition)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    if not worship or worship.god_id ~= gods.NEMELEX_XOBEH or
        piety.rank(worship.god_id, worship.piety) < definition.rank then
        return false
    end

    local owned = state.get(ctx, player)

    if owned.pending_kind ~= card_operations.NONE then
        return owned.pending_kind == definition.kind and
            (definition.kind ~= card_operations.DRAW or
                owned.pending_deck == definition.deck_id)
    end

    if definition.deck_id == decks.STACK then
        return #owned.stack > 0
    end

    if definition.deck_id then
        return (owned.counts[definition.deck_id] or 0) > 0
    end

    for _, deck_id in ipairs({
        decks.ESCAPE,
        decks.DESTRUCTION,
        decks.SUMMONING,
    }) do
        if (owned.counts[deck_id] or 0) > 0 then
            return true
        end
    end

    return false
end

-- Roll only at the source commitment boundary, after a deck and any
-- precommit confirmation are accepted, before sampling or replacing cards.
local function failure_boundary(owned, input, definition)
    if input.cancelled then
        return false
    end

    if definition.kind == card_operations.DRAW then
        return false
    end

    local phase = owned.pending_phase

    if definition.kind == card_operations.STACK_FIVE then
        return input.forced and
            (phase == card_phases.SHORT_STACK or
                (phase == card_phases.REPLACE_STACK and
                    shared.total_cards(owned) >= 5))
    end

    if phase == card_phases.SHORT_TRIPLE then
        return input.forced
    end

    return phase == card_phases.CHOOSE_DECK and
        shared.deck_names[input.target_id] ~= nil and
        (definition.kind ~= card_operations.TRIPLE_DRAW or
            (owned.counts[input.target_id] or 0) >= 3)
end

-- Source abilities compare an average of three bounded draws with their
-- failure chance. A zero-chance Draw still consumes the same three rolls.
local function fails(ctx, player, ability_id)
    local average = roll.average_three(ctx, streams.CARDS, 100)

    return average < nemelex.failure_chance(ctx, player, ability_id)
end

-- The terminal replays the same ability command with a chosen option or a
-- confirmation answer. Only the deck owner interprets the saved phase.
function nemelex.prepare(ctx, player, input, definition)
    local owned = state.get(ctx, player)
    local result

    if owned.pending_kind ~= card_operations.NONE then
        if failure_boundary(owned, input, definition) and
            owned.pending_failed then
            operations.fail(ctx, player, definition.kind)

            return nil
        end

        if owned.pending_phase == card_phases.TARGET_CARD or
            owned.pending_phase == card_phases.CONFIRM_WASTE then
            result = operations.play(ctx, player, input)
        else
            result = operations.continue(ctx, player, {
                selected_id = input.target_id,
                confirmed = input.forced,
                cancelled = input.cancelled,
            })
        end
    else
        if input.cancelled then
            return "Okay."
        end

        if definition.mp_cost > 0 then
            local magic = ctx:get(player, component.MAGIC)

            if not magic or magic.current < definition.mp_cost then
                return "You do not have enough magic."
            end
        end

        local failed = fails(ctx, player, definition.id)

        if failed and definition.kind == card_operations.STACK_FIVE and
            #owned.stack == 0 and
            shared.total_cards(owned) >= 5 then
            operations.fail(ctx, player, definition.kind)

            return nil
        end

        result = operations.prepare(ctx, player, {
            kind = definition.kind,
            deck_id = definition.deck_id,
        })

        if result.selection or result.confirmation then
            local pending = state.get(ctx, player)

            if pending.pending_kind ~= card_operations.NONE then
                pending.pending_failed = failed
                state.set(ctx, player, pending)
            end
        end
    end

    if not result then
        return "Okay."
    end

    if result.card_id then
        result = operations.play(ctx, player, input)
    end

    if result.ready then
        return nil
    end

    return result
end

-- Resolution belongs to the timed action; later card-effect modules read
-- the saved samples rather than trusting an option label from the client.
function nemelex.resolve(ctx, player, intent, aut, definition)
    local owned = state.get(ctx, player)

    if owned.pending_phase == card_phases.FAILED then
        operations.finish(ctx, player)
        ctx:emit("religion", "You fail to use " .. definition.name .. ".")

        return
    end

    if definition.mp_cost > 0 then
        local magic = ctx:get(player, component.MAGIC)

        magic.current = magic.current - definition.mp_cost
        ctx:set(player, component.MAGIC, magic)
    end

    if definition.piety_cost > 0 then
        piety.lose(ctx, player, definition.piety_cost)
    end

    return operations.resolve(ctx, player, intent, aut, definition)
end

-- Register every source action from small definitions. The closures carry
-- immutable menu metadata; mutable cards remain solely on the ECS player.
for _, definition in ipairs(definitions) do
    registry.add(definition.id, {
        name = definition.name,
        -- A postcommit target cancellation can confirm wasting a card,
        -- so generic ability cancellation must not eat that prompt.
        owns_cancellation = true,
        available = function(ctx, player)
            return nemelex.available(ctx, player, definition)
        end,
        prepare = function(ctx, player, input)
            return nemelex.prepare(ctx, player, input, definition)
        end,
        resolve = function(ctx, player, intent, aut)
            return nemelex.resolve(ctx, player, intent, aut,
                definition)
        end,
    })
end

return nemelex
