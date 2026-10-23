-- Card area effects use the source seven-cell LOS_NO_TRANS footprint. Sort
-- by map cell so seeded outcomes do not depend on ECS query or load order.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local flags = require("constants.monster_flags")

local nearby = {}
local SIGHT_RADIUS = 7

-- Exclude projectile bodies from source choose_any_monster eligibility.
local function projectile(definition)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.PROJECTILE then
            return true
        end
    end

    return false
end

-- Return currently living, visible monsters in row-major cell order.
-- Callers apply their own allegiance and threat filters afterward.
function nearby.monsters(ctx, player)
    local origin = ctx:get(player, component.POSITION)
    local found = {}

    for _, entity in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if entity ~= player then
            local position = ctx:get(entity, component.POSITION)
            local health = ctx:get(entity, component.HEALTH)
            local distance = math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if health.current > 0 and
                position.level_id == origin.level_id and
                distance <= SIGHT_RADIUS and
                ctx:visible_no_trans(origin.level_id, origin.x,
                    origin.y, SIGHT_RADIUS, position.x, position.y) then
                local actor = ctx:get(entity, component.ACTOR)
                local definition = catalog.get(categories.MONSTERS,
                    actor.kind_id)

                if not projectile(definition) then
                    found[#found + 1] = {
                        entity = entity,
                        definition = definition,
                        position = position,
                    }
                end
            end
        end
    end

    table.sort(found, function(left, right)
        if left.position.y ~= right.position.y then
            return left.position.y < right.position.y
        end

        if left.position.x ~= right.position.x then
            return left.position.x < right.position.x
        end

        return ctx:id(left.entity) < ctx:id(right.entity)
    end)

    return found
end

return nearby
