-- Good-neutral Jiyva slimes seek the nearest edible floor item they can
-- see. The saved items and per-cell vault properties are the only inputs;
-- catalog ordering cannot change this target or its tie break.
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local cells = require("policy.religion.jiyva.cells")
local edibility = require("policy.religion.jiyva.items")
local identity = require("policy.religion.jiyva.identity")
local targets = require("policy.ai.targets")

local module = {}

local SIGHT = 7

-- Compare distance, then map coordinates, so entity creation order and
-- layered catalog order never choose between equally close item cells.
local function precedes(candidate, best)
    if not best then
        return true
    end

    if candidate.distance ~= best.distance then
        return candidate.distance < best.distance
    end

    if candidate.y ~= best.y then
        return candidate.y < best.y
    end

    return candidate.x < best.x
end

-- Return a real floor location only while Jiyva's neutral-slime passive is
-- active. Another faction's neutral monster keeps its ordinary wandering.
function module.item(ctx, monster, position)
    local player = ctx:player()
    local actor = ctx:get(monster, component.ACTOR)

    if not player or not actor or
        not identity.passive(ctx, player) or
        targets.real_attitude(ctx, monster) ~= attitudes.GOOD_NEUTRAL then
        return nil
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    if not identity.slime(definition) then
        return nil
    end

    local best

    for _, entity in ipairs(ctx:query({
        component.ITEM,
        component.POSITION,
    })) do
        local item_position = ctx:get(entity, component.POSITION)

        if item_position.level_id == position.level_id and
            not ctx:has(entity, component.CARRIED_BY) and
            cells.allowed(ctx, item_position.level_id,
                item_position.x, item_position.y) and
            edibility.edible(ctx, entity) then
            local distance = math.max(
                math.abs(item_position.x - position.x),
                math.abs(item_position.y - position.y))

            if distance > 0 and distance <= SIGHT and
                ctx:visible(position.level_id, position.x,
                    position.y, SIGHT,
                    item_position.x, item_position.y) then
                local candidate = {
                    x = item_position.x,
                    y = item_position.y,
                    distance = distance,
                }

                if precedes(candidate, best) then
                    best = candidate
                end
            end
        end
    end

    return best
end

return module
