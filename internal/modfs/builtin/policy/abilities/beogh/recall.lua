-- Theory of operation: Recall samples and saves a queue of living Beogh
-- companions when invoked. Player actions advance its timer; each entry
-- either receives follow orders nearby or moves to a habitable cell near
-- the player. Entity handles remain stable across floors and save/restore.
local abilities = require("ids.abilities")
local attitudes = require("constants.attitude")
local behaviors = require("constants.ai_behaviors")
local branch_flags = require("constants.branch_flags")
local branches = require("ids.branches")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local costs = require("policy.abilities.beogh.costs")
local flags = require("constants.monster_flags")
local gods = require("constants.gods")
local habitat = require("policy.combat.monster_habitat")
local monster_stats = require("policy.combat.monster_stats")
local net = require("policy.combat.net")
local registry = require("policy.abilities.registry")
local streams = require("constants.rng_streams")

local recall = {}

-- Resolve equal HD rolls by stable entity identity, not registration order.
local function entity_before(left, right)
    return left.id < right.id
end

-- A larger experience-and-random score answers the call first. IDs only
-- break ties, keeping save seeds independent of Lua file load order.
local function score_before(left, right)
    if left.score == right.score then
        return left.id < right.id
    end

    return left.score > right.score
end

-- The player's current branch controls whether off-level recall runs.
-- Pandemonium is explicitly allowed despite its no-travel branch flag.
local function allows_offlevel(ctx, level_id)
    local branch_id = ctx:level_branch(level_id)

    if branch_id == branches.BRANCH_ABYSS then
        return false
    end

    if branch_id == branches.BRANCH_PANDEMONIUM then
        return true
    end

    local branch = catalog.get(categories.BRANCHES, branch_id)

    for _, flag in ipairs(branch.flags or {}) do
        if flag == branch_flags.NO_X_LEVEL_TRAVEL then
            return false
        end
    end

    return true
end

-- Source mons_is_recallable excludes inert, conjured, and no-threat bodies;
-- the Beogh layer also requires a living friendly god gift.
local function eligible(ctx, entity, current_level)
    local gift = ctx:get(entity, component.BEOGH_ORC)
    local actor = ctx:get(entity, component.ACTOR)
    local health = ctx:get(entity, component.HEALTH)
    local position = ctx:get(entity, component.POSITION)

    if not gift or not gift.gift or
        gift.attitude ~= attitudes.FRIENDLY or
        not actor or actor.speed <= 0 or
        not health or health.current <= 0 or not position then
        return false
    end

    -- Source companion storage omits only Abyss companions. A follower
    -- left in another isolated branch can answer from an eligible level.
    if position.level_id ~= current_level and
        ctx:level_branch(position.level_id) ==
            branches.BRANCH_ABYSS then
        return false
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.STATIONARY or flag == flags.CONJURED or
            flag == flags.NO_THREAT then
            return false
        end
    end

    return true
end

-- Stable entity order precedes source experience-plus-d10 ranking, so a
-- mod's file load order cannot change which companion draws which bonus.
local function queue(ctx, player)
    local origin = ctx:get(player, component.POSITION)
    local scored = {}
    local offlevel_allowed = allows_offlevel(ctx, origin.level_id)

    for _, entity in ipairs(ctx:query({ component.BEOGH_ORC })) do
        local position = ctx:get(entity, component.POSITION)

        if eligible(ctx, entity, origin.level_id) and
            (position.level_id == origin.level_id or
                offlevel_allowed) then
            local actor = ctx:get(entity, component.ACTOR)
            local definition = catalog.get(categories.MONSTERS,
                actor.kind_id)

            scored[#scored + 1] = {
                entity = entity,
                id = ctx:id(entity),
                hd = monster_stats.base_hit_dice(ctx, entity,
                    definition),
            }
        end
    end

    table.sort(scored, entity_before)

    for _, entry in ipairs(scored) do
        entry.score = entry.hd + ctx:random(streams.RELIGION, 10)
    end

    table.sort(scored, score_before)

    local result = {}

    for _, entry in ipairs(scored) do
        result[#result + 1] = entry.entity
    end

    return result
end

-- Recall starts even when no one answers; the accepted ability still
-- spends its MP. An active call replaces no prior queue because the menu
-- presents Stop Recall while one is running.
function recall.start(ctx, player)
    local result = queue(ctx, player)

    if #result == 0 then
        ctx:emit("religion", "Nothing appears to have answered your call.")

        return false
    end

    local state = {
        queue = result,
        next_index = 1,
        next_aut = 0,
    }

    if ctx:has(player, component.BEOGH_RECALL) then
        ctx:set(player, component.BEOGH_RECALL, state)
    else
        ctx:add(player, component.BEOGH_RECALL, state)
    end

    ctx:emit("religion", "You begin recalling your allies.")

    return true
end

-- A stopped queue has no latent timer or references in the saved game.
function recall.stop(ctx, player)
    if not ctx:has(player, component.BEOGH_RECALL) then
        return false
    end

    ctx:remove(player, component.BEOGH_RECALL)
    ctx:emit("religion", "You stop recalling your allies.")

    return true
end

-- Recalled companions forget their former patrol and stale foe so the
-- friendly AI can follow the player after the teleport finishes.
local function orders(ctx, entity, player_position)
    if ctx:has(entity, component.MONSTER_PATROL) then
        ctx:remove(entity, component.MONSTER_PATROL)
    end

    local ai = ctx:get(entity, component.AI)

    if ai then
        ai.behavior = behaviors.SEEK
        ai.target_x = player_position.x
        ai.target_y = player_position.y
        ai.memory_until_aut = ctx:aut() + 250
        ctx:set(entity, component.AI, ai)
    end
end

-- Source find_habitable_spot_near samples the whole radius-three square.
-- The destination belongs to the player's level, even for an off-level orc.
local function landing(ctx, entity, origin)
    local chosen
    local count = 0

    for dy = -3, 3 do
        for dx = -3, 3 do
            local x = origin.x + dx
            local y = origin.y + dy

            if (dx ~= 0 or dy ~= 0) and
                not ctx:actor_at(origin.level_id, x, y) and
                ctx:visible_no_trans(origin.level_id, origin.x,
                    origin.y, 3, x, y) and
                habitat.at(ctx, entity, origin.level_id, x, y) then
                count = count + 1

                if ctx:random(streams.RELIGION, count) == 0 then
                    chosen = { x = x, y = y }
                end
            end
        end
    end

    return chosen
end

-- Nearby followers need orders rather than a needless teleport. Dead or
-- vanished entities are skipped, allowing the queue to finish normally.
local function try_one(ctx, player, entity)
    local origin = ctx:get(player, component.POSITION)
    local position = ctx:get(entity, component.POSITION)

    if not position or
        not eligible(ctx, entity, origin.level_id) then
        return false
    end

    local distance = math.max(math.abs(position.x - origin.x),
        math.abs(position.y - origin.y))

    if position.level_id == origin.level_id and distance < 3 and
        ctx:visible_no_trans(origin.level_id, position.x, position.y,
            7, origin.x, origin.y) then
        orders(ctx, entity, origin)

        return false
    end

    local destination = landing(ctx, entity, origin)

    if not destination then
        return false
    end

    net.release(ctx, entity)
    ctx:move_actor(entity, origin.level_id,
        destination.x, destination.y)
    orders(ctx, entity, origin)
    ctx:emit("religion", "An ally is recalled.")

    return true
end

-- Source do_recall uses strict time > next delay. Failed placements do
-- not postpone the next candidate; successful ones wait three to six aut.
function recall.tick(ctx, player, elapsed_aut)
    local state = ctx:get(player, component.BEOGH_RECALL)

    if not state then
        return
    end

    local time = elapsed_aut

    while state.next_index <= #state.queue and
        time > state.next_aut do
        local entity = state.queue[state.next_index]

        state.next_index = state.next_index + 1

        if try_one(ctx, player, entity) then
            time = time - state.next_aut
            state.next_aut = 3 + ctx:random(streams.RELIGION, 4)
        end
    end

    if state.next_index > #state.queue then
        ctx:remove(player, component.BEOGH_RECALL)
        ctx:emit("religion", "You finish recalling your allies.")

        return
    end

    state.next_aut = state.next_aut - time
    ctx:set(player, component.BEOGH_RECALL, state)
end

-- Death removes a queued entity before its handle becomes invalid in a
-- saved game. The index tracks the next remaining entry after compaction.
function recall.forget(ctx, player, victim)
    local state = ctx:get(player, component.BEOGH_RECALL)

    if not state then
        return
    end

    local remaining = {}
    local removed_before = 0

    for index, entity in ipairs(state.queue) do
        if entity == victim then
            if index < state.next_index then
                removed_before = removed_before + 1
            end
        else
            remaining[#remaining + 1] = entity
        end
    end

    if #remaining == #state.queue then
        return
    end

    state.queue = remaining
    state.next_index = state.next_index - removed_before

    if state.next_index > #remaining then
        ctx:remove(player, component.BEOGH_RECALL)
    else
        ctx:set(player, component.BEOGH_RECALL, state)
    end
end

-- Save validation rejects a forged queue or timer before the next action
-- could relocate an unrelated entity into the player's level.
function recall.validate(ctx, player)
    local state = ctx:get(player, component.BEOGH_RECALL)

    if not state then
        return
    end

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    if not ctx:has(player, component.PLAYER) or
        not worship or worship.god_id ~= gods.BEOGH or
        #state.queue == 0 or
        state.next_index < 1 or
        state.next_index > #state.queue or
        state.next_aut < 0 or state.next_aut > 6 then
        error("invalid saved Beogh recall queue")
    end

    local seen = {}
    local origin = ctx:get(player, component.POSITION)

    for _, entity in ipairs(state.queue) do
        local id = ctx:id(entity)

        if seen[id] or not eligible(ctx, entity, origin.level_id) then
            error("invalid saved Beogh recall companion " .. id)
        end

        seen[id] = true
    end
end

-- Beogh's four-star action rolls failure before sampling the follower
-- queue. A failed invocation spends the turn but no MP.
function recall.resolve(ctx, player)
    if costs.failed(ctx, player, 30, 6, 20) then
        ctx:emit("religion", "You fail to use your ability.")

        return
    end

    recall.start(ctx, player)
    costs.spend(ctx, player, 2, 0)
end

-- Two MP is checked before action timing; a cancelled request is free.
local function prepare(ctx, player)
    if not costs.enough_magic(ctx, player, 2) then
        return "You do not have enough magic."
    end

    return nil
end

-- Stop Recall is a separate menu row during the active channel, matching
-- the source fixup of Recall Orcish Followers to Stop Recall.
local function stop_available(ctx, player)
    return ctx:has(player, component.BEOGH_RECALL)
end

-- A running queue replaces the menu's ordinary Recall row; the live
-- component, rather than stale player piety, decides which row appears.
local function start_available(ctx, player)
    return costs.available(ctx, player, 4) and
        not ctx:has(player, component.BEOGH_RECALL)
end

-- Stop Recall has no target or resource preflight.
local function stop_prepare()
    return nil
end

registry.add(abilities.BEOGH_RECALL_ORCISH_FOLLOWERS, {
    name = "Recall Orcish Followers",
    available = start_available,
    prepare = prepare,
    resolve = recall.resolve,
})

registry.add(abilities.BEOGH_STOP_RECALL, {
    name = "Stop Recall",
    available = stop_available,
    prepare = stop_prepare,
    resolve = recall.stop,
})

return recall
