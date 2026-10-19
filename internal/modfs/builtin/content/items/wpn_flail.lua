-- flail (WPN_FLAIL) belongs to OBJ_WEAPONS and occupies the weapon slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_FLAIL",
    name = "flail",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 4,
    slot = "weapon",
    weapon_skill = "SK_MACES_FLAILS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- flail has its display text here so identification policy can choose known or
    -- unknown names consistently.
    naming = {
        text = "flail",
        kind = "static",
    },
    explicitly_removed = false,
    -- flail uses base damage 10 and delay 14; melee policy adds skill, brands and
    -- defenses.
    weapon = {
        damage = 10,
        hit = 0,
        speed = 14,
        commonness = 8,
        acquire_weight = 10,
        price = 35,
        skill_id = "SK_MACES_FLAILS",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_LITTLE",
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
    -- Generation mode random controls whether flail enters random item pools; held
    -- copies remain separate entities.
    generation = {
        mode = "random",
        commonness = 8,
    },
}

register.definition(categories.ITEMS, definition)

return definition
