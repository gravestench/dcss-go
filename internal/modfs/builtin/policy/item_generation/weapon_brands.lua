local brands = require("constants.weapon_brands")
local quality = require("constants.vault_item_quality")
local source = require("policy.item_generation.source_roll")

local weapon_brands = {}

local function is_demonic(definition)
    return definition.id:match("^WPN_DEMON_") ~= nil
end

function weapon_brands.roll(ctx, definition, request)
    if request.ego then
        return request.ego
    end

    local weights = definition.weapon and definition.weapon.brand_weights or {}

    if #weights == 0 then
        return ""
    end

    local tries = 0

    if request.quality == quality.GOOD or
        request.quality == quality.SUPERB then
        tries = 5
    elseif is_demonic(definition) or
        source.chance(ctx, 101 + request.depth, 300) then
        tries = 1
    end

    -- Source: crawl-ref/source/makeitem.cc:252-278 and
    -- item-prop.cc:1098-1108. A normal result is retried for good gear.
    for _ = 1, tries do
        local brand = source.weighted_id(ctx, weights)

        if brand ~= brands.NORMAL then
            return brand
        end
    end

    return ""
end

return weapon_brands
