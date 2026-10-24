local component = require("constants.component")
local spells = require("ids.spells")
local catalog = require("policy.catalog")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")
local will = require("policy.magic.effects.zaps.will")

local slow = {}

-- Example: A visible susceptible monster on a clear ray makes Slow castable.
-- Check range and clear visibility before prompting for a ray that could affect a living actor.
function slow.can_target(ctx, player, spell)
    local origin = ctx:get(player, component.POSITION)
    local reach = range.for_spell(ctx, player, spell)

    for _, target in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if target ~= player then
            local location = ctx:get(target, component.POSITION)
            local health = ctx:get(target, component.HEALTH)
            local distance = math.max(math.abs(location.x - origin.x),
                math.abs(location.y - origin.y))

            if health.current > 0 and distance <= reach and
                location.level_id == origin.level_id and
                ctx:visible(origin.level_id, origin.x, origin.y, reach,
                    location.x, location.y) and
                ctx:projectile_clear(origin.level_id, origin.x, origin.y,
                    location.x, location.y) then
                return true
            end
        end
    end

    return false
end

-- Round two-thirds speed through the spell stream to preserve source action timing.
local function slowed_speed(ctx, base)
    local numerator = base * 2
    local quotient = math.floor(numerator / 3)

    if numerator % 3 > 0 and ctx:random("spell", 3) < numerator % 3 then
        quotient = quotient + 1
    end

    return quotient
end

-- Extend an existing Slow timer without overwriting the original speed needed for restoration.
local function apply(ctx, target, definition, ench_power)
    -- Reapplication extends the saved duration; only the first cast changes
    -- actor speed and records the original value for restoration.
    local current = ctx:get(target, component.PROJECTILE_SLOW)

    if current then
        current.remaining_aut = current.remaining_aut + ench_power * 10
        ctx:set(target, component.PROJECTILE_SLOW, current)
        ctx:emit("spell", "The " .. definition.name .. " is slowed for longer.")
        return
    end

    local actor = ctx:get(target, component.ACTOR)
    local base_speed = actor.speed

    actor.speed = slowed_speed(ctx, base_speed)
    ctx:set(target, component.ACTOR, actor)
    ctx:add(target, component.PROJECTILE_SLOW, {
        base_speed = base_speed,
        remaining_aut = ench_power * 10,
    })
    ctx:emit("spell", "The " .. definition.name .. " seems to slow down.")
end

-- Trace a beam contact and check enchant resistance before changing monster speed.
function slow.resolve(ctx, player, intent, spell, power)
    local origin = ctx:get(player, component.POSITION)
    local ray = trajectory.trace(ctx, origin.level_id, origin.x, origin.y,
        origin.x + intent.dx, origin.y + intent.dy,
        range.for_spell(ctx, player, spell))
    local contact = ray.contacts[1]

    if not contact then
        ctx:emit("spell", "The slowing magic dissipates.")
        return
    end

    local target = contact.actor
    local actor = ctx:get(target, component.ACTOR)
    local health = ctx:get(target, component.HEALTH)

    if not actor or not health then
        error("Slow struck an actor without health")
    end

    local definition = catalog.get("monsters", actor.kind_id)
    if health.current <= 0 then
        ctx:emit("spell", "The " .. definition.name .. " is unaffected.")
        return
    end

    -- zap-data.h:ZAP_SLOW enchants at 3*power/2 (cap 100).
    local ench_power = math.floor(math.min(power, 100) * 3 / 2)

    if will.resists(ctx, definition, ench_power,
        target, nil, player) then
        ctx:emit("spell", "The " .. definition.name .. " resists slowing.")
        return
    end

    apply(ctx, target, definition, ench_power)
end

registry.add(spells.SPELL_SLOW, slow)

return slow
