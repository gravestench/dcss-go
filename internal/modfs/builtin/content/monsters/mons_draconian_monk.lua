-- draconian monk (MONS_DRACONIAN_MONK) is a DCSS monster profile with 16 hit
-- dice and speed 10.
-- Its first melee contact is AT_HIT for 35 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_DRACONIAN_MONK",
    status = "defined",
    name = "draconian monk",
    glyph = 113,
    colour_id = "LIGHTGREEN",
    flags = {
        "M_FIGHTER",
        "M_COLD_BLOOD",
        "M_SPEAKS",
    },
    xp_modifier = 10,
    genus_id = "MONS_DRACONIAN",
    species_id = "MONS_DRACONIAN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- draconian monk offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 35,
        },
        {
            type_id = "AT_KICK",
            flavour_id = "AF_PLAIN",
            damage = 20,
        },
        {
            type_id = "AT_TAIL_SLAP",
            flavour_id = "AF_PLAIN",
            damage = 15,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 16,
    average_hp_10x = 1200,
    ac = -3,
    ev = 10,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_ROAR",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For draconian monk, energy costs combine with speed 10 to determine action
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
    shape_id = "MON_SHAPE_HUMANOID_TAILED",
    tile = {
        id = "TILEP_DRACO_MONK",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
