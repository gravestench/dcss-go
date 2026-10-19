-- great mace (WPN_GREAT_MACE) belongs to OBJ_WEAPONS and occupies the weapon
-- slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_GREAT_MACE",
    name = "great mace",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 9,
    slot = "weapon",
    weapon_skill = "SK_MACES_FLAILS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- great mace has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "great mace",
        kind = "static",
    },
    explicitly_removed = false,
    -- great mace uses base damage 17 and delay 17; melee policy adds skill, brands
    -- and defenses.
    weapon = {
        damage = 17,
        hit = -4,
        speed = 17,
        commonness = 3,
        acquire_weight = 10,
        price = 65,
        skill_id = "SK_MACES_FLAILS",
        min_2h_size_id = "SIZE_MEDIUM",
        min_1h_size_id = "NUM_SIZE_LEVELS",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_CRUSHING",
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
    -- Generation mode random controls whether great mace enters random item pools;
    -- held copies remain separate entities.
    generation = {
        mode = "random",
        commonness = 3,
    },
}

register.definition(categories.ITEMS, definition)

return definition
