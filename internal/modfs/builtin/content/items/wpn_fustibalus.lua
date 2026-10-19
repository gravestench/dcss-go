-- fustibalus (WPN_FUSTIBALUS) belongs to OBJ_WEAPONS and occupies the weapon
-- slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_FUSTIBALUS",
    name = "fustibalus",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 53,
    slot = "weapon",
    weapon_skill = "SK_RANGED_WEAPONS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- fustibalus has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "fustibalus",
        kind = "static",
    },
    explicitly_removed = false,
    -- fustibalus uses base damage 10 and delay 16; melee policy adds skill, brands
    -- and defenses.
    weapon = {
        damage = 10,
        hit = -2,
        speed = 16,
        commonness = 0,
        acquire_weight = 0,
        price = 150,
        skill_id = "SK_RANGED_WEAPONS",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_SMALL",
        ammo_id = "MI_SLING_BULLET",
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
    -- Generation mode random controls whether fustibalus enters random item pools;
    -- held copies remain separate entities.
    generation = {
        mode = "random",
        commonness = 0,
    },
}

register.definition(categories.ITEMS, definition)

return definition
