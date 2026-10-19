-- quicksilver ooze (MONS_QUICKSILVER_OOZE) is a DCSS monster profile with 13
-- hit dice and speed 16.
-- Its first melee contact is AT_HIT for 27 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_QUICKSILVER_OOZE",
    status = "defined",
    name = "quicksilver ooze",
    glyph = 74,
    colour_id = "CYAN",
    flags = {
        "M_SEE_INVIS",
        "M_UNBLINDABLE",
        "M_EAT_DOORS",
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
    xp_modifier = 15,
    genus_id = "MONS_JELLY",
    species_id = "MONS_QUICKSILVER_OOZE",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 5000,
    -- quicksilver ooze offers AT_HIT as its first contact; later slots are tried
    -- by the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_ENGULF",
            damage = 27,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_ANTIMAGIC",
            damage = 15,
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
    hd = 13,
    average_hp_10x = 500,
    ac = 3,
    ev = 15,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_LAND",
    speed = 16,
    -- For quicksilver ooze, energy costs combine with speed 16 to determine action
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
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_BLOB",
    tile = {
        id = "TILEP_MONS_QUICKSILVER_OOZE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
