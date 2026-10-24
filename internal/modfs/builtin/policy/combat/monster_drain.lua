-- Source: monster.cc:monster::drain and mon-ench.cc:ENCH_DRAINED.
local component = require("constants.component")
local resistance_ids = require("constants.resistance_ids")
local monster_health = require("policy.combat.monster_health")
local catalog = require("policy.catalog")
local senses = require("policy.character.senses")
local monster_profile = require("policy.combat.monster_profile")
local monster_resistance = require("policy.combat.monster_resistance")

local drain = {}

-- Negative-energy drain uses the same live body, shield, jewellery, staff,
-- and artefact calculation as every other monster resistance consumer.
function drain.resistance(ctx, monster, definition)
    definition = monster_profile.definition(ctx, monster, definition)

    return monster_resistance.level(ctx, monster, definition,
        resistance_ids.NEGATIVE_ENERGY)
end

-- Monster drain is stored as a timed component after negative-energy resistance is checked.
function drain.apply(ctx, target, definition, source, stream,
    player_credit)
    local resistance = drain.resistance(ctx, target, definition)
    local random_stream = stream or "mutation"

    if resistance >= 3 then
        return false
    end

    if senses.player_sees_actor(ctx, target) then
        ctx:emit("combat", "The " .. definition.name .. " is drained!")
    end

    local health, dealt = monster_health.damage(ctx, target,
        2 + ctx:random(random_stream, 3), source)

    if dealt > 0 and health.current == 0 then
        if player_credit or
            source and ctx:has(source, component.PLAYER) then
            ctx:signal("player_kill", target)
        end

        return true
    end

    local current = ctx:get(target, component.MONSTER_DRAINED)
    local remaining = current and current.remaining_aut or 0
    -- Repeated drains add a degree but cap remaining time, then partial
    -- negative resistance shortens only the new duration.
    local duration = 200 + ctx:random(random_stream, 100)
    local cap = 300 - remaining - ctx:random(random_stream, 50)

    duration = math.min(duration, cap)

    if resistance > 0 then
        duration = math.floor(duration / (resistance * 2))
    end

    local next_state = current or {
        degree = 0,
        remaining_aut = 0,
    }

    next_state.degree = next_state.degree + 1
    next_state.remaining_aut = math.max(0, remaining + duration)

    if current then
        ctx:set(target, component.MONSTER_DRAINED, next_state)
    else
        ctx:add(target, component.MONSTER_DRAINED, next_state)
    end

    return true
end

-- Example: drain.tick(ctx, monster) with expired drain -> drained state removed
-- Timed drain expires on the monster clock and removes its hit-dice penalty.
function drain.tick(ctx, monster)
    local current = ctx:get(monster, component.MONSTER_DRAINED)

    if not current then
        return
    end

    current.remaining_aut = math.max(0, current.remaining_aut - 10)

    if current.remaining_aut > 0 then
        ctx:set(monster, component.MONSTER_DRAINED, current)

        return
    end

    ctx:remove(monster, component.MONSTER_DRAINED)
    local actor = ctx:get(monster, component.ACTOR)

    if actor then
        local definition = catalog.get("monsters", actor.kind_id)

        if senses.player_sees_actor(ctx, monster) then
            ctx:emit("monster", "The " .. definition.name ..
                " seems less drained.")
        end
    end
end

return drain
