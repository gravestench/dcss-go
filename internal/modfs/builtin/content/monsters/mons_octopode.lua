-- octopode (MONS_OCTOPODE) is a DCSS monster profile with 8 hit dice and
-- speed 10.
-- Its first melee contact is AT_TENTACLE_SLAP for 24 base damage; combat
-- policy applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_OCTOPODE",
    status = "defined",
    name = "octopode",
    glyph = 120,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_NO_SKELETON",
        "M_SPEAKS",
        "M_NO_POLY_TO",
        "M_NO_GEN_DERIVED",
    },
    xp_modifier = 10,
    genus_id = "MONS_OCTOPODE",
    species_id = "MONS_OCTOPODE",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 10,
    -- octopode offers AT_TENTACLE_SLAP as its first contact; later slots are tried
    -- by the shared melee flow.
    attacks = {
        {
            type_id = "AT_TENTACLE_SLAP",
            flavour_id = "AF_PLAIN",
            damage = 24,
        },
        {
            type_id = "AT_CONSTRICT",
            flavour_id = "AF_CRUSH",
            damage = 5,
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
    average_hp_10x = 560,
    ac = 1,
    ev = 5,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 10,
    -- For octopode, energy costs combine with speed 10 to determine action
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
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_OCTOPODE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_OCTOPODE",
}

register.definition(categories.MONSTERS, definition)

return definition
