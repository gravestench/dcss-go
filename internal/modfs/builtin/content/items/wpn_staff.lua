-- staff (WPN_STAFF) belongs to OBJ_WEAPONS and occupies the weapon slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "WPN_STAFF",
    name = "staff",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 40,
    slot = "weapon",
    weapon_skill = "SK_STAVES",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- staff has its display text here so identification policy can choose known or
    -- unknown names consistently.
    naming = {
        text = "staff",
        kind = "static",
    },
    explicitly_removed = false,
    -- staff uses base damage 5 and delay 12; melee policy adds skill, brands and
    -- defenses.
    weapon = {
        damage = 5,
        hit = 5,
        speed = 12,
        commonness = 0,
        acquire_weight = 0,
        price = 15,
        skill_id = "SK_STAVES",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_MEDIUM",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_CRUSHING",
        },
        brand_weights = mod.null,
    },
    -- Source: crawl-ref/source/item-prop.cc
    -- Generation mode random controls whether staff enters random item pools; held
    -- copies remain separate entities.
    generation = {
        mode = "random",
        commonness = 0,
    },
}

register.definition(categories.ITEMS, definition)

return definition
