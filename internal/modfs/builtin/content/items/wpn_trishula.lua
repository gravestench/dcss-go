-- trishula (WPN_TRISHULA) belongs to OBJ_WEAPONS and occupies the weapon
-- slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_TRISHULA",
    name = "trishula",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 52,
    slot = "weapon",
    weapon_skill = "SK_POLEARMS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- trishula has its display text here so identification policy can choose known
    -- or unknown names consistently.
    naming = {
        text = "trishula",
        kind = "static",
    },
    explicitly_removed = false,
    -- trishula uses base damage 13 and delay 13; melee policy adds skill, brands
    -- and defenses.
    weapon = {
        damage = 13,
        hit = 0,
        speed = 13,
        commonness = 0,
        acquire_weight = 0,
        price = 200,
        skill_id = "SK_POLEARMS",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_MEDIUM",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_PIERCING",
        },
        brand_weights = {
            {
                brand_id = brands.HOLY_WRATH,
                weight = 100,
            },
        },
    },
    -- Source: crawl-ref/source/item-prop.cc
    -- Generation mode random controls whether trishula enters random item pools;
    -- held copies remain separate entities.
    generation = {
        mode = "random",
        commonness = 0,
    },
}

register.definition(categories.ITEMS, definition)

return definition
