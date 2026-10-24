local experience_limit = require("policy.character.experience_limit")
local classes = require("constants.mutation_classes")
local choices = require("constants.mutation_choices")
local mutations = require("ids.mutations")
local physiology = require("policy.mutations.physiology")
local records = require("policy.mutations.records")
local resistance = require("policy.mutations.effects.mutation_resistance")

local evolution = {}
local component_id = "character.evolution"
local handled_mutations = {
    [mutations.MUT_EVOLUTION] = true,
    [mutations.MUT_DEVOLUTION] = true,
}

-- Only Evolution and Devolution own the saved periodic mutation clock.
function evolution.has_mutation(mutation_id)
    return handled_mutations[mutation_id] == true
end

-- Devolution wins if both records exist, so one timer drives at most one active policy.
local function active_mutation(ctx, owner)
    if records.find(ctx, owner, mutations.MUT_DEVOLUTION) then
        return mutations.MUT_DEVOLUTION
    end

    if records.find(ctx, owner, mutations.MUT_EVOLUTION) then
        return mutations.MUT_EVOLUTION
    end

    return ""
end

-- Scale the next-level XP gap by species aptitude; Devolution uses one quarter of it.
local function threshold(ctx, owner, mutation_id)
    local progress = ctx:get(owner, "core.progression")
    local player = ctx:get(owner, "core.player")

    if not progress or not player then
        error("Evolution requires player progression and species")
    end

    local level = progress.level
    local gap = experience_limit.needed(ctx, owner, level + 1) -
        experience_limit.needed(ctx, owner, level)

    if mutation_id == mutations.MUT_DEVOLUTION then
        return math.floor(gap / 4)
    end

    return gap
end

-- Read the persisted timer component; callers must tolerate a pre-start owner.
function evolution.state(ctx, owner)
    return ctx:get(owner, component_id)
end

-- Create the timer once so mutation changes do not reset elapsed aut accidentally.
function evolution.start(ctx, owner)
    if evolution.state(ctx, owner) then
        return
    end

    ctx:add(owner, component_id, {
        mutation_id = "",
        remaining_xp = 0,
        mutations_gained = 0,
        elapsed_aut = 0,
        next_check_aut = 200,
    })
end

-- Source: mutation.cc resets both the XP threshold and completed-mutation
-- count on the first level of either mutation.
function evolution.changed(ctx, owner)
    evolution.start(ctx, owner)

    local state = evolution.state(ctx, owner)
    local mutation_id = active_mutation(ctx, owner)

    if state.mutation_id == mutation_id then
        return
    end

    state.mutation_id = mutation_id
    state.mutations_gained = 0

    if mutation_id ~= "" then
        state.remaining_xp = threshold(ctx, owner, mutation_id)
    end

    ctx:set(owner, component_id, state)
end

-- Example: earned XP advances a saved Evolution threshold rather than rolling on every turn.
-- Source: player.cc:apply_exp decrements only positive ATTR_EVOL_XP.
function evolution.gain_experience(ctx, owner, amount)
    if amount < 0 or amount % 1 ~= 0 then
        error("Evolution XP gain must be a nonnegative integer")
    end

    local state = evolution.state(ctx, owner)

    if state and state.mutation_id ~= "" and state.remaining_xp > 0 then
        state.remaining_xp = state.remaining_xp - amount
        ctx:set(owner, component_id, state)
    end
end

-- Reset earned-XP threshold before rolling a mutation; two successful grants consume one source rank.
local function check(ctx, owner)
    local state = evolution.state(ctx, owner)
    local mutation_id = state.mutation_id

    if mutation_id == "" or state.remaining_xp > 0 then
        return
    end

    state.remaining_xp = threshold(ctx, owner, mutation_id)
    ctx:set(owner, component_id, state)
    ctx:emit("mutation", "You feel a genetic drift.")

    local choice = mutation_id == mutations.MUT_DEVOLUTION and
        choices.BAD or choices.GOOD
    local transition = require("policy.mutations.transition")
    local result = transition.grant_random(ctx, owner, choice,
        classes.ACQUIRED, false)

    if result.kind ~= "granted" and result.kind ~= "permanent" then
        return
    end

    state = evolution.state(ctx, owner)
    state.mutations_gained = state.mutations_gained + 1

    if state.mutations_gained >= 2 then
        state.mutations_gained = state.mutations_gained - 2
        ctx:set(owner, component_id, state)

        local entry = records.find(ctx, owner, mutation_id)

        if entry and entry.state.acquired > 0 and
            physiology.can_safely_mutate(ctx, owner) and
            not resistance.deletion_blocks(ctx, owner) then
            transition.remove(ctx, owner, mutation_id, classes.ACQUIRED)
        end

        return
    end

    ctx:set(owner, component_id, state)
end

-- Source: timed-effects.cc starts at 200 aut, then schedules each check
-- 100..300 aut after the previous scheduled time.
function evolution.tick(ctx, owner, aut)
    local state = evolution.state(ctx, owner)

    if not state then
        return
    end

    state.elapsed_aut = state.elapsed_aut + aut

    if state.elapsed_aut < state.next_check_aut then
        ctx:set(owner, component_id, state)
        return
    end

    state.next_check_aut = state.next_check_aut +
        100 + ctx:random("mutation", 201)
    ctx:set(owner, component_id, state)
    check(ctx, owner)
end

-- Reject a restored timer that disagrees with owned mutation records or schedule bounds.
function evolution.validate(ctx, owner)
    local state = evolution.state(ctx, owner)

    if not state or state.mutation_id ~= active_mutation(ctx, owner) or
        state.mutations_gained < 0 or state.mutations_gained > 1 or
        state.elapsed_aut < 0 or state.next_check_aut < 200 then
        error("invalid evolution state")
    end
end

return evolution
