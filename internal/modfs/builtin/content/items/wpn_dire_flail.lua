-- dire flail (WPN_DIRE_FLAIL) belongs to OBJ_WEAPONS and occupies the weapon
-- slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_DIRE_FLAIL",
    name = "dire flail",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 7,
    slot = "weapon",
    weapon_skill = "SK_MACES_FLAILS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- dire flail has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "dire flail",
        kind = "static",
    },
    explicitly_removed = false,
    -- dire flail uses base damage 13 and delay 13; melee policy adds skill, brands
    -- and defenses.
    weapon = {
        damage = 13,
        hit = -3,
        speed = 13,
        commonness = 2,
        acquire_weight = 10,
        price = 40,
        skill_id = "SK_MACES_FLAILS",
        min_2h_size_id = "SIZE_MEDIUM",
        min_1h_size_id = "NUM_SIZE_LEVELS",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_CRUSHING",
            "DAM_PIERCE",
        },
        brand_weights = {
            {
                brand_id = brands.PROTECTION,
                weight = 30,
            },
            {
                brand_id = brands.NORMAL,
                weight = 28,
            },
            {
                brand_id = brands.HOLY_WRATH,
                weight = 15,
            },
            {
                brand_id = brands.VORPAL,
                weight = 14,
            },
            {
                brand_id = brands.DRAINING,
                weight = 10,
            },
            {
                brand_id = brands.VENOM,
                weight = 5,
            },
            {
                brand_id = brands.DISTORTION,
                weight = 1,
            },
            {
                brand_id = brands.ANTIMAGIC,
                weight = 1,
            },
            {
                brand_id = brands.PAIN,
                weight = 1,
            },
        },
    },
    -- Source: crawl-ref/source/item-prop.cc
    -- Generation mode random controls whether dire flail enters random item pools;
    -- held copies remain separate entities.
    generation = {
        mode = "random",
        commonness = 2,
    },
}

register.definition(categories.ITEMS, definition)

return definition
