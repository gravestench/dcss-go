-- bullfrog (MONS_BULLFROG) is a DCSS monster profile with 4 hit dice and
-- speed 15.
-- Its first melee contact is AT_HIT for 9 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_BULLFROG",
    status = "defined",
    name = "bullfrog",
    glyph = 70,
    colour_id = "GREEN",
    flags = {
        "M_COLD_BLOOD",
    },
    xp_modifier = 10,
    genus_id = "MONS_FROG",
    species_id = "MONS_BULLFROG",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    -- bullfrog offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 9,
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
    ev = 12,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_CROAK",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 15,
    -- For bullfrog, energy costs combine with speed 15 to determine action
    -- cadence, not an unconditional action each turn.
    energy = {
        move = 10,
        swim = 6,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_QUADRUPED_TAILLESS",
    tile = {
        id = "TILEP_MONS_BULLFROG",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_BULLFROG",
}

register.definition(categories.MONSTERS, definition)

return definition
