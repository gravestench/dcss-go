-- Source: spl-monench.cc:englaciate and cast_englaciation.
local component = require("constants.component")
local catalog = require("policy.catalog")
local common = require("policy.magic.effects.statuses.common")
local monster_stats = require("policy.combat.monster_stats")

local englaciation = {}

-- Search catalog flags before attempting to slow stationary monsters.
local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Example: a cold-immune monster is skipped while a susceptible one receives
-- saved Projectile Slow and a reduced actor speed.
local function cold_resistance(definition)
    for _, resistance in ipairs(definition.resistances or {}) do
        if resistance.id == "MR_RES_COLD" then
            return resistance.level
        end
    end

    return 0
end

-- Englaciation slows eligible monsters by storing projectile-slow state and adjusting actor speed.
-- Reapplication extends an existing slow; the first application updates both
-- speed and duration with spell-stream random rounding.
local function apply(ctx, monster, definition, power)
    if cold_resistance(definition) > 0 or
        has(definition.flags, "M_STATIONARY") then
        ctx:emit("spell", "The " .. definition.name .. " is unaffected.")
        return
    end

    local duration = 0

    for _ = 1, 3 do
        duration = duration + 1 + ctx:random("spell", math.max(1, power))
    end

    duration = math.floor(duration / 6) - math.floor(
        monster_stats.hit_dice(ctx, monster, definition) / 2)

    if duration <= 0 then
        ctx:emit("spell", "The " .. definition.name .. " resists.")
        return
    end

    if has(definition.flags, "M_COLD_BLOOD") then
        duration = duration * 2
    end

    duration = math.max(duration, 2 + ctx:random("spell", 4)) * 10
    local current = ctx:get(monster, component.PROJECTILE_SLOW)

    if current then
        current.remaining_aut = current.remaining_aut + duration
        ctx:set(monster, component.PROJECTILE_SLOW, current)
        return
    end

    local actor = ctx:get(monster, component.ACTOR)
    local speed = actor.speed
    local slowed = math.floor(speed * 2 / 3)

    if speed * 2 % 3 > 0 and
        ctx:random("spell", 3) < speed * 2 % 3 then
        slowed = slowed + 1
    end

    actor.speed = slowed
    ctx:set(monster, component.ACTOR, actor)
    ctx:add(monster, component.PROJECTILE_SLOW, {
        base_speed = speed,
        remaining_aut = duration,
    })
    ctx:emit("spell", "The " .. definition.name .. " seems to slow down.")
end

-- Apply the cold aura only to live visible monsters; each target checks cold immunity itself.
function englaciation.cast(ctx, player, _, _, power)
    local origin = ctx:get(player, component.POSITION)
    ctx:emit("spell", "You radiate an aura of cold.")

    for _, monster in ipairs(ctx:query({
        component.ACTOR, component.POSITION, component.HEALTH,
    })) do
        if monster ~= player then
            local position = ctx:get(monster, component.POSITION)
            local health = ctx:get(monster, component.HEALTH)

            if health.current > 0 and
                common.visible(ctx, origin, position) then
                local actor = ctx:get(monster, component.ACTOR)
                apply(ctx, monster, catalog.get("monsters", actor.kind_id),
                    power)
            end
        end
    end
end

return englaciation
