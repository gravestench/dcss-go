local catalog = require("policy.catalog")
local component = require("constants.component")
local item_ids = require("ids.items")

-- Corpse aging checks source monster flags while tolerating definitions without flag arrays.
local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Corpse lifetime is item-owned. A never-decaying vault specimen still has
-- a valid corpse shape, but spends no freshness and never becomes a skeleton.
local function age_one_corpse(ctx, entity, corpse, item, elapsed)
    if corpse.freshness < 1 or corpse.freshness > 110 or
        (item.kind_id ~= item_ids.CORPSE_BODY and
            item.kind_id ~= item_ids.CORPSE_SKELETON) then
        error("corpse " .. ctx:id(entity) .. " has invalid decay state")
    end

    if corpse.never_decays then
        return
    end

    local freshness = corpse.freshness - math.floor(elapsed / 20)

    if freshness > 0 then
        corpse.freshness = freshness
        ctx:set(entity, "core.corpse", corpse)

        return
    end

    local definition = catalog.get("monsters", corpse.monster_id)

    if item.kind_id == item_ids.CORPSE_SKELETON or
        has_flag(definition, "M_NO_SKELETON") then
        ctx:destroy(entity)

        return
    end

    item.kind_id = item_ids.CORPSE_SKELETON
    corpse.freshness = 110
    corpse.appearance = ctx:random("corpse", 255) + 1
    ctx:set(entity, "core.item", item)
    ctx:set(entity, "core.corpse", corpse)

    local origin = ctx:get(entity, component.VAULT_ORIGIN)

    if origin then
        origin.kind_id = item_ids.CORPSE_SKELETON
        ctx:set(entity, component.VAULT_ORIGIN, origin)
    end
end

-- Re-entry ages a floor corpse from the last 200-aut boundary; a body either remains or becomes a skeleton.
-- Example: age_corpses(ctx, { level_id = floor, elapsed = 200 }) advances corpse decay on re-entry.
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
            age_one_corpse(ctx, entity, corpse, item, elapsed)
        end
    end

    return {}
end

-- Off-level recovery uses a bounded movement count when a remembered target remains.
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

            if actor.speed ~= (definition.speed or 0) then
                error("monster " .. ctx:id(entity) .. " (" .. actor.kind_id ..
                    ") has incorrect catch-up speed: actor=" ..
                    tostring(actor.speed) .. " definition=" ..
                    tostring(definition.speed))
            end

            -- Fast regeneration changes off-level recovery, while the offlevel stream rounds any fractional HP.
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

-- The world scheduler calls these policies on level re-entry to age corpses and catch monsters up.
register.policy({ id = "world.age_corpses", run = age_corpses })
register.policy({ id = "world.catchup_monsters", run = catchup_monsters })
