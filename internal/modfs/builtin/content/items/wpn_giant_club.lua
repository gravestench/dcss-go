-- giant club (WPN_GIANT_CLUB) belongs to OBJ_WEAPONS and occupies the weapon
-- slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_GIANT_CLUB",
    name = "giant club",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 33,
    slot = "weapon",
    weapon_skill = "SK_MACES_FLAILS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- giant club has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "giant club",
        kind = "static",
    },
    explicitly_removed = false,
    -- giant club uses base damage 20 and delay 16; melee policy adds skill, brands
    -- and defenses.
    weapon = {
        damage = 20,
        hit = -6,
        speed = 16,
        commonness = 1,
        acquire_weight = 10,
        price = 17,
        skill_id = "SK_MACES_FLAILS",
        min_2h_size_id = "SIZE_LARGE",
        min_1h_size_id = "NUM_SIZE_LEVELS",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_CRUSHING",
        },
        brand_weights = {
            {
                brand_id = brands.NORMAL,
                weight = 9,
            },
            {
                brand_id = brands.SPECTRAL,
                weight = 1,
            },
        },
    },
    -- Source: crawl-ref/source/item-prop.cc
    -- Generation mode random controls whether giant club enters random item pools;
    -- held copies remain separate entities.
    generation = {
        mode = "random",
        commonness = 1,
    },
}

register.definition(categories.ITEMS, definition)

return definition
