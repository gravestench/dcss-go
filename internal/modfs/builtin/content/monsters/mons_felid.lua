-- felid (MONS_FELID) is a DCSS monster profile with 5 hit dice and speed 10.
-- Its first melee contact is AT_CLAW for 10 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_FELID",
    status = "defined",
    name = "felid",
    glyph = 104,
    colour_id = "MAGENTA",
    flags = {
        "M_SEE_INVIS",
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_NO_POLY_TO",
        "M_NO_GEN_DERIVED",
    },
    xp_modifier = 10,
    genus_id = "MONS_FELID",
    species_id = "MONS_FELID",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- felid offers AT_CLAW as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 10,
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
    hd = 5,
    average_hp_10x = 175,
    ac = 2,
    ev = 18,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_HISS",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For felid, energy costs combine with speed 10 to determine action cadence,
    -- not an unconditional action each turn.
    energy = {
        move = 8,
        swim = 8,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_STARTING_EQUIPMENT",
    size_id = "SIZE_LITTLE",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_FELID",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_FELID",
}

register.definition(categories.MONSTERS, definition)

return definition
