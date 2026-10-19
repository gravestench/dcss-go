-- dire elephant (MONS_DIRE_ELEPHANT) is a DCSS monster profile with 15 hit
-- dice and speed 10.
-- Its first melee contact is AT_TRAMPLE for 40 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_DIRE_ELEPHANT",
    status = "defined",
    name = "dire elephant",
    glyph = 89,
    colour_id = "BLUE",
    flags = {
        "M_WARM_BLOOD",
    },
    xp_modifier = 8,
    genus_id = "MONS_ELEPHANT",
    species_id = "MONS_DIRE_ELEPHANT",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 100,
    -- dire elephant offers AT_TRAMPLE as its first contact; later slots are tried
    -- by the shared melee flow.
    attacks = {
        {
            type_id = "AT_TRAMPLE",
            flavour_id = "AF_TRAMPLE",
            damage = 40,
        },
        {
            type_id = "AT_TRUNK_SLAP",
            flavour_id = "AF_PLAIN",
            damage = 15,
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
    average_hp_10x = 1125,
    ac = 13,
    ev = 2,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_TRUMPET",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For dire elephant, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_DIRE_ELEPHANT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_DIRE_ELEPHANT",
}

register.definition(categories.MONSTERS, definition)

return definition
