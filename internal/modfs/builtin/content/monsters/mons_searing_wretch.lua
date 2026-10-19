-- searing wretch (MONS_SEARING_WRETCH) is a DCSS monster profile with 18 hit
-- dice and speed 10.
-- Its first melee contact is AT_CLAW for 40 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_SEARING_WRETCH",
    status = "defined",
    name = "searing wretch",
    glyph = 110,
    colour_id = "ETC_FIRE",
    flags = {
        "M_NO_ZOMBIE",
        "M_FAST_REGEN",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 3,
        },
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_GHOUL",
    species_id = "MONS_SEARING_WRETCH",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 80,
    -- searing wretch offers AT_CLAW as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_FIRE",
            damage = 40,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_SEAR",
            damage = 30,
        },
        {
            type_id = "AT_BITE",
            flavour_id = "AF_STICKY_FLAME",
            damage = 15,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 18,
    average_hp_10x = 1600,
    ac = 4,
    ev = 8,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For searing wretch, energy costs combine with speed 10 to determine action
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
        id = "TILEP_SEARING_WRETCH",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
