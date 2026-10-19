local classes = require("constants.mutation_classes")
local categories = require("constants.catalog")
local conflicts = require("policy.mutations.conflicts")
local levels = require("policy.mutations.levels")
local physiology = require("policy.mutations.physiology")
local records = require("policy.mutations.records")
local effects = require("policy.mutations.effects.registry")
local resistance = require("policy.mutations.effects.mutation_resistance")
local selection = require("policy.mutations.selection")
local choices = require("constants.mutation_choices")
local stat_loss = require("policy.character.stat_loss")
local evolution = require("policy.mutations.evolution")
local messages = require("policy.mutations.messages")

local transition = {}

-- Reject an unknown rank class before any mutation record or RNG is touched.
local function validate_class(class)
    if class ~= classes.INNATE and class ~= classes.ACQUIRED and
        class ~= classes.TEMPORARY then
        error("unknown mutation class " .. tostring(class))
    end
end

-- Unsafe noninnate grants can block temporary change or decompose into stat loss.
local function unsafe_mutation(ctx, owner, class)
    if class == classes.INNATE or
        physiology.can_safely_mutate(ctx, owner) then
        return nil
    end

    if class == classes.TEMPORARY and
        ctx:random("mutation", 2) == 0 then
        return { kind = "blocked" }
    end

    ctx:emit("mutation", "Your body decomposes!")
    stat_loss.drain_random(ctx, owner)

    return { kind = "decomposed" }
end

-- Example: a nonforced grant may be resisted before conflict resolution changes any saved rank.
-- Check intrinsic resistance and unsafe physiology before changing conflict or record state.
function transition.grant(ctx, owner, mutation_id, class, forced, progress)
    validate_class(class)

    if class ~= classes.INNATE and not forced and
        resistance.intrinsic_blocks(ctx, owner, class) then
        return { kind = "resisted", mutation_id = mutation_id }
    end

    local unsafe = unsafe_mutation(ctx, owner, class)

    if unsafe then
        return unsafe
    end

    return transition.grant_after_protection(ctx, owner, mutation_id,
        class, forced, progress)
end

-- The caller must already have checked acquisition protection. Malmutation
-- chooses its category before that check and must not roll protection twice.
function transition.grant_after_protection(ctx, owner, mutation_id, class,
    forced, progress, max_levels)
    validate_class(class)
    forced = forced or class == classes.INNATE

    local definition = register.get(categories.MUTATIONS, mutation_id)

    if definition.status ~= "active" or
        not physiology.permitted(ctx, owner, mutation_id) then
        return { kind = "blocked", mutation_id = mutation_id }
    end

    local converted = false
    local existing = records.find(ctx, owner, mutation_id)
    local old_level = levels.base(ctx, owner, mutation_id)

    if class == classes.INNATE and existing then
        if existing.state.temporary > 0 then
            records.delete(ctx, owner, mutation_id, classes.TEMPORARY, 1)
            converted = true
        elseif existing.state.acquired > 0 then
            records.delete(ctx, owner, mutation_id, classes.ACQUIRED, 1)
            converted = true
        end
    end

    if levels.base(ctx, owner, mutation_id) >= definition.max_level then
        return { kind = "blocked", mutation_id = mutation_id }
    end

    local result = conflicts.resolve(ctx, owner, mutation_id, class, forced)

    if result.kind ~= "continue" then
        return result
    end

    local count = math.min(max_levels or 1,
        definition.max_level - levels.base(ctx, owner, mutation_id))

    if class == classes.INNATE then
        records.grant_innate(ctx, owner, mutation_id, count)
    elseif class == classes.ACQUIRED then
        records.grant_acquired(ctx, owner, mutation_id, count)
    else
        local temporary = require("policy.mutations.temporary")
        local expiry_progress = progress or temporary.roll(ctx, owner)

        records.grant_temporary(ctx, owner, mutation_id, count,
            expiry_progress)
    end

    effects.changed(ctx, owner, mutation_id)
    messages.gained(ctx, mutation_id, old_level,
        levels.base(ctx, owner, mutation_id))

    if evolution.has_mutation(mutation_id) then
        evolution.changed(ctx, owner)
    end

    return {
        kind = converted and "permanent" or "granted",
        mutation_id = mutation_id,
    }
end

-- Remove one chosen rank, then refresh effects, message text, and Evolution timer.
function transition.remove(ctx, owner, mutation_id, class)
    if class ~= classes.INNATE and class ~= classes.ACQUIRED and
        class ~= classes.TEMPORARY then
        error("unknown mutation class " .. tostring(class))
    end

    local entry = records.find(ctx, owner, mutation_id)

    if not entry or entry.state[class] < 1 then
        return { kind = "blocked", mutation_id = mutation_id }
    end

    local old_level = levels.base(ctx, owner, mutation_id)

    records.delete(ctx, owner, mutation_id, class, 1)
    effects.changed(ctx, owner, mutation_id)
    messages.lost(ctx, mutation_id, old_level - 1)

    if evolution.has_mutation(mutation_id) then
        evolution.changed(ctx, owner)
    end

    return { kind = "removed", mutation_id = mutation_id }
end

-- Source: mutation.cc:delete_mutation protects ordinary acquired levels,
-- chooses an eligible mutation, and leaves innate and temporary levels alone.
function transition.remove_random(ctx, owner, choice, forced)
    if not forced then
        if resistance.deletion_blocks(ctx, owner) then
            return { kind = "resisted" }
        end

        if not physiology.can_safely_mutate(ctx, owner) then
            return { kind = "blocked" }
        end
    end

    local mutation_id = selection.choose_removable(ctx, owner, choice)

    if not mutation_id then
        return { kind = "blocked" }
    end

    return transition.remove(ctx, owner, mutation_id, classes.ACQUIRED)
end

-- Count acquired and temporary ranks for saturation without penalizing inherited traits.
local function noninnate_levels(ctx, owner)
    local total = 0

    for _, entry in ipairs(records.list(ctx, owner)) do
        total = total + entry.state.acquired + entry.state.temporary
    end

    return total
end

-- Above fifteen noninnate levels saturation is certain; below it uses one mutation draw.
local function heavily_mutated(ctx, owner)
    local count = noninnate_levels(ctx, owner)

    if count >= 15 then
        return true
    end

    return count > 0 and ctx:random("mutation", 15) < count
end

-- Source: mutation.cc:mutate. Random acquisition protects the player before
-- choosing a concrete mutation; saturated bodies may lose a level instead.
function transition.grant_random(ctx, owner, choice, class, forced, progress)
    validate_class(class)

    if class ~= classes.INNATE and not forced and
        resistance.intrinsic_blocks(ctx, owner, class) then
        return { kind = "resisted" }
    end

    local unsafe = unsafe_mutation(ctx, owner, class)

    if unsafe then
        return unsafe
    end

    if class == classes.ACQUIRED and
        (choice == choices.ANY or choice == choices.XOM) and
        heavily_mutated(ctx, owner) then
        local deletion_roll = ctx:random("mutation", 3) == 0

        if not deletion_roll and not forced then
            return { kind = "blocked" }
        end

        return transition.remove_random(ctx, owner, choices.ANY, forced)
    end

    local mutation_id = selection.choose(ctx, owner, choice, class)

    if not mutation_id then
        return { kind = "blocked" }
    end

    local max_levels = 1

    if choice == choices.CORRUPT or choice == choices.QAZLAL then
        max_levels = 2
    end

    return transition.grant_after_protection(ctx, owner, mutation_id,
        class, forced, progress, max_levels)
end

-- Source: species.cc:give_level_mutations calls perma_mutate for each XL
-- grant. Forced trades may consume an opposed level before growth succeeds.
function transition.grant_scheduled(ctx, owner, species, level)
    for _, scheduled in ipairs(species.mutations or {}) do
        if scheduled.level == level and scheduled.amount > 0 then
            local definition = register.get(categories.MUTATIONS, scheduled.id)

            for _ = 1, math.min(scheduled.amount, definition.max_level) do
                local completed = false

                for _ = 1, 100 do
                    local result = transition.grant(ctx, owner, scheduled.id,
                        classes.INNATE, true)

                    if result.kind == "granted" or result.kind == "permanent" then
                        completed = true
                        break
                    end

                    if result.kind ~= "traded" then
                        error("scheduled innate mutation was blocked: " ..
                            scheduled.id)
                    end
                end

                if not completed then
                    error("scheduled innate mutation exhausted conflicts: " ..
                        scheduled.id)
                end
            end
        end
    end
end

return transition
