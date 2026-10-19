-- barachi (MONS_BARACHI) is a DCSS monster profile with 3 hit dice and speed
-- 8.
-- Its first melee contact is AT_HIT for 6 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_BARACHI",
    status = "defined",
    name = "barachi",
    glyph = 70,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_SPEAKS",
        "M_NO_POLY_TO",
        "M_NO_GEN_DERIVED",
    },
    xp_modifier = 10,
    genus_id = "MONS_FROG",
    species_id = "MONS_BARACHI",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 10,
    -- barachi offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 6,
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
    hd = 3,
    average_hp_10x = 180,
    ev = 10,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 8,
    -- For barachi, energy costs combine with speed 8 to determine action cadence,
    -- not an unconditional action each turn.
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
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_BULLFROG",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_BULLFROG",
}

register.definition(categories.MONSTERS, definition)

return definition
