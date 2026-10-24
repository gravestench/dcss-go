-- Source bless_weapon changes the actual item subtype before it marks a
-- one-time capstone spent. The three demon/holy weapon pairs are the only
-- base-kind conversions; brands and enchantment apply to every eligible
-- ordinary weapon, including ranged ones for TSO and Kiku.
local component = require("constants.component")
local gods = require("constants.gods")
local items = require("ids.items")
local purpose = require("constants.item_generation_purpose")

local blessed = {}

local good_kind = {
    [items.WPN_DEMON_BLADE] = items.WPN_EUDEMON_BLADE,
    [items.WPN_DEMON_WHIP] = items.WPN_SACRED_SCOURGE,
    [items.WPN_DEMON_TRIDENT] = items.WPN_TRISHULA,
}

local evil_kind = {
    [items.WPN_EUDEMON_BLADE] = items.WPN_DEMON_BLADE,
    [items.WPN_SACRED_SCOURGE] = items.WPN_DEMON_WHIP,
    [items.WPN_TRISHULA] = items.WPN_DEMON_TRIDENT,
}

-- Source origin_acquired attributes a converted demon or already blessed
-- item to TSO. It remains the same Akara entity and keeps its inventory
-- and equipped components through the conversion.
local function record_holy_origin(ctx, entity)
    local origin = {
        purpose = purpose.GOD_GIFT,
        god_id = gods.SHINING_ONE,
    }

    if ctx:has(entity, component.ITEM_PROVENANCE) then
        ctx:set(entity, component.ITEM_PROVENANCE, origin)
    else
        ctx:add(entity, component.ITEM_PROVENANCE, origin)
    end
end

-- Apply both source enchant calls with the existing +9 cap and preserve
-- the item's stable entity ID. Extra effects run only after this succeeds.
function blessed.apply(ctx, entity, spec)
    local item = ctx:get(entity, component.ITEM)
    local old_kind = item.kind_id

    if spec.god_id == gods.SHINING_ONE then
        item.kind_id = good_kind[old_kind] or old_kind
    else
        item.kind_id = evil_kind[old_kind] or old_kind
    end

    item.ego = spec.brand
    item.plus = math.min(9, item.plus + 2)
    ctx:set(entity, component.ITEM, item)

    if spec.god_id == gods.SHINING_ONE and
        (good_kind[old_kind] or evil_kind[old_kind]) then
        record_holy_origin(ctx, entity)
    end

    return item
end

return blessed
