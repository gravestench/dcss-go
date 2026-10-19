-- pharaoh ant (MONS_PHARAOH_ANT) is a DCSS monster profile with 10 hit dice
-- and speed 14.
-- Its first melee contact is AT_BITE for 43 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_PHARAOH_ANT",
    status = "defined",
    name = "pharaoh ant",
    glyph = 66,
    colour_id = "YELLOW",
    flags = {
        "M_NO_SKELETON",
        "M_WEB_IMMUNE",
    },
    xp_modifier = 10,
    genus_id = "MONS_PHARAOH_ANT",
    species_id = "MONS_PHARAOH_ANT",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 60,
    -- pharaoh ant offers AT_BITE as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_DRAIN",
            damage = 43,
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
    hd = 10,
    average_hp_10x = 360,
    ac = 4,
    ev = 8,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    shout_id = "S_MOAN",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 14,
    -- For pharaoh ant, energy costs combine with speed 14 to determine action
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
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_INSECT",
    tile = {
        id = "TILEP_MONS_PHARAOH_ANT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
