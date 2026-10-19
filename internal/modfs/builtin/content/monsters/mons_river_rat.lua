-- river rat (MONS_RIVER_RAT) is a DCSS monster profile with 2 hit dice and
-- speed 10.
-- Its first melee contact is AT_BITE for 10 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_RIVER_RAT",
    status = "defined",
    name = "river rat",
    glyph = 114,
    colour_id = "LIGHTGREEN",
    flags = {
        "M_WARM_BLOOD",
    },
    xp_modifier = 13,
    genus_id = "MONS_RAT",
    species_id = "MONS_RIVER_RAT",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 10,
    -- river rat offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 10,
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
    hd = 2,
    average_hp_10x = 110,
    ac = 5,
    ev = 11,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 10,
    -- For river rat, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_TINY",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_RIVER_RAT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_GREEN_RAT",
}

register.definition(categories.MONSTERS, definition)

return definition
