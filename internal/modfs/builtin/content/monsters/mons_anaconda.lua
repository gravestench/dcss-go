-- anaconda (MONS_ANACONDA) is a DCSS monster profile with 11 hit dice and
-- speed 18.
-- Its first melee contact is AT_CONSTRICT for 6 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_ANACONDA",
    status = "defined",
    name = "anaconda",
    glyph = 83,
    colour_id = "LIGHTGREY",
    flags = {
        "M_COLD_BLOOD",
    },
    xp_modifier = 10,
    genus_id = "MONS_SNAKE",
    species_id = "MONS_ANACONDA",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- anaconda offers AT_CONSTRICT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_CONSTRICT",
            flavour_id = "AF_CRUSH",
            damage = 6,
        },
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 20,
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
    hd = 11,
    average_hp_10x = 605,
    ac = 4,
    ev = 16,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_HISS",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 18,
    -- For anaconda, energy costs combine with speed 18 to determine action
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
    shape_id = "MON_SHAPE_SNAKE",
    tile = {
        id = "TILEP_MONS_ANACONDA",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_ANACONDA",
}

register.definition(categories.MONSTERS, definition)

return definition
