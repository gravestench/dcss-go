local streams = require("constants.rng_streams")
local catalog = require("policy.item_generation.catalog")
local purpose = require("constants.item_generation_purpose")
local classes = require("ids.object_classes")
local quality = require("constants.vault_item_quality")

local policy = {}

-- Explicit gold remains requestable even when ordinary random mode is unavailable.
function policy.eligible(_, definition, request)
    if definition.class ~= classes.OBJ_GOLD then
        return false
    end

    return definition.generation.mode == "random" or
        request.kind_id == definition.id
end

-- Gold contributes a single candidate to its class pool.
function policy.weight()
    return 1
end

-- Example: policy.roll(ctx, gold_kind, { purpose = purpose.ACQUIREMENT }, result) grants at least 200 gold.
-- Resolve acquirement first, then quality, so their distinct source quantity bands never overlap.
function policy.roll(ctx, _, request, result)
    -- Source: crawl-ref/source/makeitem.cc.
    if request.purpose == purpose.ACQUIREMENT then
        -- Source: crawl-ref/source/acquire.cc.
        result.quantity = 200 + 2 * ctx:random(streams.ITEM_GENERATION, 601)

        return
    end

    if request.quality == quality.GIFT or
        request.quality == quality.GOOD or
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
