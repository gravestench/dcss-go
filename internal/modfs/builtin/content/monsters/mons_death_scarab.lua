-- death scarab (MONS_DEATH_SCARAB) is a DCSS monster profile with 8 hit dice
-- and speed 30.
-- Its first melee contact is AT_BITE for 33 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_DEATH_SCARAB",
    status = "defined",
    name = "death scarab",
    glyph = 66,
    colour_id = "BLUE",
    flags = {
        "M_NO_SKELETON",
        "M_BATTY",
        "M_WEB_IMMUNE",
    },
    xp_modifier = 12,
    genus_id = "MONS_DEATH_SCARAB",
    species_id = "MONS_DEATH_SCARAB",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 60,
    -- death scarab offers AT_BITE as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_SCARAB",
            damage = 33,
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
    hd = 8,
    average_hp_10x = 320,
    ac = 7,
    ev = 14,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_FAINT_SKITTER",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 30,
    -- For death scarab, energy costs combine with speed 30 to determine action
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
        id = "TILEP_MONS_DEATH_SCARAB",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_DEATH_SCARAB",
}

register.definition(categories.MONSTERS, definition)

return definition
