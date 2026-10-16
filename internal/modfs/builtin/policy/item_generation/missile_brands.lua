local streams = require("constants.rng_streams")
local brands = require("constants.missile_brands")
local ids = require("ids.items")
local quality = require("constants.vault_item_quality")
local source = require("policy.item_generation.source_roll")

local missile_brands = {}

local function normal_weight(ctx, request)
    if request.quality == quality.GOOD or
        request.quality == quality.SUPERB then
        return 0
    end

    local bound = math.max(1, 2000 - 55 * request.depth)

    return ctx:random(streams.ITEM_GENERATION, bound)
end

local function curare_denominator(depth)
    if depth > 27 then
        return 6
    end

    if depth < 2 then
        return 15
    end

    return math.floor((364 - 7 * depth) / 25)
end

function missile_brands.roll(ctx, definition, request)
    if request.ego then
        return request.ego
    end

    local kind_id = definition.id

    if kind_id ~= ids.MI_DART and
        kind_id ~= ids.MI_JAVELIN and
        kind_id ~= ids.MI_BOOMERANG then
        return ""
    end

    -- Source: crawl-ref/source/makeitem.cc:490-539. Both random weights
    -- are drawn before the subtype's brand choice.
    local ordinary = normal_weight(ctx, request)
    local poisoned = normal_weight(ctx, request)

    if kind_id == ids.MI_DART then
        if source.chance(ctx, 1, curare_denominator(request.depth)) then
            return brands.CURARE
        end

        return source.weighted_id(ctx, {
            {
                id = brands.BLINDING,
                weight = 60,
            },
            {
                id = brands.FRENZY,
                weight = 20,
            },
            {
                id = brands.POISONED,
                weight = poisoned,
            },
        })
    end

    if kind_id == ids.MI_JAVELIN then
        local brand = source.weighted_id(ctx, {
            {
                id = brands.SILVER,
                weight = 90,
            },
            {
                id = "",
                weight = ordinary,
            },
        })

        return brand
    end

    return source.weighted_id(ctx, {
        {
            id = brands.SILVER,
            weight = 30,
        },
        {
            id = brands.DISPERSAL,
            weight = 30,
        },
        {
            id = "",
            weight = ordinary,
        },
    })
end

return missile_brands
