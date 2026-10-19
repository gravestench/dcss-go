-- demonic crawler (MONS_DEMONIC_CRAWLER) is a DCSS monster profile with 9 hit
-- dice and speed 13.
-- Its first melee contact is AT_HIT for 16 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_SCREAMER when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_DEMONIC_CRAWLER",
    status = "defined",
    name = "demonic crawler",
    glyph = 115,
    colour_id = "LIGHTGREEN",
    flags = {
        "M_NO_SKELETON",
        "M_SEE_INVIS",
        "M_WEB_IMMUNE",
    },
    resistances = {
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 1,
        },
        {
            id = "MR_RES_FIRE",
            level = 1,
        },
    },
    xp_modifier = 4,
    genus_id = "MONS_DEMONIC_CRAWLER",
    species_id = "MONS_DEMONIC_CRAWLER",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 100,
    -- demonic crawler offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 16,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 16,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 16,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 9,
    average_hp_10x = 585,
    ac = 10,
    ev = 6,
    spellbook_id = "MST_SCREAMER",
    leaves_corpse = true,
    shout_id = "S_SCREAM",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 13,
    -- For demonic crawler, energy costs combine with speed 13 to determine action
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
    shape_id = "MON_SHAPE_CENTIPEDE",
    tile = {
        id = "TILEP_MONS_DEMONIC_CRAWLER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_DEMONIC_CRAWLER",
}

register.definition(categories.MONSTERS, definition)

return definition
