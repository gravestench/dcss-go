local catalog = require("policy.catalog")

local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

local function age_corpses(ctx, input)
    local level_id = input.level_id
    local elapsed = input.elapsed

    if input.start_aut ~= nil then
        local start_aut = input.start_aut
        local end_aut = input.end_aut
        local interval = 200

        if end_aut < start_aut or
            math.floor(end_aut / interval) == math.floor(start_aut / interval) then
            return {}
        end

        local last_tick = math.floor(start_aut / interval) * interval
        elapsed = end_aut - last_tick
    end

    if elapsed < 0 then
        error("corpse timer elapsed time is negative")
    end

    for _, entity in ipairs(ctx:query({ "core.corpse" })) do
        local corpse = ctx:get(entity, "core.corpse")
        local item = ctx:get(entity, "core.item")
        local position = ctx:get(entity, "core.position")

        if not item or not position then
            error("corpse " .. ctx:id(entity) .. " is not a floor item")
        end

        if position.level_id == level_id then
            local definition = catalog.get("monsters", corpse.monster_id)

            if corpse.freshness < 1 or corpse.freshness > 110 or
                (item.kind_id ~= "CORPSE_BODY" and item.kind_id ~= "CORPSE_SKELETON") then
                error("corpse " .. ctx:id(entity) .. " has invalid decay state")
            end

            local freshness = corpse.freshness - math.floor(elapsed / 20)

            if freshness > 0 then
                corpse.freshness = freshness
                ctx:set(entity, "core.corpse", corpse)
            elseif item.kind_id == "CORPSE_SKELETON" or
                has_flag(definition, "M_NO_SKELETON") then
                ctx:destroy(entity)
            else
                item.kind_id = "CORPSE_SKELETON"
                corpse.freshness = 110
                corpse.appearance = ctx:random("corpse", 255) + 1
                ctx:set(entity, "core.item", item)
                ctx:set(entity, "core.corpse", corpse)
            end
        end
    end

    return {}
end

local function catchup_monsters(ctx, input)
    local turns = input.turns
    local level_id = input.level_id

    if turns < 0 then
        error("monster catch-up turns are negative")
    end

    for _, entity in ipairs(ctx:query({ "core.ai" })) do
        local position = ctx:get(entity, "core.position")

        if not position then
            error("monster " .. ctx:id(entity) .. " has no catch-up position")
        end

        if position.level_id == level_id then
            local actor = ctx:get(entity, "core.actor")
            local health = ctx:get(entity, "core.health")
            local ai = ctx:get(entity, "core.ai")

            if not actor or not health then
                error("monster " .. ctx:id(entity) .. " lacks catch-up state")
            end

            local definition = catalog.get("monsters", actor.kind_id)

            if actor.speed ~= definition.speed then
                error("monster " .. ctx:id(entity) .. " has incorrect catch-up speed")
            end

            local rate = has_flag(definition, "M_FAST_REGEN") and 100 or 10
            local units = turns * rate
            local recovery = math.floor(units / 100)
            local remainder = units % 100

            if remainder > 0 and ctx:random("offlevel", 100) < remainder then
                recovery = recovery + 1
            end

            health.current = health.current + math.min(recovery, health.max - health.current)
            ctx:set(entity, "core.health", health)

            if ai.target_x ~= 0 or ai.target_y ~= 0 then
                local moves = math.min(50, math.floor(turns * actor.speed / 10))

                for _ = 1, moves do
                    local dx = ai.target_x > position.x and 1 or
                        (ai.target_x < position.x and -1 or 0)
                    local dy = ai.target_y > position.y and 1 or
                        (ai.target_y < position.y and -1 or 0)

                    if dx == 0 and dy == 0 then
                        break
                    end

                    local x = position.x + dx
                    local y = position.y + dy

                    if not ctx:walkable(level_id, x, y) or ctx:actor_at(level_id, x, y) then
                        break
                    end

                    ctx:move_actor(entity, level_id, x, y)
                    position.x = x
                    position.y = y
                end
            end
        end
    end

    return {}
end

register.policy({ id = "world.age_corpses", run = age_corpses })
register.policy({ id = "world.catchup_monsters", run = catchup_monsters })
