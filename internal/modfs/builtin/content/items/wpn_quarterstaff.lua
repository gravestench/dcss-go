-- quarterstaff (WPN_QUARTERSTAFF) belongs to OBJ_WEAPONS and occupies the
-- weapon slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_QUARTERSTAFF",
    name = "quarterstaff",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 41,
    slot = "weapon",
    weapon_skill = "SK_STAVES",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- quarterstaff has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "quarterstaff",
        kind = "static",
    },
    explicitly_removed = false,
    -- quarterstaff uses base damage 10 and delay 13; melee policy adds skill,
    -- brands and defenses.
    weapon = {
        damage = 10,
        hit = 3,
        speed = 13,
        commonness = 8,
        acquire_weight = 10,
        price = 40,
        skill_id = "SK_STAVES",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "NUM_SIZE_LEVELS",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_CRUSHING",
        },
        brand_weights = {
            {
                brand_id = brands.NORMAL,
                weight = 50,
            },
            {
                brand_id = brands.SPECTRAL,
                weight = 18,
            },
            {
                brand_id = brands.DRAINING,
                weight = 8,
            },
            {
                brand_id = brands.VORPAL,
                weight = 8,
            },
            {
                brand_id = brands.SPEED,
                weight = 8,
            },
            {
                brand_id = brands.DISTORTION,
                weight = 2,
            },
            {
                brand_id = brands.PAIN,
                weight = 2,
            },
            {
                brand_id = brands.HOLY_WRATH,
                weight = 2,
            },
            {
                brand_id = brands.ANTIMAGIC,
                weight = 2,
            },
        },
    },
    -- Source: crawl-ref/source/item-prop.cc
    -- Generation mode random controls whether quarterstaff enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        commonness = 8,
    },
}

register.definition(categories.ITEMS, definition)

return definition
