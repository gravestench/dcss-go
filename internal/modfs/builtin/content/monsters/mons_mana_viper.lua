-- mana viper (MONS_MANA_VIPER) is a DCSS monster profile with 9 hit dice and
-- speed 14.
-- Its first melee contact is AT_BITE for 23 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_MANA_VIPER",
    status = "defined",
    name = "mana viper",
    glyph = 83,
    colour_id = "MAGENTA",
    flags = {
        "M_COLD_BLOOD",
        "M_SEE_INVIS",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_SNAKE",
    species_id = "MONS_MANA_VIPER",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 100,
    -- mana viper offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_ANTIMAGIC",
            damage = 23,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 9,
    average_hp_10x = 495,
    ac = 3,
    ev = 14,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_HISS",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 14,
    -- For mana viper, energy costs combine with speed 14 to determine action
    -- cadence, not an unconditional action each turn.
    energy = {
        move = 10,
        swim = 10,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_SNAKE",
    tile = {
        id = "TILEP_MONS_MANA_VIPER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
