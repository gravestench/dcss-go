local streams = require("constants.rng_streams")
local catalog = require("policy.item_generation.catalog")
local purpose = require("constants.item_generation_purpose")
local classes = require("ids.object_classes")
local quality = require("constants.vault_item_quality")

local policy = {}

function policy.eligible(_, definition, request)
    if definition.class ~= classes.OBJ_GOLD then
        return false
    end

    return definition.generation.mode == "random" or
        request.kind_id == definition.id
end

function policy.weight()
    return 1
end

function policy.roll(ctx, _, request, result)
    -- Source: crawl-ref/source/makeitem.cc:1901-1911.
    if request.purpose == purpose.ACQUIREMENT then
        -- Source: crawl-ref/source/acquire.cc:1246.
        result.quantity = 200 + 2 * ctx:random(streams.ITEM_GENERATION, 601)

        return
    end

    if request.quality == quality.GOOD or
        request.quality == quality.SUPERB then
        result.quantity = 100 + ctx:random(streams.ITEM_GENERATION, 400)

        return
    end

    local first = ctx:random(streams.ITEM_GENERATION, 19)
    local second = ctx:random(streams.ITEM_GENERATION, 19)

    result.quantity = 1 + math.floor((first + second) / 2) +
        ctx:random(streams.ITEM_GENERATION, request.depth)
end

catalog.register(classes.OBJ_GOLD, policy)

return policy
