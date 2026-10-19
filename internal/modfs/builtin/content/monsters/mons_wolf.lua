-- wolf (MONS_WOLF) is a DCSS monster profile with 4 hit dice and speed 17.
-- Its first melee contact is AT_BITE for 12 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_WOLF",
    status = "defined",
    name = "wolf",
    glyph = 104,
    colour_id = "LIGHTGREY",
    flags = {
        "M_SEE_INVIS",
        "M_UNBLINDABLE",
        "M_WARM_BLOOD",
    },
    xp_modifier = 12,
    genus_id = "MONS_HOUND",
    species_id = "MONS_WOLF",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    -- wolf offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 12,
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
    hd = 4,
    average_hp_10x = 220,
    ac = 4,
    ev = 15,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_HOWL",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 17,
    -- For wolf, energy costs combine with speed 17 to determine action cadence,
    -- not an unconditional action each turn.
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
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_WOLF",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_WOLF",
}

register.definition(categories.MONSTERS, definition)

return definition
