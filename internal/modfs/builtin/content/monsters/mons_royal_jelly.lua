-- the Royal Jelly (MONS_ROYAL_JELLY) is a DCSS monster profile with 21 hit
-- dice and speed 14.
-- Its first melee contact is AT_HIT for 50 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_ROYAL_JELLY",
    status = "defined",
    name = "the Royal Jelly",
    glyph = 74,
    colour_id = "YELLOW",
    flags = {
        "M_SEE_INVIS",
        "M_UNBLINDABLE",
        "M_ACID_SPLASH",
        "M_UNIQUE",
        "M_EAT_DOORS",
        "M_TALL_TILE",
        "M_WEB_IMMUNE",
        "M_NO_SKELETON",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_ACID",
            level = 3,
        },
    },
    xp_modifier = 20,
    genus_id = "MONS_JELLY",
    species_id = "MONS_JELLY",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 180,
    -- the Royal Jelly offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_ACID",
            damage = 50,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_ACID",
            damage = 30,
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
    hd = 21,
    average_hp_10x = 2310,
    ac = 8,
    ev = 4,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_LAND",
    speed = 14,
    -- For the Royal Jelly, energy costs combine with speed 14 to determine action
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_BLOB",
    tile = {
        id = "TILEP_MONS_ROYAL_JELLY",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
