-- animated armour (MONS_ANIMATED_ARMOUR) is a DCSS monster profile with 15
-- hit dice and speed 10.
-- Its first melee contact is AT_HIT for 1 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_ANIMATED_ARMOUR",
    status = "defined",
    name = "animated armour",
    glyph = 91,
    colour_id = "GREEN",
    flags = {
        "M_FLIES",
        "M_UNBLINDABLE",
    },
    xp_modifier = 10,
    genus_id = "MONS_ANIMATED_ARMOUR",
    species_id = "MONS_ANIMATED_ARMOUR",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 5000,
    -- animated armour offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 1,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 1,
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
    hd = 15,
    average_hp_10x = 400,
    ac = 8,
    ev = 5,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For animated armour, energy costs combine with speed 10 to determine action
    -- cadence, not an unconditional action each turn.
    energy = {
        move = 30,
        swim = 30,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_ANIMATED_ARMOUR",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
