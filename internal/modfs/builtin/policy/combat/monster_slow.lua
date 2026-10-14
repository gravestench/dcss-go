local roll = require("policy.combat.roll")

local slow = {}

local function duration(ctx, speed, hit_dice)
    -- mon-ench.cc:2251,2379-2384 computes ENCH_SLOW duration before changing
    -- the monster's speed, then applies the asymmetric duration fuzz.
    local modified_speed = math.max(1,
        math.floor((hit_dice + 10) * 10 / math.max(1, speed)))
    local centiturns = math.max(2, math.floor(250 / (1 + modified_speed)))
    local speed_duration = roll.random_divide(ctx, 100, speed)
    local raw = centiturns * speed_duration
    local low = math.floor(60 * raw / 100)
    local high = math.floor(40 * raw / 100)
    local spread = low + high + 1
    local fuzz = roll.average_two(ctx, "melee", spread)

    return math.max(15, raw + fuzz - low)
end

function slow.apply(ctx, monster, definition)
    local current = ctx:get(monster, "projectile.slow")
    local actor = ctx:get(monster, "core.actor")
    local base_speed = current and current.base_speed or actor.speed
    local added_aut = duration(ctx, base_speed, definition.hd)

    if current then
        current.remaining_aut = current.remaining_aut + added_aut
        ctx:set(monster, "projectile.slow", current)

        return
    end

    -- monster.cc:4766-4776 applies haste_div(speed) for ENCH_SLOW.
    actor.speed = roll.random_divide(ctx, base_speed * 2, 3)
    ctx:set(monster, "core.actor", actor)
    ctx:add(monster, "projectile.slow", {
        base_speed = base_speed,
        remaining_aut = added_aut,
    })
    ctx:emit("combat", "The " .. definition.name .. " seems to slow down.")
end

function slow.tick(ctx, monster)
    local state = ctx:get(monster, "projectile.slow")

    if not state then
        return
    end

    local health = ctx:get(monster, "core.health")

    if not health or health.current <= 0 then
        return
    end

    state.remaining_aut = state.remaining_aut - 10

    if state.remaining_aut > 0 then
        ctx:set(monster, "projectile.slow", state)

        return
    end

    local actor = ctx:get(monster, "core.actor")
    actor.speed = state.base_speed
    ctx:set(monster, "core.actor", actor)
    ctx:remove(monster, "projectile.slow")
end

function slow.validate(ctx, monster, definition, actor)
    local state = ctx:get(monster, "projectile.slow")

    if not state then
        return actor.speed == definition.speed
    end

    local minimum = math.floor(state.base_speed * 2 / 3)

    return state.base_speed == definition.speed and
        state.remaining_aut > 0 and
        (actor.speed == minimum or actor.speed == minimum + 1)
end

return slow
