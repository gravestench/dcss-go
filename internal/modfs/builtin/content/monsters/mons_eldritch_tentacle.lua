-- eldritch tentacle (MONS_ELDRITCH_TENTACLE) is a DCSS monster profile with
-- 16 hit dice and speed 12.
-- Its first melee contact is AT_TENTACLE_SLAP for 30 base damage; combat
-- policy applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_ELDRITCH_TENTACLE",
    status = "defined",
    name = "eldritch tentacle",
    glyph = 119,
    colour_id = "COLOUR_UNDEF",
    flags = {
        "M_NO_POLY_TO",
        "M_STATIONARY",
        "M_SEE_INVIS",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 3,
        },
        {
            id = "MR_RES_COLD",
            level = 3,
        },
        {
            id = "MR_RES_ELEC",
            level = 3,
        },
        {
            id = "MR_RES_ACID",
            level = 3,
        },
        {
            id = "MR_RES_STICKY_FLAME",
            level = 1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_ELDRITCH_TENTACLE",
    species_id = "MONS_ELDRITCH_TENTACLE",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 5000,
    -- eldritch tentacle offers AT_TENTACLE_SLAP as its first contact; later slots
    -- are tried by the shared melee flow.
    attacks = {
        {
            type_id = "AT_TENTACLE_SLAP",
            flavour_id = "AF_CHAOTIC",
            damage = 30,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_CHAOTIC",
            damage = 40,
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
    hd = 16,
    average_hp_10x = 1200,
    ac = 13,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 12,
    -- For eldritch tentacle, energy costs combine with speed 12 to determine
    -- action cadence, not an unconditional action each turn.
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
    shape_id = "MON_SHAPE_SNAKE",
    tile = {
        id = "TILEP_MONS_PROGRAM_BUG",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
