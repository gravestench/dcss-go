-- sun demon (MONS_SUN_DEMON) is a DCSS monster profile with 10 hit dice and
-- speed 12.
-- Its first melee contact is AT_HIT for 30 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_SUN_DEMON",
    status = "defined",
    name = "sun demon",
    glyph = 51,
    colour_id = "YELLOW",
    flags = {
        "M_FLIES",
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
            level = -1,
        },
        {
            id = "MR_RES_FIRE",
            level = 3,
        },
    },
    xp_modifier = 14,
    genus_id = "MONS_SUN_DEMON",
    species_id = "MONS_SUN_DEMON",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 80,
    -- sun demon offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_FIRE",
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
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 10,
    average_hp_10x = 550,
    ac = 10,
    ev = 12,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 12,
    -- For sun demon, energy costs combine with speed 12 to determine action
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
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_SUN_DEMON",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
