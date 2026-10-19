-- blowgun (WPN_BLOWGUN) belongs to OBJ_WEAPONS and occupies the weapon slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "WPN_BLOWGUN",
    name = "blowgun",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 28,
    slot = "weapon",
    weapon_skill = "SK_THROWING",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- blowgun has its display text here so identification policy can choose known
    -- or unknown names consistently.
    naming = {
        text = "blowgun",
        kind = "static",
    },
    explicitly_removed = false,
    -- blowgun uses base damage 0 and delay 10; melee policy adds skill, brands and
    -- defenses.
    weapon = {
        damage = 0,
        hit = 2,
        speed = 10,
        commonness = 0,
        acquire_weight = 0,
        price = 0,
        skill_id = "SK_THROWING",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_LITTLE",
        ammo_id = "MI_NEEDLE",
        damage_flags = {
            "DAMV_NON_MELEE",
        },
        brand_weights = mod.null,
    },
    -- Source: crawl-ref/source/item-prop.cc
    -- Generation mode random controls whether blowgun enters random item pools;
    -- held copies remain separate entities.
    generation = {
        mode = "random",
        commonness = 0,
    },
}

register.definition(categories.ITEMS, definition)

return definition
