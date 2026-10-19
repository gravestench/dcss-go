-- shortbow (WPN_SHORTBOW) belongs to OBJ_WEAPONS and occupies the weapon
-- slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_SHORTBOW",
    name = "shortbow",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 30,
    slot = "weapon",
    weapon_skill = "SK_RANGED_WEAPONS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- shortbow has its display text here so identification policy can choose known
    -- or unknown names consistently.
    naming = {
        text = "shortbow",
        kind = "static",
    },
    explicitly_removed = false,
    -- shortbow uses base damage 9 and delay 15; melee policy adds skill, brands
    -- and defenses.
    weapon = {
        damage = 9,
        hit = 2,
        speed = 15,
        commonness = 8,
        acquire_weight = 10,
        price = 30,
        skill_id = "SK_RANGED_WEAPONS",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "NUM_SIZE_LEVELS",
        ammo_id = "MI_ARROW",
        damage_flags = {
            "DAMV_NON_MELEE",
        },
        brand_weights = {
            {
                brand_id = brands.NORMAL,
                weight = 58,
            },
            {
                brand_id = brands.FLAMING,
                weight = 16,
            },
            {
                brand_id = brands.FREEZING,
                weight = 16,
            },
            {
                brand_id = brands.VORPAL,
                weight = 10,
            },
        },
    },
    -- Source: crawl-ref/source/item-prop.cc
    -- Generation mode random controls whether shortbow enters random item pools;
    -- held copies remain separate entities.
    generation = {
        mode = "random",
        commonness = 8,
    },
}

register.definition(categories.ITEMS, definition)

return definition
