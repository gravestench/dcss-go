local common = require("policy.ai.common")
local cloud_danger = require("policy.clouds.danger")

local route = {}

-- Reduce target deltas to one-cell steps without changing direction.
local function sign(value)
    if value < 0 then
        return -1
    end

    if value > 0 then
        return 1
    end

    return 0
end

-- Package an attack only when the step reaches the target actor.
local function step_intent(x, y, target, dx, dy, attack_goal)
    if attack_goal and x == target.x and y == target.y then
        return {
            kind = 2,
            dx = dx,
            dy = dy,
        }
    end

    return {
        kind = 1,
        dx = dx,
        dy = dy,
    }
end

-- Reject habitat and occupancy violations before offering a detour.
local function safe_move(ctx, entity, position, x, y)
    if not ctx:walkable(position.level_id, x, y) or
        ctx:actor_at(position.level_id, x, y) then
        return false
    end

    return not cloud_danger.avoids(ctx, entity, {
        level_id = position.level_id,
        x = x,
        y = y,
    }, false)
end

-- Try the direct route first so open corridors avoid detour RNG.
local function direct_intent(ctx, entity, state, position,
    target, attack_goal)
    local dx = sign(state.target_x - position.x)
    local dy = sign(state.target_y - position.y)
    local steps = {
        { dx, dy },
        { dx, 0 },
        { 0, dy },
    }

    for _, step in ipairs(steps) do
        local step_x, step_y = step[1], step[2]

        if step_x ~= 0 or step_y ~= 0 then
            local x = position.x + step_x
            local y = position.y + step_y

            if x == target.x and y == target.y then
                if attack_goal then
                    return step_intent(x, y, target, step_x, step_y,
                        attack_goal)
                end

                return { kind = 6 }
            end

            if safe_move(ctx, entity, position, x, y) then
                return step_intent(x, y, target, step_x, step_y,
                    attack_goal)
            end
        end
    end

    return nil
end

-- A detour is accepted only after the direct step has failed its safety checks.
local function safe_detour(ctx, entity, position, target, attack_goal)
    local best
    local best_distance

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local x = position.x + dx
                local y = position.y + dy
                local distance = common.distance(x, y,
                    target.x, target.y)

                if safe_move(ctx, entity, position, x, y) and
                    (not best_distance or distance < best_distance) then
                    best = step_intent(x, y, target, dx, dy,
                        attack_goal)
                    best_distance = distance
                end
            end
        end
    end

    return best or { kind = 6 }
end

-- Permit pathfinding into an occupied goal only when it is the intended target or followed leader.
local function goal_actor(ctx, entity, state, position, target,
    target_entity)
    if state.target_x == target.x and state.target_y == target.y then
        return target_entity
    end

    local leader_position, leader = common.leader_position(ctx, entity, position.level_id)

    if leader_position and state.target_x == leader_position.x and
        state.target_y == leader_position.y then
        return leader
    end

    return nil
end

-- Movement candidates are filtered for occupancy and walkability before the AI commits to a route step.
-- Example: route.follow(ctx, monster, state, pos, target, player) picks a safe pursuit step.
function route.follow(ctx, entity, state, position, target, target_entity,
    attack_goal)
    if attack_goal == nil then
        attack_goal = true
    end

    local level_id = position.level_id
    local goal = goal_actor(ctx, entity, state, position, target,
        target_entity)

    if ctx:visible(level_id, position.x, position.y, 7, state.target_x, state.target_y) then
        local direct = direct_intent(ctx, entity, state, position, target,
            attack_goal)

        if direct then
            return direct
        end
    end

    local dx, dy, found = ctx:route_step(
        level_id,
        position.x,
        position.y,
        state.target_x,
        state.target_y,
        goal
    )

    if not found then
        return {
            kind = 6,
        }
    end

    local x = position.x + dx
    local y = position.y + dy

    if goal and not attack_goal and
        x == state.target_x and y == state.target_y then
        return {
            kind = 6,
        }
    end

    if not safe_move(ctx, entity, position, x, y) then
        return safe_detour(ctx, entity, position, target,
            attack_goal)
    end

    return step_intent(x, y, target, dx, dy, attack_goal)
end

return route
