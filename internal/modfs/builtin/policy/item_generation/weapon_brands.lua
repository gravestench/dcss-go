local brands = require("constants.weapon_brands")
local quality = require("constants.vault_item_quality")
local source = require("policy.item_generation.source_roll")

local weapon_brands = {}

-- Demonic bases use their own brand handling before ordinary weapon weights.
local function is_demonic(definition)
    return definition.id:match("^WPN_DEMON_") ~= nil
end

-- Example: weapon_brands.roll(ctx, sword, request) draws an allowed brand for that weapon base.
-- Respect an explicit ego, then draw only from the base's normalized brand table with bounded retries.
function weapon_brands.roll(ctx, definition, request)
    if request.ego then
        return request.ego
    end

    -- Catalog `mod.null` means this weapon has no authored brand pool. It is
    -- truthy in Lua, so normalize it before taking the length or drawing.
    local configured = definition.weapon and definition.weapon.brand_weights
    local weights = type(configured) == "table" and configured or {}

    if #weights == 0 then
        return ""
    end

    local tries = 0

    if request.quality == quality.GIFT or
        request.quality == quality.GOOD or
        request.quality == quality.SUPERB then
        tries = 5
    elseif is_demonic(definition) or
        source.chance(ctx, 101 + request.depth, 300) then
        tries = 1
    end

    -- Source: crawl-ref/source/makeitem.cc and
    -- item-prop.cc. A normal result is retried for good gear.
    for _ = 1, tries do
        local brand = source.weighted_id(ctx, weights)

        if brand ~= brands.NORMAL then
            return brand
        end
    end

    return ""
end

return weapon_brands
