-- spiked flail (WPN_SPIKED_FLAIL) belongs to OBJ_WEAPONS and occupies the
-- weapon slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "WPN_SPIKED_FLAIL",
    name = "spiked flail",
    glyph = 41,
    class = "OBJ_WEAPONS",
    class_value = 0,
    subtype_value = 6,
    slot = "weapon",
    weapon_skill = "SK_MACES_FLAILS",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- spiked flail has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "spiked flail",
        kind = "static",
    },
    explicitly_removed = false,
    -- spiked flail uses base damage 5 and delay 13; melee policy adds skill,
    -- brands and defenses.
    weapon = {
        damage = 5,
        hit = 3,
        speed = 13,
        commonness = 0,
        acquire_weight = 0,
        price = 0,
        skill_id = "SK_MACES_FLAILS",
        min_2h_size_id = "SIZE_LITTLE",
        min_1h_size_id = "SIZE_LITTLE",
        ammo_id = "MI_NONE",
        damage_flags = {
            "DAMV_CRUSHING",
        },
        brand_weights = mod.null,
    },
    -- Source: crawl-ref/source/item-prop.cc
    -- Generation mode random controls whether spiked flail enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        commonness = 0,
    },
}

register.definition(categories.ITEMS, definition)

return definition
