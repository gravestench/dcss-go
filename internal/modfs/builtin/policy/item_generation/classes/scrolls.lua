local streams = require("constants.rng_streams")
local catalog = require("policy.item_generation.catalog")
local classes = require("ids.object_classes")
local item_sets = require("policy.item_generation.item_sets")

local policy = {}

function policy.eligible(ctx, definition, request)
    if definition.class ~= classes.OBJ_SCROLLS then
        return false
    end

    if request.kind_id == definition.id then
        return definition.generation.mode ~= "none"
    end

    return definition.generation.mode == "random" and
        item_sets.allowed(ctx, ctx:player(), definition.id)
end

function policy.weight(_, definition)
    -- Source: makeitem.cc:1358-1404. The import pins rarity weights.
    return definition.generation.weight or 0
end

function policy.roll(ctx, _, _, result)
    -- Source: makeitem.cc:1407-1410. Two and three scroll stacks are rare.
    local draw = ctx:random(streams.ITEM_GENERATION, 48)

    if draw == 46 then
        result.quantity = 2
    elseif draw == 47 then
        result.quantity = 3
    end
end

catalog.register(classes.OBJ_SCROLLS, policy)

return policy
