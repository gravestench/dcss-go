local common = require("policy.ai.common")

local route = {}

local function sign(value)
    if value < 0 then
        return -1
    end

    if value > 0 then
        return 1
    end

    return 0
end

local function step_intent(x, y, player, dx, dy)
    if x == player.x and y == player.y then
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

local function direct_intent(ctx, state, position, player)
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

            if x == player.x and y == player.y then
                return step_intent(x, y, player, step_x, step_y)
            end

            if ctx:walkable(position.level_id, x, y) and
                not ctx:actor_at(position.level_id, x, y) then
                return step_intent(x, y, player, step_x, step_y)
            end
        end
    end

    return nil
end

local function goal_actor(ctx, entity, state, position, player, player_entity)
    if state.target_x == player.x and state.target_y == player.y then
        return player_entity
    end

    local leader_position, leader = common.leader_position(ctx, entity, position.level_id)

    if leader_position and state.target_x == leader_position.x and
        state.target_y == leader_position.y then
        return leader
    end

    return nil
end

function route.follow(ctx, entity, state, position, player, player_entity)
    local level_id = position.level_id
    local goal = goal_actor(ctx, entity, state, position, player, player_entity)

    if ctx:visible(level_id, position.x, position.y, 7, state.target_x, state.target_y) then
        local direct = direct_intent(ctx, state, position, player)

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

    if goal and goal ~= player_entity and
        x == state.target_x and y == state.target_y then
        return {
            kind = 6,
        }
    end

    return step_intent(x, y, player, dx, dy)
end

return route
