-- Instant area spells need the same two geometry queries without sharing
-- their damage or ally-safety rules. This owner returns live actors in
-- stable order; each spell decides which of them it may harm.
-- Source: spl-damage.cc:_cast_los_attack_spell and beam.cc:bolt::explode.
-- Example: actors.los(ctx, caster, 7) includes a nearby ally because
-- Refrigeration can hurt it, while the spell's plan may decline that cast.
local component = require("constants.component")
local explosion = require("policy.combat.explosion")

local actors = {}

-- A LOS_NO_TRANS spell sees through actors but cannot reach through clear
-- or opaque walls. A dead actor remains in ECS until cleanup, so omit it.
function actors.los(ctx, caster, radius)
    local origin = ctx:get(caster, component.POSITION)

    if not origin then
        return {}
    end

    local found = {}

    for _, target in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if target ~= caster then
            local position = ctx:get(target, component.POSITION)
            local health = ctx:get(target, component.HEALTH)
            local distance = math.max(
                math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if health.current > 0 and
                position.level_id == origin.level_id and
                distance <= radius and
                ctx:visible_no_trans(origin.level_id,
                    origin.x, origin.y, radius,
                    position.x, position.y) then
                found[#found + 1] = target
            end
        end
    end

    return found
end

-- Explosion propagation already handles walls. Keep its cell order, then
-- ask the grid for current occupants so a moved actor is struck at most
-- once and an empty cell costs no actor-level work.
function actors.blast(ctx, level_id, center_x, center_y, radius)
    local found = {}

    for _, cell in ipairs(explosion.cells(ctx, level_id,
        center_x, center_y, radius)) do
        local target = ctx:actor_at(level_id, cell.x, cell.y)

        if target then
            local health = ctx:get(target, component.HEALTH)

            if health and health.current > 0 then
                found[#found + 1] = target
            end
        end
    end

    return found
end

return actors
