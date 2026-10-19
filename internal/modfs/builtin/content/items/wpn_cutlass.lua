-- cutlass (WPN_CUTLASS) belongs to OBJ_WEAPONS and occupies the weapon slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "WPN_CUTLASS",
    name = "cutlass",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 56,
    slot = "weapon",
    weapon_skill = "SK_SHORT_BLADES",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- cutlass has its display text here so identification policy can choose known
    -- or unknown names consistently.
    naming = {
        text = "cutlass",
        kind = "static",
    },
    explicitly_removed = false,
    -- cutlass uses base damage 8 and delay 12; melee policy adds skill, brands and
    -- defenses.
    weapon = {
        damage = 8,
        hit = 4,
        speed = 12,
        commonness = 0,
        acquire_weight = 0,
        price = 0,
        skill_id = "SK_SHORT_BLADES",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_LITTLE",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_SLICING",
            "DAM_PIERCE",
        },
        brand_weights = mod.null,
    },
    -- Source: crawl-ref/source/item-prop.cc
    -- Generation mode random controls whether cutlass enters random item pools;
    -- held copies remain separate entities.
    generation = {
        mode = "random",
        commonness = 0,
    },
}

register.definition(categories.ITEMS, definition)

return definition
