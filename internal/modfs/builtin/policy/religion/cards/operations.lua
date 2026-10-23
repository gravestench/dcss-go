-- Theory of operation: each Nemelex action owns its own saved phases.
-- This dispatcher selects the action by stable operation ID, while card
-- counts and sampled IDs stay on the player ECS component across menus.
local card_operations = require("constants.card_operations")
local deal = require("policy.religion.cards.actions.deal")
local single = require("policy.religion.cards.actions.single")
local stack = require("policy.religion.cards.actions.stack")
local shared = require("policy.religion.cards.actions.shared")
local card_phases = require("constants.card_phases")
local play = require("policy.religion.cards.play")
local state = require("policy.religion.cards.state")
local triple = require("policy.religion.cards.actions.triple")

local operations = {}

local actions = {
    [card_operations.DRAW] = single,
    [card_operations.TRIPLE_DRAW] = triple,
    [card_operations.DEAL_FOUR] = deal,
    [card_operations.STACK_FIVE] = stack,
}

-- Repeated preparation resumes a saved action instead of sampling anew.
-- The originating ability checks that its ID matches this pending kind.
function operations.prepare(ctx, player, request)
    local owned = state.get(ctx, player)

    if owned.pending_kind ~= card_operations.NONE then
        return actions[owned.pending_kind].resume(owned)
    end

    local action = actions[request.kind]

    if not action then
        return { message = "Unknown card action." }
    end

    return action.prepare(ctx, player, owned, request)
end

-- A menu response always goes to the action named in the saved component.
-- The client cannot redirect a sampled choice by changing a request kind.
function operations.continue(ctx, player, response)
    local owned = state.get(ctx, player)
    local action = actions[owned.pending_kind]

    if not action then
        return { message = "No card action is pending." }
    end

    return action.continue(ctx, player, owned, response)
end

-- A failed invocation still spends the timed action, but leaves resources,
-- the chosen deck count, and the previous stack untouched.
function operations.fail(ctx, player, kind)
    local owned = state.get(ctx, player)

    owned.pending_kind = kind
    owned.pending_phase = card_phases.FAILED
    owned.pending_deck = ""
    owned.pending_cards = {}
    owned.pending_target_count = 0
    owned.pending_selected = 0
    owned.pending_failed = true
    owned.pending_tier = -1
    state.set(ctx, player, owned)
end

-- Card effects run through the named Lua module before the action's one
-- timed intent. An effect may pause on a saved target or abort question.
function operations.play(ctx, player, response)
    return play.run(ctx, player, response)
end

-- Complete the saved operation after its timed outcome has been applied.
function operations.finish(ctx, player)
    local owned = state.get(ctx, player)

    shared.clear_pending(owned)
    state.set(ctx, player, owned)
end

-- A completed Stack Five only needs its saved readiness cleared at the
-- timed action; other operations continue through their effect modules.
function operations.resolve(ctx, player, _, _, definition)
    local owned = state.get(ctx, player)

    if owned.pending_phase ~= card_phases.READY then
        error("card action resolved before its choices finished: " ..
            owned.pending_kind .. "/" .. owned.pending_phase)
    end

    operations.finish(ctx, player)

    if definition.kind == card_operations.STACK_FIVE then
        ctx:emit("religion", "You stack your cards.")
    end
end

return operations
