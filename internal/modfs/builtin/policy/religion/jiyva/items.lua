-- Every Jiyva slime path shares the source's item_is_jelly_edible rule.
-- Eligibility is about the live item entity, not its displayed appearance:
-- rare progress items and a net holding a creature must remain intact.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local classes = require("ids.object_classes")
local component = require("constants.component")
local item_ids = require("ids.items")

local items = {}

local protected_ids = {
    [item_ids.MISC_HORN_OF_GERYON] = true,
    [item_ids.MISC_ZIGGURAT] = true,
    [item_ids.ORB_ZOT] = true,
}

-- The source excludes special identities as well as entire rune and Orb
-- classes. A modded ordinary item stays edible without an engine whitelist.
function items.edible(ctx, entity)
    local item = ctx:get(entity, component.ITEM)

    if not item or ctx:has(entity, component.ITEM_ARTEFACT) or
        ctx:has(entity, component.VAULT_ITEM_MIMIC) or
        ctx:has(entity, component.PROJECTILE_NET) or
        protected_ids[item.kind_id] then
        return false
    end

    local definition = catalog.get(categories.ITEMS, item.kind_id)

    return definition.class ~= classes.OBJ_RUNES and
        definition.class ~= classes.OBJ_ORBS
end

return items
