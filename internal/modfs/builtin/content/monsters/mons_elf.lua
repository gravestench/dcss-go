-- elf (MONS_ELF) is a DCSS monster profile with 8 hit dice and speed 10.
-- Its first melee contact is AT_HIT for 10 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_ELF",
    status = "defined",
    name = "elf",
    glyph = 101,
    colour_id = "LIGHTRED",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_NO_POLY_TO",
    },
    xp_modifier = 10,
    genus_id = "MONS_ELF",
    species_id = "MONS_ELF",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- elf has AT_HIT in its first attack slot; current melee rules read that slot.
    attacks = {
        {
            type_id = "AT_HIT",
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
    hd = 8,
    average_hp_10x = 360,
    ac = 3,
    ev = 15,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For elf, energy costs combine with speed 10 to determine action cadence, not
    -- an unconditional action each turn.
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
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_ELF",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_ELF",
    -- Source: vaults/arrival/dreamdust_arrival_sigmund_warning.des
    vault_aliases = {
        "deep elf",
    },
}

register.definition(categories.MONSTERS, definition)

return definition
