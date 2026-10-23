-- Theory of operation: Jiyva first prunes each acquired mutation rank,
-- then attempts four new ranks from good and slime mutation pools. Every
-- change uses the shared ECS mutation transition owner. The resulting
-- cooldown lives with worship, so save and restore need no gift ledger.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local classes = require("constants.mutation_classes")
local choices = require("constants.mutation_choices")
local draws = require("policy.religion.gifts.draws")
local gifts = require("policy.religion.gifts")
local mutation_enum = require("data.mutation_enum")
local physiology = require("policy.mutations.physiology")
local piety = require("policy.religion.piety")
local records = require("policy.mutations.records")
local selection = require("policy.mutations.selection")
local streams = require("constants.rng_streams")
local transition = require("policy.mutations.transition")
local uses = require("constants.mutation_uses")

local jiyva = {}

local MAX_GRANT_ATTEMPTS = 500
local GIFT_LEVELS = 4

-- A mutation's bad use tag selects the stronger deletion chance. This
-- reads the effective mod catalog so newly registered mutations follow
-- the same source rule without another classification table.
local function bad_mutation(mutation_id)
    local definition = catalog.get(categories.MUTATIONS, mutation_id)

    for _, use in ipairs(definition.uses) do
        if use == uses.BAD then
            return true
        end
    end

    return false
end

-- Source iterates the mutation enum, not the order in which record
-- entities were created. Innate and temporary ranks never enter the
-- deletion draw, and a god gift bypasses ordinary deletion resistance.
local function prune_acquired(ctx, player)
    local acquired = {}
    local deleted = false
    local ordered = {}
    local source_ids = {}

    for _, entry in ipairs(records.list(ctx, player)) do
        acquired[entry.state.mutation_id] = entry.state.acquired
    end

    for _, mutation_id in ipairs(mutation_enum) do
        ordered[#ordered + 1] = mutation_id
        source_ids[mutation_id] = true
    end

    -- A mod can register new mutation IDs. Append only owned additions
    -- in sorted order, independent of file and entity creation order.
    local additions = {}

    for mutation_id, levels in pairs(acquired) do
        if levels > 0 and not source_ids[mutation_id] then
            additions[#additions + 1] = mutation_id
        end
    end

    table.sort(additions)

    for _, mutation_id in ipairs(additions) do
        ordered[#ordered + 1] = mutation_id
    end

    for _, mutation_id in ipairs(ordered) do
        local levels = acquired[mutation_id] or 0

        if levels > 0 then
            local chance = bad_mutation(mutation_id) and 50 or 25
            local count = 0

            for _ = 1, levels do
                if ctx:random(streams.MUTATION, 100) < chance then
                    count = count + 1
                end
            end

            for _ = 1, count do
                local result = transition.remove(ctx, player,
                    mutation_id, classes.ACQUIRED)

                deleted = result.kind == "removed" or deleted
            end
        end
    end

    return deleted
end

-- Select a concrete mutation once per attempt, then stay with it while
-- it can gain ranks. God-gift conflict resolution may trade a rank;
-- source counts that successful trade against the four gift levels.
local function add_levels(ctx, player)
    local remaining = GIFT_LEVELS

    for _ = 1, MAX_GRANT_ATTEMPTS do
        if remaining == 0 then
            break
        end

        local choice = choices.JIYVA

        if ctx:random(streams.MUTATION, 10) < 6 then
            choice = choices.GOOD
        end

        local mutation_id

        if choice == choices.JIYVA then
            -- Source samples one slime ID even if that ID is capped.
            -- Its failure spends this outer attempt.
            mutation_id = selection.weighted(ctx, uses.JIYVA)
        else
            mutation_id = selection.choose(ctx, player, choice,
                classes.ACQUIRED)
        end

        if mutation_id then
            while remaining > 0 do
                local result = transition.grant_after_protection(ctx,
                    player, mutation_id, classes.ACQUIRED, true)

                if result.kind ~= "granted" and
                    result.kind ~= "traded" then
                    break
                end

                remaining = remaining - 1
            end
        end
    end

    return remaining == 0
end

-- The shared gift owner has already rejected penance and an active
-- timeout. Source spends its chance draws before checking body safety.
local function due(ctx, player, worship)
    if worship.piety < piety.breakpoint(3) then
        return false
    end

    if ctx:random(streams.RELIGION, worship.piety) <= 50 then
        return false
    end

    if ctx:random(streams.RELIGION, 4) ~= 0 then
        return false
    end

    return physiology.can_safely_mutate(ctx, player)
end

-- Example: a third-star Jiyva follower may trade old mutation ranks for
-- four new ones, then wait 45 plus a source average before another gift.
function jiyva.check(ctx, player, worship)
    if not due(ctx, player, worship) then
        return false
    end

    ctx:emit(channels.RELIGION, "Jiyva alters your body.")

    local deleted = prune_acquired(ctx, player)
    local granted = add_levels(ctx, player)

    if not deleted and not granted then
        ctx:emit(channels.RELIGION,
            "You feel as though nothing has changed.")

        return false
    end

    gifts.record(ctx, player, 45 + draws.average(ctx, 30))

    return true
end

return jiyva
