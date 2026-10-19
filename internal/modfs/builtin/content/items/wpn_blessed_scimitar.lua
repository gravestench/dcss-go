-- old scimitar (WPN_BLESSED_SCIMITAR) belongs to OBJ_WEAPONS and occupies the
-- weapon slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "WPN_BLESSED_SCIMITAR",
    name = "old scimitar",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 46,
    slot = "weapon",
    weapon_skill = "SK_LONG_BLADES",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- old scimitar has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "old scimitar",
        kind = "static",
    },
    explicitly_removed = false,
    -- old scimitar uses base damage 12 and delay 14; melee policy adds skill,
    -- brands and defenses.
    weapon = {
        damage = 12,
        hit = -2,
        speed = 14,
        commonness = 0,
        acquire_weight = 0,
        price = 0,
        skill_id = "SK_LONG_BLADES",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_LITTLE",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_SLICING",
        },
        brand_weights = mod.null,
    },
    -- Source: crawl-ref/source/item-prop.cc
    -- Generation mode random controls whether old scimitar enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        commonness = 0,
    },
}

register.definition(categories.ITEMS, definition)

return definition
