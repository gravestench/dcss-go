-- spatial maelstrom (MONS_SPATIAL_MAELSTROM) is a DCSS monster profile with
-- 10 hit dice and speed 16.
-- Its first melee contact is AT_HIT for 20 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_SPATIAL_MAELSTROM",
    status = "defined",
    name = "spatial maelstrom",
    glyph = 118,
    colour_id = "YELLOW",
    flags = {
        "M_BATTY",
        "M_INSUBSTANTIAL",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 2,
        },
        {
            id = "MR_RES_COLD",
            level = 2,
        },
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
    },
    xp_modifier = 5,
    genus_id = "MONS_SPATIAL_MAELSTROM",
    species_id = "MONS_SPATIAL_MAELSTROM",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 5000,
    -- spatial maelstrom offers AT_HIT as its first contact; later slots are tried
    -- by the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_DISTORT",
            damage = 20,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_DISTORT",
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
    hd = 10,
    average_hp_10x = 750,
    ev = 5,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    shout_id = "S_SILENT",
    intelligence_id = "I_BRAINLESS",
    habitat_id = "HT_LAND",
    speed = 16,
    -- For spatial maelstrom, energy costs combine with speed 16 to determine
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
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_SPATIAL_MAELSTROM",
        variation_id = "TVARY_CYCLE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
