-- Cause Fear and Mass Confusion share only target geometry and allegiance.
-- Their spell files own distinct immunities, saving throws, and statuses.
-- Source: mon-cast.cc:_mons_cause_fear and _mons_mass_confuse.
local component = require("constants.component")
local invisibility = require("policy.potions.invisibility")
local targets = require("policy.ai.targets")

local area = {}
local SIGHT_RADIUS = 7

-- LOS_NO_TRANS blocks clear and opaque walls but lets other actors stand
-- between the caster and victim. A player must also be visible to the
-- caster; invisible monsters in the area still receive the source effect.
local function in_area(ctx, caster, target, origin, position)
    if position.level_id ~= origin.level_id or
        targets.aligned(ctx, caster, target) then
        return false
    end

    local distance = math.max(math.abs(position.x - origin.x),
        math.abs(position.y - origin.y))

    if distance > SIGHT_RADIUS or
        not ctx:visible_no_trans(origin.level_id, origin.x, origin.y,
            SIGHT_RADIUS, position.x, position.y) then
        return false
    end

    return not ctx:has(target, component.PLAYER) or
        invisibility.visible_to(ctx, target, caster)
end

-- A plan needs one eligible body but cannot consume willpower or damage
-- rolls. Recheck this same set at resolution because actors may have moved.
function area.any(ctx, caster, eligible)
    local origin = ctx:get(caster, component.POSITION)

    if not origin then
        return false
    end

    for _, target in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        local position = ctx:get(target, component.POSITION)
        local health = ctx:get(target, component.HEALTH)

        if health.current > 0 and
            in_area(ctx, caster, target, origin, position) and
            eligible(ctx, caster, target) then
            return true
        end
    end

    return false
end

-- Visit eligible actors in stable ECS order, leaving the spell's own
-- resolver responsible for saves, status duration, and messages.
function area.each(ctx, caster, eligible, visit)
    local origin = ctx:get(caster, component.POSITION)

    if not origin then
        error("monster mind spell caster has no position")
    end

    for _, target in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        local position = ctx:get(target, component.POSITION)
        local health = ctx:get(target, component.HEALTH)

        if health.current > 0 and
            in_area(ctx, caster, target, origin, position) and
            eligible(ctx, caster, target) then
            visit(ctx, caster, target)
        end
    end
end

return area
