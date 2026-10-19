local streams = require("constants.rng_streams")
local catalog = require("policy.item_generation.catalog")
local classes = require("ids.object_classes")
local ids = require("ids.items")
local missile_brands = require("policy.item_generation.missile_brands")
local source = require("policy.item_generation.source_roll")

local policy = {}

-- Source: crawl-ref/source/makeitem.cc.
local source_weights = {
    [ids.MI_STONE] = 50,
    [ids.MI_DART] = 10,
    [ids.MI_BOOMERANG] = 3,
    [ids.MI_JAVELIN] = 2,
    [ids.MI_THROWING_NET] = 1,
    [ids.MI_LARGE_ROCK] = 1,
}

-- Example: policy.eligible(nil, arrow_kind, request) requires a random missile kind to have positive weight.
-- Explicit missile kinds bypass the random weight gate but cannot use generation mode none.
function policy.eligible(_, definition, request)
    if definition.class ~= classes.OBJ_MISSILES then
        return false
    end

    if request.kind_id == definition.id then
        return definition.generation.mode ~= "none"
    end

    return definition.generation.mode == "random" and
        policy.weight(nil, definition) > 0
end

-- Use source fallback weights only when the definition omits one.
function policy.weight(_, definition)
    return definition.generation.weight or source_weights[definition.id] or 0
end

-- Stack sizes differ for rocks, stones, nets, and brandable missiles.
function policy.roll(ctx, definition, request, result)
    -- Source: crawl-ref/source/makeitem.cc.
    if definition.id == ids.MI_LARGE_ROCK then
        result.quantity = 2 + source.average(ctx, 5, 2)
    elseif definition.id == ids.MI_STONE then
        result.quantity = 1 + ctx:random(streams.ITEM_GENERATION, 5) +
            ctx:random(streams.ITEM_GENERATION, 5)
    elseif definition.id == ids.MI_THROWING_NET then
        result.quantity = 1 + (source.chance(ctx, 1, 4) and 1 or 0)
    else
        result.ego = missile_brands.roll(ctx, definition, request)
        result.quantity = source.between(ctx, 2, 6)
    end
end

catalog.register(classes.OBJ_MISSILES, policy)

return policy
