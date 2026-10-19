-- eveningstar (WPN_EVENINGSTAR) belongs to OBJ_WEAPONS and occupies the
-- weapon slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_EVENINGSTAR",
    name = "eveningstar",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 8,
    slot = "weapon",
    weapon_skill = "SK_MACES_FLAILS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- eveningstar has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "eveningstar",
        kind = "static",
    },
    explicitly_removed = false,
    -- eveningstar uses base damage 15 and delay 15; melee policy adds skill,
    -- brands and defenses.
    weapon = {
        damage = 15,
        hit = -1,
        speed = 15,
        commonness = 0,
        acquire_weight = 2,
        price = 150,
        skill_id = "SK_MACES_FLAILS",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_LITTLE",
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
                brand_id = brands.DRAINING,
                weight = 19,
            },
            {
                brand_id = brands.HOLY_WRATH,
                weight = 15,
            },
            {
                brand_id = brands.NORMAL,
                weight = 8,
            },
            {
                brand_id = brands.VORPAL,
                weight = 6,
            },
            {
                brand_id = brands.VENOM,
                weight = 6,
            },
            {
                brand_id = brands.FLAMING,
                weight = 6,
            },
            {
                brand_id = brands.FREEZING,
                weight = 6,
            },
            {
                brand_id = brands.DISTORTION,
                weight = 2,
            },
            {
                brand_id = brands.ANTIMAGIC,
                weight = 2,
            },
            {
                brand_id = brands.PAIN,
                weight = 2,
            },
            {
                brand_id = brands.VAMPIRISM,
                weight = 2,
            },
        },
    },
    -- Source: crawl-ref/source/item-prop.cc
    -- Generation mode random controls whether eveningstar enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        commonness = 0,
    },
}

register.definition(categories.ITEMS, definition)

return definition
