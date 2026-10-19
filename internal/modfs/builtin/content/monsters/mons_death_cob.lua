-- death cob (MONS_DEATH_COB) is a DCSS monster profile with 14 hit dice and
-- speed 25.
-- Its first melee contact is AT_HIT for 35 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_DEATH_COB",
    status = "defined",
    name = "death cob",
    glyph = 122,
    colour_id = "YELLOW",
    flags = {
        "M_SPEAKS",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_DEATH_COB",
    species_id = "MONS_DEATH_COB",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 40,
    -- death cob offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_DRAIN_SPEED",
            damage = 35,
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
    hd = 14,
    average_hp_10x = 910,
    ac = 10,
    ev = 15,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_MOAN",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 25,
    -- For death cob, energy costs combine with speed 25 to determine action
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
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_TINY",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_DEATH_COB",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
