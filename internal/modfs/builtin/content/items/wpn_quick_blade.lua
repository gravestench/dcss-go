-- quick blade (WPN_QUICK_BLADE) belongs to OBJ_WEAPONS and occupies the
-- weapon slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "WPN_QUICK_BLADE",
    name = "quick blade",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 11,
    slot = "weapon",
    weapon_skill = "SK_SHORT_BLADES",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- quick blade has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "quick blade",
        kind = "static",
    },
    explicitly_removed = false,
    -- quick blade uses base damage 4 and delay 7; melee policy adds skill, brands
    -- and defenses.
    weapon = {
        damage = 4,
        hit = 6,
        speed = 7,
        commonness = 0,
        acquire_weight = 2,
        price = 150,
        skill_id = "SK_SHORT_BLADES",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_LITTLE",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_PIERCING",
        },
        brand_weights = mod.null,
    },
    -- Source: crawl-ref/source/item-prop.cc
    -- Generation mode random controls whether quick blade enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        commonness = 0,
    },
}

register.definition(categories.ITEMS, definition)

return definition
