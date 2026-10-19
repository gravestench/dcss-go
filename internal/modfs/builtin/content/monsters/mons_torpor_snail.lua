-- torpor snail (MONS_TORPOR_SNAIL) is a DCSS monster profile with 10 hit dice
-- and speed 7.
-- Its first melee contact is AT_BITE for 25 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_TORPOR_SNAIL",
    status = "defined",
    name = "torpor snail",
    glyph = 119,
    colour_id = "GREEN",
    flags = {
        "M_NO_SKELETON",
        "M_WEB_IMMUNE",
    },
    xp_modifier = 20,
    genus_id = "MONS_ELEPHANT_SLUG",
    species_id = "MONS_TORPOR_SNAIL",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 80,
    -- torpor snail offers AT_BITE as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 25,
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
    average_hp_10x = 600,
    ac = 8,
    ev = 1,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 7,
    -- For torpor snail, energy costs combine with speed 7 to determine action
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
    shape_id = "MON_SHAPE_SNAIL",
    tile = {
        id = "TILEP_MONS_TORPOR_SNAIL",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_TORPOR_SNAIL",
}

register.definition(categories.MONSTERS, definition)

return definition
