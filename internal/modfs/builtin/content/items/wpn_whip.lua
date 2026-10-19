-- whip (WPN_WHIP) belongs to OBJ_WEAPONS and occupies the weapon slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_WHIP",
    name = "whip",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 1,
    slot = "weapon",
    weapon_skill = "SK_MACES_FLAILS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- whip has its display text here so identification policy can choose known or
    -- unknown names consistently.
    naming = {
        text = "whip",
        kind = "static",
    },
    explicitly_removed = false,
    -- whip uses base damage 6 and delay 11; melee policy adds skill, brands and
    -- defenses.
    weapon = {
        damage = 6,
        hit = 2,
        speed = 11,
        commonness = 4,
        acquire_weight = 0,
        price = 25,
        skill_id = "SK_MACES_FLAILS",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_LITTLE",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_SLASHING",
        },
        brand_weights = {
            {
                brand_id = brands.NORMAL,
                weight = 34,
            },
            {
                brand_id = brands.VENOM,
                weight = 16,
            },
            {
                brand_id = brands.ELECTROCUTION,
                weight = 16,
            },
            {
                brand_id = brands.DRAINING,
                weight = 7,
            },
            {
                brand_id = brands.FREEZING,
                weight = 6,
            },
            {
                brand_id = brands.FLAMING,
                weight = 6,
            },
            {
                brand_id = brands.VAMPIRISM,
                weight = 5,
            },
            {
                brand_id = brands.PAIN,
                weight = 4,
            },
            {
                brand_id = brands.HOLY_WRATH,
                weight = 3,
            },
            {
                brand_id = brands.DISTORTION,
                weight = 2,
            },
            {
                brand_id = brands.ANTIMAGIC,
                weight = 1,
            },
        },
    },
    -- Source: crawl-ref/source/item-prop.cc
    -- Generation mode random controls whether whip enters random item pools; held
    -- copies remain separate entities.
    generation = {
        mode = "random",
        commonness = 4,
    },
}

register.definition(categories.ITEMS, definition)

return definition
