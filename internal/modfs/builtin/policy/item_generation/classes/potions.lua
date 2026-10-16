local streams = require("constants.rng_streams")
local catalog = require("policy.item_generation.catalog")
local classes = require("ids.object_classes")

local policy = {}

function policy.eligible(_, definition, request)
    if definition.class ~= classes.OBJ_POTIONS then
        return false
    end

    return definition.generation.mode == "random" or
        request.kind_id == definition.id and
        definition.generation.mode == "forced"
end

function policy.weight(_, definition)
    return definition.generation.weight or 0
end

function policy.roll(ctx, _, _, result)
    -- Source: crawl-ref/source/makeitem.cc:1287-1300.
    if ctx:random(streams.ITEM_GENERATION, 18) == 0 then
        result.quantity = result.quantity + 1
    end

    if ctx:random(streams.ITEM_GENERATION, 25) == 0 then
        result.quantity = result.quantity + 1
    end
end

catalog.register(classes.OBJ_POTIONS, policy)

return policy
