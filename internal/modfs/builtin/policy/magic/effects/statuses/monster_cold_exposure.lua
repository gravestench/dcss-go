-- Cold exposure is an actor effect shared by Freeze and Refrigeration.
-- Damage and resistance are decided by the caller before exposure occurs.
local component = require("constants.component")
local display = require("policy.combat.monster_support.display")
local roll = require("policy.combat.roll")
local senses = require("policy.character.senses")
local flags = require("constants.monster_flags")
local resistances = require("constants.resistance_ids")

local exposure = {}

-- A cold-blooded survivor without rC can be slowed after taking cold damage.
-- monster.cc:expose_to_element uses a coin flip and adds 0-4 to strength;
-- repeated exposure extends duration without reducing speed a second time.
function exposure.apply(ctx, monster, definition, strength, stream)
    local cold_blooded = false
    local slow_immune = false

    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.STATIONARY or flag == flags.STASIS then
            slow_immune = true
        end

        if flag == flags.COLD_BLOOD then
            cold_blooded = true
        end
    end

    if not cold_blooded then
        return
    end

    for _, resistance in ipairs(definition.resistances or {}) do
        if resistance.id == resistances.COLD and resistance.level > 0 then
            return
        end
    end

    if ctx:random(stream, 2) ~= 0 then
        return
    end

    local duration = (strength + ctx:random(stream, 5)) * 10

    -- Source tests slow immunity only after both exposure draws. Keep the
    -- saved stream aligned even for cold-blooded stationary creatures.
    if slow_immune or duration <= 0 then
        return
    end

    local current = ctx:get(monster, component.PROJECTILE_SLOW)

    if current then
        current.remaining_aut = current.remaining_aut + duration
        ctx:set(monster, component.PROJECTILE_SLOW, current)
        return
    end

    local actor = ctx:get(monster, component.ACTOR)
    local speed = actor.speed

    actor.speed = roll.random_divide(ctx, speed * 2, 3, stream)
    ctx:set(monster, component.ACTOR, actor)
    ctx:add(monster, component.PROJECTILE_SLOW, {
        base_speed = speed,
        remaining_aut = duration,
    })

    if senses.player_sees_actor(ctx, monster) then
        ctx:emit("spell", "The " .. display.name(ctx, monster) ..
            " seems to slow down.")
    end
end

return exposure
