-- Source: actor.cc:can_hibernate, beam.cc:BEAM_HIBERNATION and
-- apply_bolt_petrify, mon-ench.cc:calc_duration, monster.cc:hurt.
local component = require("constants.component")
local catalog = require("policy.catalog")
local range = require("policy.magic.range")
local roll = require("policy.combat.roll")
local trajectory = require("policy.combat.trajectory")
local will = require("policy.magic.effects.zaps.will")

local stasis = {}

local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

local function resistance(definition, id)
    for _, entry in ipairs(definition.resistances or {}) do
        if entry.id == id then
            return entry.level
        end
    end

    return 0
end

local function state(ctx, target)
    return ctx:get(target, component.MONSTER_STASIS)
end

local function ensure(ctx, target)
    return state(ctx, target) or {
        hibernating = false,
        sleep_wary_aut = 0,
        petrifying_aut = 0,
        petrified_aut = 0,
    }
end

local function save(ctx, target, value)
    if state(ctx, target) then
        ctx:set(target, component.MONSTER_STASIS, value)
    else
        ctx:add(target, component.MONSTER_STASIS, value)
    end
end

local function duration(ctx, target, definition, kind)
    local actor = ctx:get(target, component.ACTOR)
    local speed = math.max(1, actor.speed)
    local hd = definition.hd
    local centiturns

    if kind == "petrifying" then
        centiturns = math.floor(50 / math.max(1,
            math.floor(10 * 10 / speed)))
    elseif kind == "petrified" then
        centiturns = math.max(8, math.floor(150 / (1 +
            math.max(1, math.floor((hd + 5) * 10 / speed)))))
    else
        centiturns = math.floor(1000 / math.max(1,
            math.floor(50 * 10 / speed)))
    end

    centiturns = math.max(2, centiturns)
    local raw = centiturns * roll.random_divide(ctx, 100, speed)
    local low = math.floor(raw * 60 / 100)
    local high = math.floor(raw * 40 / 100)
    local fuzz = roll.average_two(ctx, "melee", low + high + 1)

    return math.max(15, raw + fuzz - low)
end

local function can_hibernate(ctx, target, definition)
    local current = state(ctx, target)
    local holiness = definition.holiness

    if has(holiness, "MH_UNDEAD") or has(holiness, "MH_NONLIVING") or
        has(holiness, "MH_PLANT") or
        resistance(definition, "MR_RES_COLD") > 0 then
        return false
    end

    return not current or not current.hibernating and
        current.sleep_wary_aut <= 0
end

local function can_petrify(definition)
    return not has(definition.flags, "M_INSUBSTANTIAL") and
        resistance(definition, "MR_RES_PETRIFY") <= 0
end

local function can_target(ctx, player, spell)
    local origin = ctx:get(player, component.POSITION)
    local reach = range.for_spell(ctx, player, spell)

    for _, target in ipairs(ctx:query({
        component.ACTOR, component.POSITION, component.HEALTH,
    })) do
        if target ~= player then
            local position = ctx:get(target, component.POSITION)
            local health = ctx:get(target, component.HEALTH)
            local distance = math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if health.current > 0 and position.level_id == origin.level_id and
                distance <= reach and
                ctx:visible(origin.level_id, origin.x, origin.y, reach,
                    position.x, position.y) and
                ctx:projectile_clear(origin.level_id, origin.x, origin.y,
                    position.x, position.y) then
                return true
            end
        end
    end

    return false
end

local function aimed(ctx, player, intent, spell)
    local origin = ctx:get(player, component.POSITION)
    local ray = trajectory.trace(ctx, origin.level_id, origin.x, origin.y,
        origin.x + intent.dx, origin.y + intent.dy,
        range.for_spell(ctx, player, spell))

    return ray.contacts[1] and ray.contacts[1].actor or nil
end

function stasis.can_target(ctx, player, spell)
    return can_target(ctx, player, spell)
end

function stasis.cast_hibernation(ctx, player, intent, spell, power)
    local target = aimed(ctx, player, intent, spell)

    if not target then
        ctx:emit("spell", "The sleeping magic dissipates.")
        return
    end

    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    if not can_hibernate(ctx, target, definition) then
        ctx:emit("spell", "The " .. definition.name .. " is unaffected.")
        return
    end

    if will.resists(ctx, definition, math.min(power, 50)) then
        ctx:emit("spell", "The " .. definition.name .. " resists sleep.")
        return
    end

    local current = ensure(ctx, target)
    current.hibernating = true
    current.sleep_wary_aut = duration(ctx, target, definition, "sleep_wary")
    save(ctx, target, current)
    ctx:emit("spell", "The " .. definition.name .. " looks drowsy...")
end

function stasis.cast_petrify(ctx, player, intent, spell, power)
    local target = aimed(ctx, player, intent, spell)

    if not target then
        ctx:emit("spell", "The petrifying magic dissipates.")
        return
    end

    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    if not can_petrify(definition) then
        ctx:emit("spell", "The " .. definition.name .. " is unaffected.")
        return
    end

    if will.resists(ctx, definition, power) then
        ctx:emit("spell", "The " .. definition.name .. " resists petrification.")
        return
    end

    local current = ensure(ctx, target)

    if current.petrified_aut > 0 then
        return
    end

    if current.petrifying_aut > 0 then
        current.petrifying_aut = 0
        current.petrified_aut = duration(ctx, target, definition, "petrified")
        ctx:emit("spell", "The " .. definition.name .. " stops moving altogether!")
    else
        current.petrifying_aut = duration(ctx, target, definition, "petrifying")
        ctx:emit("spell", "The " .. definition.name .. " is moving more slowly.")
    end

    save(ctx, target, current)
end

function stasis.hibernating(ctx, target)
    local current = state(ctx, target)

    return current ~= nil and current.hibernating
end

function stasis.petrifying(ctx, target)
    local current = state(ctx, target)

    return current ~= nil and current.petrifying_aut > 0
end

function stasis.petrified(ctx, target)
    local current = state(ctx, target)

    return current ~= nil and current.petrified_aut > 0
end

function stasis.wake_hibernating(ctx, target)
    local current = state(ctx, target)

    if not current or not current.hibernating then
        return false
    end

    current.hibernating = false
    save(ctx, target, current)
    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    ctx:emit("monster", "The " .. definition.name .. " wakes up.")

    return true
end

function stasis.petrified_damage(ctx, target, amount)
    local current = state(ctx, target)

    if not current then
        return amount
    end

    if current.petrified_aut > 0 then
        return math.floor(amount / 2)
    end

    if current.petrifying_aut > 0 then
        return math.floor(amount * 2 / 3)
    end

    return amount
end

function stasis.tick(ctx, target)
    local current = state(ctx, target)

    if not current then
        return
    end

    current.sleep_wary_aut = math.max(0, current.sleep_wary_aut - 10)

    if current.petrifying_aut > 0 then
        current.petrifying_aut = math.max(0, current.petrifying_aut - 10)

        if current.petrifying_aut == 0 then
            local actor = ctx:get(target, component.ACTOR)
            local definition = catalog.get("monsters", actor.kind_id)
            current.petrified_aut = duration(ctx, target, definition, "petrified")
            ctx:emit("monster", "The " .. definition.name .. " stops moving altogether!")
        end
    elseif current.petrified_aut > 0 then
        current.petrified_aut = math.max(0, current.petrified_aut - 10)

        if current.petrified_aut == 0 then
            local actor = ctx:get(target, component.ACTOR)
            local definition = catalog.get("monsters", actor.kind_id)
            ctx:emit("monster", "The " .. definition.name .. " is no longer petrified.")
        end
    end

    if current.hibernating or current.sleep_wary_aut > 0 or
        current.petrifying_aut > 0 or current.petrified_aut > 0 then
        ctx:set(target, component.MONSTER_STASIS, current)
    else
        ctx:remove(target, component.MONSTER_STASIS)
    end
end

return stasis
