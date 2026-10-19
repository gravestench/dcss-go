local streams = require("constants.rng_streams")
local catalog = require("policy.item_generation.catalog")
local classes = require("ids.object_classes")

local policy = {}

-- Example: policy.eligible(nil, potion_kind, request) omits potion kinds barred from random generation.
-- Permit forced-mode potions only when named by the request; random draws stay in random-mode stock.
function policy.eligible(_, definition, request)
    if definition.class ~= classes.OBJ_POTIONS then
        return false
    end

    return definition.generation.mode == "random" or
        request.kind_id == definition.id and
        definition.generation.mode == "forced"
end

-- A potion without a generation weight cannot enter a random subtype draw.
function policy.weight(_, definition)
    return definition.generation.weight or 0
end

-- Two independent rare rolls add at most two extra potions to a stack.
function policy.roll(ctx, _, _, result)
    -- Source: crawl-ref/source/makeitem.cc.
    if ctx:random(streams.ITEM_GENERATION, 18) == 0 then
        result.quantity = result.quantity + 1
    end

    if ctx:random(streams.ITEM_GENERATION, 25) == 0 then
        result.quantity = result.quantity + 1
    end
end

catalog.register(classes.OBJ_POTIONS, policy)

return policy
