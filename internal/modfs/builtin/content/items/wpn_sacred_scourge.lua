-- sacred scourge (WPN_SACRED_SCOURGE) belongs to OBJ_WEAPONS and occupies the
-- weapon slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_SACRED_SCOURGE",
    name = "sacred scourge",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 51,
    slot = "weapon",
    weapon_skill = "SK_MACES_FLAILS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- sacred scourge has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "sacred scourge",
        kind = "static",
    },
    explicitly_removed = false,
    -- sacred scourge uses base damage 12 and delay 11; melee policy adds skill,
    -- brands and defenses.
    weapon = {
        damage = 12,
        hit = 0,
        speed = 11,
        commonness = 0,
        acquire_weight = 0,
        price = 200,
        skill_id = "SK_MACES_FLAILS",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_LITTLE",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_SLASHING",
        },
        brand_weights = {
            {
                brand_id = brands.HOLY_WRATH,
                weight = 100,
            },
        },
    },
    -- Source: crawl-ref/source/item-prop.cc
    -- Generation mode random controls whether sacred scourge enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        commonness = 0,
    },
}

register.definition(categories.ITEMS, definition)

return definition
