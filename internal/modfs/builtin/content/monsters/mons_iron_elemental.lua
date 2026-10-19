-- iron elemental (MONS_IRON_ELEMENTAL) is a DCSS monster profile with 12 hit
-- dice and speed 6.
-- Its first melee contact is AT_HIT for 40 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_IRON_ELEMENTAL when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_IRON_ELEMENTAL",
    status = "defined",
    name = "iron elemental",
    glyph = 69,
    colour_id = "ETC_IRON",
    flags = {
        "M_UNBLINDABLE",
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
    },
    xp_modifier = 13,
    genus_id = "MONS_ELEMENTAL",
    species_id = "MONS_IRON_ELEMENTAL",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 5000,
    -- iron elemental offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
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
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 12,
    average_hp_10x = 1080,
    ac = 20,
    ev = 2,
    spellbook_id = "MST_IRON_ELEMENTAL",
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_LAND",
    speed = 6,
    -- For iron elemental, energy costs combine with speed 6 to determine action
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
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_IRON_ELEMENTAL",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
