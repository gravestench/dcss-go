local links = {}

local function adjacent(a, b)
    if a.level_id ~= b.level_id then
        return false
    end

    local dx = math.abs(a.x - b.x)
    local dy = math.abs(a.y - b.y)

    return dx <= 1 and dy <= 1 and (dx ~= 0 or dy ~= 0)
end

local function validate_followers(ctx)
    for _, entity in ipairs(ctx:query({ "core.follower" })) do
        local follower = ctx:get(entity, "core.follower")
        local actor = ctx:get(entity, "core.actor")
        local ai = ctx:get(entity, "core.ai")
        local position = ctx:get(entity, "core.position")
        local leader_id = ctx:id(follower.leader)

        if not ai or not actor or actor.kind_id ~= "MONS_JACKAL" or
            leader_id == 0 or leader_id == ctx:id(entity) then
            error("entity " .. ctx:id(entity) .. " has an invalid band leader link")
        end

        local leader = ctx:entity(leader_id)

        if leader then
            local leader_actor = ctx:get(leader, "core.actor")
            local leader_position = ctx:get(leader, "core.position")

            if not leader_actor or leader_actor.kind_id ~= "MONS_JACKAL" or
                not leader_position or not position or
                leader_position.level_id ~= position.level_id then
                error("entity " .. ctx:id(entity) .. " has an incompatible living band leader")
            end
        end
    end
end

local function validate_constriction(ctx)
    local player = ctx:player()
    local grip = ctx:get(player, "core.constricted")

    if not grip then
        return
    end

    local player_health = ctx:get(player, "core.health")
    local player_position = ctx:get(player, "core.position")
    local python_id = ctx:id(grip.by)
    local python = python_id ~= 0 and ctx:entity(python_id) or nil
    local actor = python and ctx:get(python, "core.actor")
    local ai = python and ctx:get(python, "core.ai")
    local health = python and ctx:get(python, "core.health")
    local position = python and ctx:get(python, "core.position")

    if grip.escape_attempts < 0 or grip.escape_attempts > 1000 or
        not player_health or player_health.current <= 0 or not player_position or
        not actor or actor.kind_id ~= "MONS_BALL_PYTHON" or not ai or
        not health or health.current <= 0 or not position or
        not adjacent(player_position, position) then
        error("player has invalid ball python constriction link")
    end
end

function links.validate(ctx)
    validate_followers(ctx)
    validate_constriction(ctx)
end

return links
