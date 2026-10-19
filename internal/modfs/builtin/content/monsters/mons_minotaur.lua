-- minotaur (MONS_MINOTAUR) is a DCSS monster profile with 14 hit dice and
-- speed 10.
-- Its first melee contact is AT_HIT for 35 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_MINOTAUR",
    status = "defined",
    name = "minotaur",
    glyph = 72,
    colour_id = "LIGHTRED",
    flags = {
        "M_FIGHTER",
        "M_WARM_BLOOD",
        "M_SPEAKS",
    },
    xp_modifier = 10,
    genus_id = "MONS_MINOTAUR",
    species_id = "MONS_MINOTAUR",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 100,
    -- minotaur offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 35,
        },
        {
            type_id = "AT_GORE",
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
    hd = 14,
    average_hp_10x = 780,
    ac = 6,
    ev = 9,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_BELLOW",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For minotaur, energy costs combine with speed 10 to determine action
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
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_MINOTAUR",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_MINOTAUR",
}

register.definition(categories.MONSTERS, definition)

return definition
