-- giant cockroach (MONS_GIANT_COCKROACH) is a DCSS monster profile with 1 hit
-- dice and speed 12.
-- Its first melee contact is AT_BITE for 2 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_GIANT_COCKROACH",
    status = "defined",
    name = "giant cockroach",
    glyph = 66,
    colour_id = "BROWN",
    flags = {
        "M_NO_SKELETON",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = -1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_GIANT_COCKROACH",
    species_id = "MONS_GIANT_COCKROACH",
    holiness = {
        "MH_NATURAL",
    },
    -- giant cockroach offers AT_BITE as its first contact; later slots are tried
    -- by the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 2,
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
    hd = 1,
    average_hp_10x = 50,
    ac = 3,
    ev = 10,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 12,
    -- For giant cockroach, energy costs combine with speed 12 to determine action
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
    size_id = "SIZE_LITTLE",
    shape_id = "MON_SHAPE_INSECT",
    tile = {
        id = "TILEP_MONS_GIANT_COCKROACH",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_GIANT_COCKROACH",
}

register.definition(categories.MONSTERS, definition)

return definition
