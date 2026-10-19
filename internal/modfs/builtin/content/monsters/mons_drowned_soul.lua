-- drowned soul (MONS_DROWNED_SOUL) is a DCSS monster profile with 13 hit dice
-- and speed 12.
-- Its first melee contact is AT_TOUCH for 0 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_DROWNED_SOUL",
    status = "defined",
    name = "drowned soul",
    glyph = 87,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_SEE_INVIS",
        "M_INSUBSTANTIAL",
        "M_SPEAKS",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 3,
        },
    },
    xp_modifier = 8,
    genus_id = "MONS_PHANTOM",
    species_id = "MONS_DROWNED_SOUL",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 60,
    -- drowned soul offers AT_TOUCH as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_TOUCH",
            flavour_id = "AF_DROWN",
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
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 13,
    average_hp_10x = 195,
    ev = 13,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 12,
    -- For drowned soul, energy costs combine with speed 12 to determine action
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
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_DROWNED_SOUL",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
