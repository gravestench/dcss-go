local catalog = require("policy.catalog")
local roll = require("policy.combat.roll")

local poison = {}

function poison.resistance(definition)
    for _, entry in ipairs(definition.resistances or {}) do
        if entry.id == "MR_RES_POISON" then
            return entry.level
        end
    end

    for _, id in ipairs(definition.holiness or {}) do
        if id == "MH_UNDEAD" or id == "MH_NONLIVING" then
            return 3
        end
    end

    return 0
end

local function duration(ctx, speed, degree)
    -- mon-ench.cc:2269,2379-2384 gives poison an actor-speed-adjusted,
    -- asymmetrically fuzzed duration. Keep its draws on the combat stream.
    speed = math.max(1, math.min(100, speed))

    local modified_speed = math.max(1, math.floor(1250 / speed))
    local centiturns = math.max(2, math.floor(1000 * degree / modified_speed))
    local speed_duration = roll.random_divide(ctx, 100, speed)
    local raw = centiturns * speed_duration
    local low = math.floor(60 * raw / 100)
    local high = math.floor(40 * raw / 100)
    local spread = low + high + 1
    local fuzz = roll.average_two(ctx, "melee", spread)

    return math.max(15, raw + fuzz - low)
end

function poison.apply(ctx, monster, definition, levels, source)
    if levels <= 0 or poison.resistance(definition) > 0 then
        return false
    end

    local actor = ctx:get(monster, "core.actor")
    local current = ctx:get(monster, "projectile.poison")
    local old_degree = current and current.degree or 0
    local degree = math.min(4, old_degree + levels)
    local added_aut = duration(ctx, actor.speed, levels)

    if current then
        current.degree = degree
        current.remaining_aut = current.remaining_aut + added_aut
        current.max_aut = math.max(current.max_aut, current.remaining_aut)
        current.source = source
        ctx:set(monster, "projectile.poison", current)
    else
        ctx:add(monster, "projectile.poison", {
            degree = degree,
            remaining_aut = added_aut,
            max_aut = added_aut,
            source = source,
        })
    end

    if degree > old_degree then
        local text = old_degree == 0 and " is poisoned." or " looks even sicker."
        ctx:emit("poison", "The " .. definition.name .. text)
    end

    return true
end

function poison.tick(ctx, monster)
    local state = ctx:get(monster, "projectile.poison")

    if not state then
        return
    end

    local health = ctx:get(monster, "core.health")

    if health.current <= 0 then
        return
    end

    local actor = ctx:get(monster, "core.actor")
    local definition = catalog.get("monsters", actor.kind_id)
    local damage = state.degree >= 4 and 1 or 0

    if roll.melee(ctx, 2) == 0 then
        damage = damage + 1 + roll.melee(ctx, state.degree + 1)
    end

    if poison.resistance(definition) < 0 then
        damage = damage + 1 + roll.melee(ctx, state.degree)
        damage = damage + roll.melee(ctx, state.degree)
    end

    if damage > 0 then
        health.current = math.max(0, health.current - damage)
        ctx:set(monster, "core.health", health)

        if health.current == 0 and state.source == ctx:player() then
            ctx:signal("player_kill", monster)
        end
    end

    -- mon-ench.cc:1074-1135 decays one normal action at a time and lowers
    -- high poison degrees as their duration approaches zero.
    state.remaining_aut = state.remaining_aut - 10

    if state.remaining_aut <= 0 then
        ctx:remove(monster, "projectile.poison")
        ctx:emit("poison", "The " .. definition.name .. " looks more healthy.")

        return
    end

    if state.degree > 1 then
        local factor = state.degree * (state.degree + 1) / 2

        if state.remaining_aut < state.max_aut * (factor - 1) / factor then
            state.degree = state.degree - 1
            state.max_aut = state.remaining_aut
        end
    end

    ctx:set(monster, "projectile.poison", state)
end

function poison.validate(ctx, monster)
    local state = ctx:get(monster, "projectile.poison")

    if not state then
        return
    end

    if state.degree < 1 or state.degree > 4 or state.remaining_aut < 1 or
        state.max_aut < state.remaining_aut or state.source ~= ctx:player() then
        error("monster " .. ctx:id(monster) .. " has invalid poison state")
    end
end

return poison
