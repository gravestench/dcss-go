-- battleaxe (WPN_BATTLEAXE) belongs to OBJ_WEAPONS and occupies the weapon
-- slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")

local definition = {
    id = "WPN_BATTLEAXE",
    name = "battleaxe",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 21,
    slot = "weapon",
    weapon_skill = "SK_AXES",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- battleaxe has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "battleaxe",
        kind = "static",
    },
    explicitly_removed = false,
    -- battleaxe uses base damage 15 and delay 17; melee policy adds skill, brands
    -- and defenses.
    weapon = {
        damage = 15,
        hit = -4,
        speed = 17,
        commonness = 6,
        acquire_weight = 10,
        price = 65,
        skill_id = "SK_AXES",
        min_2h_size_id = "SIZE_MEDIUM",
        min_1h_size_id = "NUM_SIZE_LEVELS",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_CHOPPING",
        },
        brand_weights = {
            {
                brand_id = brands.NORMAL,
                weight = 31,
            },
            {
                brand_id = brands.VORPAL,
                weight = 16,
            },
            {
                brand_id = brands.ELECTROCUTION,
                weight = 11,
            },
            {
                brand_id = brands.FLAMING,
                weight = 10,
            },
            {
                brand_id = brands.FREEZING,
                weight = 10,
            },
            {
                brand_id = brands.VENOM,
                weight = 8,
            },
            {
                brand_id = brands.VAMPIRISM,
                weight = 5,
            },
            {
                brand_id = brands.DRAINING,
                weight = 3,
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
                weight = 1,
            },
            {
                brand_id = brands.HOLY_WRATH,
                weight = 1,
            },
        },
    },
    -- Source: crawl-ref/source/item-prop.cc
    -- Generation mode random controls whether battleaxe enters random item pools;
    -- held copies remain separate entities.
    generation = {
        mode = "random",
        commonness = 6,
    },
}

register.definition(categories.ITEMS, definition)

return definition
